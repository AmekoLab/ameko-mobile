import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/notification/domain/entities/notification_entity.dart';
import 'package:ameko_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:ameko_app/features/notification/presentation/bloc/notification_event.dart';
import 'package:ameko_app/features/notification/presentation/bloc/notification_state.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<NotificationBloc>().add(const FetchNotifications(isRefresh: true));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      context.read<NotificationBloc>().add(const FetchNotifications());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Thông báo'),
        actions: [
          TextButton(
            onPressed: () {
              context.read<NotificationBloc>().add(MarkAllNotificationsAsRead());
            },
            child: const Text('Đọc tất cả', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.status == NotificationStatus.loading && state.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == NotificationStatus.failure && state.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.errorMessage ?? 'Có lỗi xảy ra'),
                  ElevatedButton(
                    onPressed: () => context.read<NotificationBloc>().add(const FetchNotifications(isRefresh: true)),
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          if (state.notifications.isEmpty) {
            return const Center(child: Text('Bạn chưa có thông báo nào'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<NotificationBloc>().add(const FetchNotifications(isRefresh: true));
            },
            child: ListView.separated(
              controller: _scrollController,
              itemCount: state.notifications.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (context, index) {
                if (index >= state.notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                final notification = state.notifications[index];
                return _NotificationItem(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationEntity notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm, dd/MM/yyyy');

    return InkWell(
      onTap: () {
        if (!notification.isRead) {
          context.read<NotificationBloc>().add(MarkNotificationAsRead(notification.id));
        }
        _handleNavigation(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        color: notification.isRead ? Colors.transparent : AppColors.primary.withOpacity(0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getIconColor(notification.referenceType).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getIcon(notification.referenceType),
                color: _getIconColor(notification.referenceType),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.content,
                    style: AppTextStyles.bodySecondary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeFormat.format(notification.createdAt),
                    style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(NotificationReferenceType type) {
    switch (type) {
      case NotificationReferenceType.post:
        return Icons.article_outlined;
      case NotificationReferenceType.order:
        return Icons.shopping_bag_outlined;
      case NotificationReferenceType.chat:
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(NotificationReferenceType type) {
    switch (type) {
      case NotificationReferenceType.post:
        return Colors.blue;
      case NotificationReferenceType.order:
        return Colors.orange;
      case NotificationReferenceType.chat:
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  void _handleNavigation(BuildContext context) {
    final refId = notification.referenceId;
    if (refId == null || refId.isEmpty) return;

    switch (notification.referenceType) {
      case NotificationReferenceType.post:
        context.push('/post-detail/$refId');
        break;
      case NotificationReferenceType.order:
        context.push('/orders/$refId');
        break;
      case NotificationReferenceType.chat:
        context.push('/chat/$refId');
        break;
      default:
        break;
    }
  }
}
