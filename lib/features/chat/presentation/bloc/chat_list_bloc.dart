import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';
import 'package:ameko_app/features/chat/domain/repositories/chat_repository.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';
import 'package:ameko_app/core/services/chat_service.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ChatRepository repository;
  final ChatService _chatService;

  ChatListBloc({
    required this.repository,
    required ChatService chatService,
  })  : _chatService = chatService,
        super(const ChatListState()) {
    on<FetchConversations>(_onFetchConversations);
    on<LoadMoreConversations>(_onLoadMoreConversations);
    on<ListReceiveMessage>(_onListReceiveMessage);
    on<OptimisticMarkAsReadList>(_onOptimisticMarkAsReadList);

    // Real-time listener
    _chatService.onMessageReceived(_onSignalRMessage);
  }

  void _onSignalRMessage(Map<String, dynamic> data) {
    // Support both PascalCase (Backend) and camelCase (Standard)
    final convoId = (data['ConversationId'] ?? data['conversationId'])?.toString() ?? '';
    final content = (data['Content'] ?? data['content'])?.toString() ?? '';
    final senderId = (data['SenderId'] ?? data['senderId'])?.toString() ?? '';
    final createdAtStr = (data['CreatedAt'] ?? data['createdAt'])?.toString();

    final message = MessageEntity(
      id: (data['Id'] ?? data['id'])?.toString() ?? '',
      senderId: senderId,
      content: content,
      createdAt: createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now(),
    );
    
    add(ListReceiveMessage(
      conversationId: convoId,
      message: message,
      isActiveConversation: false,
    ));
  }

  @override
  Future<void> close() {
    _chatService.offMessageReceived(_onSignalRMessage);
    return super.close();
  }

  Future<void> _onFetchConversations(
    FetchConversations event,
    Emitter<ChatListState> emit,
  ) async {
    emit(state.copyWith(status: ChatListStatus.loading, cursor: null));
    try {
      final response = await repository.getConversations(
        cursor: null,
        pageSize: 20,
      );
      
      // Auto-join all conversation groups for real-time updates in the list
      for (final convo in response.items) {
        _chatService.joinConversation(convo.conversationId);
      }

      emit(state.copyWith(
        status: ChatListStatus.success,
        conversations: response.items,
        hasMore: response.hasMore,
        cursor: response.nextCursor,
        conversationsInitialized: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatListStatus.failure,
        error: e.toString(),
        conversationsInitialized: true,
      ));
    }
  }

  Future<void> _onLoadMoreConversations(
    LoadMoreConversations event,
    Emitter<ChatListState> emit,
  ) async {
    if (!state.hasMore || state.status == ChatListStatus.loadingMore) return;

    emit(state.copyWith(status: ChatListStatus.loadingMore));
    try {
      final response = await repository.getConversations(
        cursor: state.cursor,
        pageSize: 20,
      );
      emit(state.copyWith(
        status: ChatListStatus.success,
        conversations: [...state.conversations, ...response.items],
        hasMore: response.hasMore,
        cursor: response.nextCursor,
      ));
    } catch (e) {
      emit(state.copyWith(status: ChatListStatus.failure, error: e.toString()));
    }
  }

  void _onListReceiveMessage(
    ListReceiveMessage event,
    Emitter<ChatListState> emit,
  ) {
    final bucket = List<ConversationEntity>.from(state.conversations);
    final idx = bucket.indexWhere((c) => c.conversationId == event.conversationId);

    if (idx != -1) {
      final convo = bucket.removeAt(idx);
      final updatedConvo = convo.copyWith(
        lastMessage: event.message.content,
        lastMessageAt: event.message.createdAt,
        unreadCount: event.isActiveConversation ? convo.unreadCount : (convo.unreadCount + 1),
      );
      bucket.insert(0, updatedConvo);
      emit(state.copyWith(conversations: bucket));
    }
    // Note: If idx == -1 (conversation not found), we would ideally fetch the conversation
    // or rely on a generic reload. The FE Redux slice also doesn't fetch missing ones easily
    // without `bubbleToTop` failing silently if not found or relying on signalR `startConversation`.
  }

  void _onOptimisticMarkAsReadList(
    OptimisticMarkAsReadList event,
    Emitter<ChatListState> emit,
  ) {
    final bucket = List<ConversationEntity>.from(state.conversations);
    final idx = bucket.indexWhere((c) => c.conversationId == event.conversationId);
    if (idx != -1) {
      bucket[idx] = bucket[idx].copyWith(unreadCount: 0);
      emit(state.copyWith(conversations: bucket));
    }
  }
}
