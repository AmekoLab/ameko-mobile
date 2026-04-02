import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';
import 'package:ameko_app/features/chat/domain/repositories/chat_repository.dart';
import 'chat_list_event.dart';
import 'chat_list_state.dart';

class ChatListBloc extends Bloc<ChatListEvent, ChatListState> {
  final ChatRepository repository;

  ChatListBloc({required this.repository}) : super(const ChatListState()) {
    on<FetchConversations>(_onFetchConversations);
    on<LoadMoreConversations>(_onLoadMoreConversations);
    on<ListReceiveMessage>(_onListReceiveMessage);
    on<OptimisticMarkAsReadList>(_onOptimisticMarkAsReadList);
  }

  Future<void> _onFetchConversations(
    FetchConversations event,
    Emitter<ChatListState> emit,
  ) async {
    emit(state.copyWith(status: ChatListStatus.loading, cursor: 1));
    try {
      final response = await repository.getConversations(
        cursor: 1,
        pageSize: 20,
      );
      emit(state.copyWith(
        status: ChatListStatus.success,
        conversations: response.items,
        hasMore: response.hasMore,
        cursor: response.nextCursor ?? (state.cursor + 1),
        conversationsInitialized: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: ChatListStatus.failure,
        error: e.toString(),
        conversationsInitialized: true, // mark done even on error to avoid loop
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
        cursor: response.nextCursor ?? (state.cursor + 1),
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
