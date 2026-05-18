import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';

class ConversationModel {
  final String conversationId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  ConversationModel({
    required this.conversationId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      conversationId: json['conversationId']?.toString() ?? '',
      otherUserName: json['otherUserName'] ?? '',
      otherUserAvatarUrl: json['otherUserAvatarUrl'],
      lastMessage: json['lastMessage'] ?? '',
      lastMessageAt: DateTime.parse(json['lastMessageAt'] ?? DateTime.now().toIso8601String()),
      unreadCount: json['unreadCount'] != null ? int.tryParse(json['unreadCount'].toString()) ?? 0 : 0,
    );
  }

  ConversationEntity toEntity() {
    return ConversationEntity(
      conversationId: conversationId,
      otherUserName: otherUserName,
      otherUserAvatarUrl: otherUserAvatarUrl,
      lastMessage: lastMessage,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
    );
  }
}

class ConversationResponse {
  final List<ConversationModel> items;
  final String? nextCursor;
  final bool hasMore;

  ConversationResponse({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  factory ConversationResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return ConversationResponse(
      items: (data['items'] as List?)
              ?.map((e) => ConversationModel.fromJson(e))
              .toList() ??
          [],
      nextCursor: data['nextCursor']?.toString(),
      hasMore: data['hasMore'] ?? false,
    );
  }
}
