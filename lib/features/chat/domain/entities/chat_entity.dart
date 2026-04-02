import 'package:equatable/equatable.dart';

/// Status of a locally-created (optimistic) message.
enum MessageStatus { sending, sent, error }

class MessageEntity extends Equatable {
  final String id;
  final String? tempId; // local optimistic id, null for server messages
  final String senderId;
  final String content;
  final int messageType; // 0 = text
  final String? parentMessageId;
  final int? reaction;
  final DateTime createdAt;
  final MessageStatus status;

  const MessageEntity({
    required this.id,
    this.tempId,
    required this.senderId,
    required this.content,
    this.messageType = 0,
    this.parentMessageId,
    this.reaction,
    required this.createdAt,
    this.status = MessageStatus.sent,
  });

  MessageEntity copyWith({
    String? id,
    String? tempId,
    String? senderId,
    String? content,
    int? messageType,
    String? parentMessageId,
    int? reaction,
    DateTime? createdAt,
    MessageStatus? status,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      tempId: tempId ?? this.tempId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      reaction: reaction ?? this.reaction,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, tempId, senderId, content, createdAt, status, reaction];
}

class ConversationEntity extends Equatable {
  final String conversationId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ConversationEntity({
    required this.conversationId,
    required this.otherUserName,
    this.otherUserAvatarUrl,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
  });

  ConversationEntity copyWith({
    String? conversationId,
    String? otherUserName,
    String? otherUserAvatarUrl,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ConversationEntity(
      conversationId: conversationId ?? this.conversationId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatarUrl: otherUserAvatarUrl ?? this.otherUserAvatarUrl,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [conversationId, otherUserName, lastMessage, unreadCount];
}

