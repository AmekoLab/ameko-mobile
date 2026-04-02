import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';
import 'package:ameko_app/features/chat/domain/repositories/chat_repository.dart';
import 'chat_detail_event.dart';
import 'chat_detail_state.dart';

class ChatDetailBloc extends Bloc<ChatDetailEvent, ChatDetailState> {
  final ChatRepository repository;
  static const _uuid = Uuid();

  ChatDetailBloc({required this.repository}) : super(const ChatDetailState()) {
    on<FetchMessages>(_onFetchMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<ReceiveMessage>(_onReceiveMessage);
    on<MarkMessagesRead>(_onMarkMessagesRead);
    on<ReactToMessage>(_onReactToMessage);
  }

  Future<void> _onFetchMessages(
    FetchMessages event,
    Emitter<ChatDetailState> emit,
  ) async {
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
        messages: response.items,
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
        messages: [...state.messages, ...response.items],
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
}
