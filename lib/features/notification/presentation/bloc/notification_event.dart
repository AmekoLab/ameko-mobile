import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/notification/domain/entities/notification_entity.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object?> get props => [];
}

class FetchNotifications extends NotificationEvent {
  final bool isRefresh;
  const FetchNotifications({this.isRefresh = false});
  @override
  List<Object?> get props => [isRefresh];
}

class FetchUnreadCount extends NotificationEvent {}

class MarkNotificationAsRead extends NotificationEvent {
  final String id;
  const MarkNotificationAsRead(this.id);
  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsAsRead extends NotificationEvent {}

class NewNotificationReceived extends NotificationEvent {
  final NotificationEntity notification;
  const NewNotificationReceived(this.notification);
  @override
  List<Object?> get props => [notification];
}

class InitializeSignalR extends NotificationEvent {}
