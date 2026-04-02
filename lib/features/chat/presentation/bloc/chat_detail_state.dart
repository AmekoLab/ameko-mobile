import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';

enum ChatDetailStatus { initial, loading, success, failure, loadingMore }

class ChatDetailState extends Equatable {
  final List<MessageEntity> messages;
  final ChatDetailStatus status;
  final bool hasMore;
  final int cursor;
  final String? conversationId;
  final String? error;

  const ChatDetailState({
    this.messages = const [],
    this.status = ChatDetailStatus.initial,
    this.hasMore = true,
    this.cursor = 1,
    this.conversationId,
    this.error,
  });

  ChatDetailState copyWith({
    List<MessageEntity>? messages,
    ChatDetailStatus? status,
    bool? hasMore,
    int? cursor,
    String? conversationId,
    String? error,
  }) {
    return ChatDetailState(
      messages: messages ?? this.messages,
      status: status ?? this.status,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      conversationId: conversationId ?? this.conversationId,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [messages, status, hasMore, cursor, conversationId, error];
}
