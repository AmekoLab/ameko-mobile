import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';
import 'package:ameko_app/features/chat/domain/repositories/chat_repository.dart';
import 'chat_detail_event.dart';
import 'chat_detail_state.dart';
import 'package:ameko_app/core/services/chat_service.dart';

class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  final ChatRepository repository;
  final ChatService _chatService;
  static const _uuid = Uuid();

  ChatDetailBloc({
    required this.repository,
    required ChatService chatService,
  })  : _chatService = chatService,
        super(const ChatDetailState()) {
    on<FetchMessages>(_onFetchMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<ReceiveMessage>(_onReceiveMessage);
    on<MarkMessagesRead>(_onMarkMessagesRead);
    on<ReactToMessage>(_onReactToMessage);
    on<MessageReactionReceived>(_onMessageReactionReceived);
    on<ReadReceiptReceived>(_onReadReceiptReceived);

    // Real-time listeners
    _chatService.onMessageReceived(_onSignalRMessage);
    _chatService.onReactionChanged(_onSignalRReaction);
    _chatService.onReadReceipt(_onSignalRReadReceipt);
  }

  void _onSignalRMessage(Map<String, dynamic> data) {
    // Support both PascalCase (Backend) and camelCase (Standard)
    final backendConvoId = (data['ConversationId'] ?? data['conversationId'])?.toString();
    if (backendConvoId != state.conversationId) return;

    final message = MessageEntity(
      id: (data['Id'] ?? data['id'])?.toString() ?? 'sr-${DateTime.now().millisecondsSinceEpoch}',
      senderId: (data['SenderId'] ?? data['senderId'])?.toString() ?? '',
      content: (data['Content'] ?? data['content'])?.toString() ?? '',
      createdAt: (data['CreatedAt'] ?? data['createdAt']) != null 
          ? DateTime.parse((data['CreatedAt'] ?? data['createdAt']).toString()) 
          : DateTime.now(),
      status: MessageStatus.sent,
      messageType: (data['MessageType'] ?? data['messageType']) as int? ?? 0,
      reaction: (data['Reaction'] ?? data['reaction']) as int?,
      tempId: (data['TempId'] ?? data['tempId'])?.toString(),
    );
    
    add(ReceiveMessage(message));
  }

  void _onSignalRReaction(Map<String, dynamic> data) {
    final backendConvoId = (data['ConversationId'] ?? data['conversationId'])?.toString();
    if (backendConvoId != state.conversationId) return;

    add(MessageReactionReceived(
      messageId: (data['MessageId'] ?? data['messageId']).toString(),
      reaction: (data['Reaction'] ?? data['reaction']) as int?,
    ));
  }

  void _onSignalRReadReceipt(Map<String, dynamic> data) {
    final backendConvoId = (data['ConversationId'] ?? data['conversationId'])?.toString();
    if (backendConvoId != state.conversationId) return;

    add(ReadReceiptReceived(
      userId: (data['UserId'] ?? data['userId']).toString(),
      upToMessageId: (data['UpToMessageId'] ?? data['upToMessageId']) as int,
    ));
  }

  @override
  Future<void> close() {
    if (state.conversationId != null) {
      _chatService.leaveConversation(state.conversationId!);
    }
    _chatService.offMessageReceived(_onSignalRMessage);
    _chatService.offReactionChanged(_onSignalRReaction);
    _chatService.offReadReceipt(_onSignalRReadReceipt);
    return super.close();
  }

  Future<void> _onFetchMessages(
    FetchMessages event,
    Emitter<ChatDetailState> emit,
  ) async {
    // Join SignalR group for this conversation
    _chatService.joinConversation(event.conversationId);

    emit(state.copyWith(
      status: ChatDetailStatus.loading,
      cursor: 1,
      conversationId: event.conversationId,
    ));
    try {
      final response = await repository.getMessages(
        conversationId: event.conversationId,
        cursor: 1,
        pageSize: 10,
      );
      emit(state.copyWith(
        status: ChatDetailStatus.success,
        messages: response.items.reversed.toList(),
        hasMore: response.hasMore,
        cursor: response.nextCursor ?? (state.cursor + 1),
      ));
    } catch (e) {
      emit(state.copyWith(status: ChatDetailStatus.failure, error: e.toString()));
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatDetailState> emit,
  ) async {
    if (!state.hasMore ||
        state.status == ChatDetailStatus.loadingMore ||
        state.conversationId == null) return;

    emit(state.copyWith(status: ChatDetailStatus.loadingMore));
    try {
      final response = await repository.getMessages(
        conversationId: state.conversationId!,
        cursor: state.cursor,
        pageSize: 10,
      );
      emit(state.copyWith(
        status: ChatDetailStatus.success,
        messages: [...state.messages, ...response.items.reversed.toList()],
        hasMore: response.hasMore,
        cursor: response.nextCursor ?? (state.cursor + 1),
      ));
    } catch (e) {
      emit(state.copyWith(status: ChatDetailStatus.failure, error: e.toString()));
    }
  }

  /// Mirrors FE sendMessageThunk:
  /// 1. Optimistically insert a "sending" message with tempId.
  /// 2. Call API → on success, replace temp with real message.
  /// 3. On error, mark temp message as "error".
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatDetailState> emit,
  ) async {
    final tempId = event.tempId.isNotEmpty ? event.tempId : _uuid.v4();

    // 1. Optimistic insert (status = sending)
    final optimistic = MessageEntity(
      id: '-${DateTime.now().millisecondsSinceEpoch}', // negative = temp
      tempId: tempId,
      senderId: event.senderId,
      content: event.content,
      messageType: event.messageType,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    emit(state.copyWith(messages: [optimistic, ...state.messages]));

    try {
      final sent = await repository.sendMessage(
        conversationId: event.conversationId,
        content: event.content,
        messageType: event.messageType,
      );

      final bucket = List<MessageEntity>.from(state.messages);
      final tempIdx = bucket.indexWhere((m) => m.tempId == tempId);
      final alreadyExists = bucket.any((m) => m.id == sent.id);

      if (tempIdx != -1) {
        if (alreadyExists) {
          bucket.removeAt(tempIdx);
        } else {
          bucket[tempIdx] = sent.copyWith(status: MessageStatus.sent, tempId: tempId);
        }
      } else if (!alreadyExists) {
        bucket.insert(0, sent.copyWith(status: MessageStatus.sent));
      }

      emit(state.copyWith(status: ChatDetailStatus.success, messages: bucket));
    } catch (_) {
      // Mark the optimistic message as error
      final bucket = state.messages.map((m) {
        if (m.tempId == tempId) return m.copyWith(status: MessageStatus.error);
        return m;
      }).toList();
      emit(state.copyWith(messages: bucket));
    }
  }

  /// Mirrors FE receiveMessage reducer — deduplicates by id and tempId.
  void _onReceiveMessage(
    ReceiveMessage event,
    Emitter<ChatDetailState> emit,
  ) {
    final message = event.message;
    final bucket = List<MessageEntity>.from(state.messages);

    final alreadyExists = bucket.any(
      (m) => m.id == message.id || (message.tempId != null && m.tempId == message.tempId),
    );

    if (!alreadyExists) {
      final tempIdx = message.tempId != null
          ? bucket.indexWhere((m) => m.tempId == message.tempId)
          : -1;

      if (tempIdx != -1) {
        bucket[tempIdx] = message.copyWith(status: MessageStatus.sent);
      } else {
        bucket.insert(0, message.copyWith(status: MessageStatus.sent));
      }

      emit(state.copyWith(messages: bucket));
    }
  }

  /// Mirrors FE markMessagesReadThunk — calls API optimistically.
  Future<void> _onMarkMessagesRead(
    MarkMessagesRead event,
    Emitter<ChatDetailState> emit,
  ) async {
    try {
      await repository.markAsRead(
        conversationId: event.conversationId,
        upToMessageId: event.upToMessageId,
      );
    } catch (_) {
      // silently ignore — same as FE behavior
    }
  }

  /// Mirrors FE reactToMessageThunk.
  Future<void> _onReactToMessage(
    ReactToMessage event,
    Emitter<ChatDetailState> emit,
  ) async {
    try {
      await repository.reactToMessage(
        conversationId: event.conversationId,
        messageId: event.messageId,
        reaction: event.reaction,
      );
      // Update reaction locally
      final bucket = state.messages.map((m) {
        if (m.id == event.messageId) return m.copyWith(reaction: event.reaction);
        return m;
      }).toList();
      emit(state.copyWith(messages: bucket));
    } catch (_) {
      // silently ignore for now
    }
  }

  void _onMessageReactionReceived(
    MessageReactionReceived event,
    Emitter<ChatDetailState> emit,
  ) {
    final bucket = state.messages.map((m) {
      if (m.id == event.messageId) return m.copyWith(reaction: event.reaction);
      return m;
    }).toList();
    emit(state.copyWith(messages: bucket));
  }

  void _onReadReceiptReceived(
    ReadReceiptReceived event,
    Emitter<ChatDetailState> emit,
  ) {
    // In many apps, read receipts update the status of messages sent by CURRENT user.
    // For now we just emit success to trigger any potential UI updates if needed,
    // though the actual "read" state is often calculated vs user session.
    // In our entity, we don't have a specific 'isReadByOther' field yet, 
    // but we can update any messages up to upToMessageId if we had it.
  }
}
