import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';

enum ChatListStatus { initial, loading, success, failure, loadingMore }

class ChatListState extends Equatable {
  final List<ConversationEntity> conversations;
  final ChatListStatus status;
  final bool hasMore;
  final int cursor;
  final String? error;
  final bool conversationsInitialized;

  const ChatListState({
    this.conversations = const [],
    this.status = ChatListStatus.initial,
    this.hasMore = true,
    this.cursor = 1,
    this.error,
    this.conversationsInitialized = false,
  });

  ChatListState copyWith({
    List<ConversationEntity>? conversations,
    ChatListStatus? status,
    bool? hasMore,
    int? cursor,
    String? error,
    bool? conversationsInitialized,
  }) {
    return ChatListState(
      conversations: conversations ?? this.conversations,
      status: status ?? this.status,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      error: error ?? this.error,
      conversationsInitialized: conversationsInitialized ?? this.conversationsInitialized,
    );
  }

  @override
  List<Object?> get props => [
        conversations,
        status,
        hasMore,
        cursor,
        error,
        conversationsInitialized,
      ];
}
