import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/core/services/storage_service.dart';
import 'package:ameko_app/features/notification/domain/repositories/notification_repository.dart';
import 'package:ameko_app/features/notification/data/services/notification_signalr_service.dart';
import 'notification_event.dart';
import 'notification_state.dart';
import 'package:ameko_app/features/notification/domain/entities/notification_entity.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository repository;
  final NotificationSignalRService signalRService;
  final StorageService storageService;

  NotificationBloc({
    required this.repository,
    required this.signalRService,
    required this.storageService,
  }) : super(const NotificationState()) {
    on<FetchNotifications>(_onFetchNotifications);
    on<FetchUnreadCount>(_onFetchUnreadCount);
    on<MarkNotificationAsRead>(_onMarkAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllAsRead);
    on<NewNotificationReceived>(_onNewNotificationReceived);
    on<InitializeSignalR>(_onInitializeSignalR);

    // Set up real-time listener
    signalRService.onNotificationReceived((notification) {
      add(NewNotificationReceived(notification));
    });
  }

  Future<void> _onInitializeSignalR(
    InitializeSignalR event,
    Emitter<NotificationState> emit,
  ) async {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'https://api.amekolab.online';
    final hubUrl = '$baseUrl/realtimeHub';
    
    await signalRService.connect(
      hubUrl,
      accessTokenFactory: () async => await storageService.getToken(),
    );
  }

  Future<void> _onFetchNotifications(
    FetchNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    if (event.isRefresh) {
      emit(state.copyWith(status: NotificationStatus.loading, nextCursor: null, hasMore: false));
    } else if (state.status == NotificationStatus.success && !state.hasMore) {
      return;
    }

    final result = await repository.getNotifications(
      cursor: event.isRefresh ? null : state.nextCursor,
    );

    result.fold(
      (failure) => emit(state.copyWith(status: NotificationStatus.failure, errorMessage: failure.message)),
      (data) {
        final notifications = (data['items'] as List).cast<NotificationEntity>();
        emit(state.copyWith(
          status: NotificationStatus.success,
          notifications: event.isRefresh ? notifications : [...state.notifications, ...notifications],
          nextCursor: data['nextCursor'],
          hasMore: data['hasMore'],
        ));
      },
    );
  }

  Future<void> _onFetchUnreadCount(
    FetchUnreadCount event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await repository.getUnreadCount();
    result.fold(
      (failure) => null, // Ignore for now
      (count) => emit(state.copyWith(unreadCount: count)),
    );
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await repository.markAsRead(event.id);
    result.fold(
      (failure) => null,
      (_) {
        final updatedNotifications = state.notifications.map((n) {
          if (n.id == event.id) {
            return n.copyWith(isRead: true); // I need to add copyWith to Entity
          }
          return n;
        }).toList();
        
        final newCount = state.unreadCount > 0 ? state.unreadCount - 1 : 0;
        emit(state.copyWith(notifications: updatedNotifications.cast<NotificationEntity>(), unreadCount: newCount));
      },
    );
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await repository.markAllAsRead();
    result.fold(
      (failure) => null,
      (_) {
        final updatedNotifications = state.notifications.map((n) => n.copyWith(isRead: true)).toList();
        emit(state.copyWith(notifications: updatedNotifications.cast<NotificationEntity>(), unreadCount: 0));
      },
    );
  }

  void _onNewNotificationReceived(
    NewNotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    emit(state.copyWith(
      notifications: [event.notification, ...state.notifications],
      unreadCount: state.unreadCount + 1,
    ));
  }
}

// Helper extension to make updating entities easier in Bloc
extension NotificationEntityX on NotificationEntity {
  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      title: title,
      content: content,
      referenceType: referenceType,
      referenceId: referenceId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
