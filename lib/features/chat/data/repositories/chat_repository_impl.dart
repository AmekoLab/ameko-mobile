import 'package:dio/dio.dart';
import 'package:ameko_app/features/chat/data/models/conversation_model.dart';
import 'package:ameko_app/features/chat/data/models/message_model.dart';
import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';
import 'package:ameko_app/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Dio _dio;

  ChatRepositoryImpl(this._dio);

  @override
  Future<({List<ConversationEntity> items, int? nextCursor, bool hasMore})>
      getConversations({int cursor = 1, int pageSize = 20}) async {
    final response = await _dio.get(
      '/api/v1/chat/conversations',
      queryParameters: {'cursor': cursor, 'pageSize': pageSize},
    );
    final convoResponse = ConversationResponse.fromJson(response.data);
    return (
      items: convoResponse.items.map((i) => i.toEntity()).toList(),
      nextCursor: convoResponse.nextCursor,
      hasMore: convoResponse.hasMore,
    );
  }

  @override
  Future<({List<MessageEntity> items, int? nextCursor, bool hasMore})>
      getMessages({
    required String conversationId,
    int cursor = 1,
    int pageSize = 10,
  }) async {
    final response = await _dio.get(
      '/api/v1/chat/conversations/$conversationId/messages',
      queryParameters: {'cursor': cursor, 'pageSize': pageSize},
    );
    final msgResponse = MessageResponse.fromJson(response.data);
    return (
      items: msgResponse.items.map((i) => i.toEntity()).toList(),
      nextCursor: msgResponse.nextCursor,
      hasMore: msgResponse.hasMore,
    );
  }

  @override
  Future<MessageEntity> sendMessage({
    required String conversationId,
    required String content,
    int messageType = 0,
  }) async {
    final response = await _dio.post('/api/v1/chat/messages', data: {
      'conversationId': int.tryParse(conversationId) ?? conversationId,
      'content': content,
      'messageType': messageType,
    });
    final data = response.data['data'] ?? response.data;
    return MessageModel.fromJson(data).toEntity();
  }

  @override
  Future<void> markAsRead({
    required String conversationId,
    required int upToMessageId,
  }) async {
    await _dio.post(
      '/api/v1/chat/conversations/$conversationId/read',
      data: {'upToMessageId': upToMessageId},
    );
  }

  @override
  Future<MessageEntity> reactToMessage({
    required String conversationId,
    required String messageId,
    required int? reaction,
  }) async {
    final response = await _dio.put(
      '/api/v1/chat/conversations/$conversationId/messages/$messageId/reaction',
      data: {'reaction': reaction},
    );
    final data = response.data['data'] ?? response.data;
    return MessageModel.fromJson(data).toEntity();
  }

  @override
  Future<ConversationEntity> getOrCreateDirectRoom(String targetUserId) async {
    final response = await _dio.post(
      '/api/v1/chat/conversations/direct/$targetUserId',
    );
    final data = response.data['data'] ?? response.data;
    return ConversationModel.fromJson(data).toEntity();
  }
}
