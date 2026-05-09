import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/core/widgets/app_avatar_circle.dart';
import 'package:ameko_app/features/chat/domain/entities/chat_entity.dart';
import 'package:ameko_app/features/chat/presentation/bloc/chat_list_bloc.dart';
import 'package:ameko_app/features/chat/presentation/bloc/chat_list_event.dart';
import 'package:ameko_app/features/chat/presentation/bloc/chat_list_state.dart';
import 'package:ameko_app/injection_container.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _scrollController = ScrollController();
  late ChatListBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<ChatListBloc>();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) _bloc.add(LoadMoreConversations());
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: GestureDetector(
          onTap: () => _bloc.add(FetchConversations()),
          child: Text('Tin nhắn', style: AppTextStyles.subheading.copyWith(fontWeight: FontWeight.bold)),
        ),
        centerTitle: false,
        toolbarHeight: 60,
      ),
      body: SafeArea(
        child: BlocBuilder<ChatListBloc, ChatListState>(
          builder: (context, state) {
            if (state.status == ChatListStatus.loading && state.conversations.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.status == ChatListStatus.failure && state.conversations.isEmpty) {
              return Center(child: Text(state.error ?? 'Lỗi khi tải tin nhắn'));
            }
            if (state.conversations.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Chưa có tin nhắn nào', style: AppTextStyles.bodySecondary),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _bloc.add(FetchConversations()),
                      child: const Text('Tải lại'),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _bloc.add(FetchConversations());
              },
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.hasMore ? state.conversations.length + 1 : state.conversations.length,
                separatorBuilder: (_, __) => const SizedBox(height: 0),
                itemBuilder: (context, i) {
                  if (i >= state.conversations.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  final convo = state.conversations[i];
                  return _ChatTile(
                    conversation: convo,
                    onTap: () => context.push('/chat/${convo.conversationId}'),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.conversation, required this.onTap});
  final ConversationEntity conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: AppColors.surface,
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        conversation.otherUserName,
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatTime(conversation.lastMessageAt),
                        style: AppTextStyles.caption.copyWith(
                          color: conversation.unreadCount > 0 ? AppColors.primary : AppColors.textHint,
                          fontWeight: conversation.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.lastMessage,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: conversation.unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: conversation.unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (conversation.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (conversation.otherUserAvatarUrl != null) {
      return CachedNetworkImage(
        imageUrl: conversation.otherUserAvatarUrl!,
        imageBuilder: (context, imageProvider) => Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        ),
        placeholder: (context, url) => Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => AppAvatarCircle(name: conversation.otherUserName, radius: 26),
      );
    }
    return AppAvatarCircle(name: conversation.otherUserName, radius: 26);
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) {
      return DateFormat('HH:mm').format(time);
    }
    final diff = now.difference(time);
    if (diff.inDays < 7) {
      return DateFormat('EEE').format(time);
    }
    return DateFormat('MMM d').format(time);
  }
}
