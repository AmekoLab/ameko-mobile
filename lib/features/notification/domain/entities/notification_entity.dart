import 'package:equatable/equatable.dart';

enum NotificationReferenceType {
  post,
  order,
  chat,
  unknown;

  static NotificationReferenceType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'post':
        return NotificationReferenceType.post;
      case 'order':
        return NotificationReferenceType.order;
      case 'chat':
        return NotificationReferenceType.chat;
      default:
        return NotificationReferenceType.unknown;
    }
  }
}

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String content;
  final NotificationReferenceType referenceType;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.content,
    required this.referenceType,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, title, content, referenceType, referenceId, isRead, createdAt];
}
