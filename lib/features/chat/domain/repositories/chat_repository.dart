import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';

abstract class ChatRepository {
  Future<({List<ConversationEntity> items, int? nextCursor, bool hasMore})>
      getConversations({int cursor = 1, int pageSize = 20});

  Future<({List<MessageEntity> items, int? nextCursor, bool hasMore})>
      getMessages({
    required String conversationId,
    int cursor = 1,
    int pageSize = 10,
  });

  /// POST /chat/messages — mirrors FE sendMessage
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String content,
    int messageType = 0,
  });

  /// POST /chat/conversations/{id}/read — mirrors FE markAsRead
  Future<void> markAsRead({
    required String conversationId,
    required int upToMessageId,
  });

  /// PUT /chat/conversations/{cId}/messages/{mId}/reaction
  Future<MessageEntity> reactToMessage({
    required String conversationId,
    required String messageId,
    required int? reaction,
  });

  /// POST /chat/conversations/direct/{targetUserId}
  Future<ConversationEntity> getOrCreateDirectRoom(String targetUserId);
}
