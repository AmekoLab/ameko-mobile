import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final int messageType;
  final String? parentMessageId;
  final int? reaction;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    required this.messageType,
    this.parentMessageId,
    this.reaction,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      content: json['content'] ?? '',
      messageType: json['messageType'] != null
          ? int.tryParse(json['messageType'].toString()) ?? 0
          : 0,
      parentMessageId: json['parentMessageId']?.toString(),
      reaction: json['reaction'] != null
          ? int.tryParse(json['reaction'].toString())
          : null,
      createdAt: DateTime.parse(
          json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  MessageEntity toEntity() {
    return MessageEntity(
      id: id,
      senderId: senderId,
      content: content,
      messageType: messageType,
      parentMessageId: parentMessageId,
      reaction: reaction,
      createdAt: createdAt,
      status: MessageStatus.sent,
    );
  }
}

class MessageResponse {
  final List<MessageModel> items;
  final int? nextCursor;
  final bool hasMore;

  MessageResponse({
    required this.items,
    this.nextCursor,
    required this.hasMore,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return MessageResponse(
      items: (data['items'] as List?)
              ?.map((e) => MessageModel.fromJson(e))
              .toList() ??
          [],
      nextCursor: data['nextCursor'] != null
          ? int.tryParse(data['nextCursor'].toString())
          : null,
      hasMore: data['hasMore'] ?? false,
    );
  }
}
