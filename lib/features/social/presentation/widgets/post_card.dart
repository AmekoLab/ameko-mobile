import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/social/data/models/post_model.dart';
import 'package:ameko_app/features/social/presentation/bloc/social_feed_bloc.dart';
import 'package:ameko_app/features/social/presentation/bloc/social_feed_event.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:ameko_app/features/auth/presentation/bloc/auth_state.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Vừa xong';
        }
        return '${difference.inMinutes} phút trước';
      }
      return '${difference.inHours} giờ trước';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthSuccess ? authState.user.id : '';

    return Container(
      color: AppColors.background,
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User Info
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primarySurface,
              backgroundImage: post.avatarUrl != null ? CachedNetworkImageProvider(post.avatarUrl!) : null,
              child: post.avatarUrl == null
                  ? Text(post.username.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary))
                  : null,
            ),
            title: Text(post.fullName, style: AppTextStyles.titleSmall),
            subtitle: Text('@${post.username} • ${_formatDate(post.createdAt)}', style: AppTextStyles.caption),
            trailing: IconButton(
              icon: const Icon(Icons.more_horiz),
              onPressed: () => _showPostOptions(context, currentUserId),
            ),
          ),

          // Post Title/Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(post.title, style: AppTextStyles.body),
          ),

          // Attachments (Images)
          if (post.attachmentUrls.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                height: 300,
                child: PageView.builder(
                  itemCount: post.attachmentUrls.length,
                  itemBuilder: (context, index) {
                    return CachedNetworkImage(
                      imageUrl: post.attachmentUrls[index],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: AppColors.surfaceVariant),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    );
                  },
                ),
              ),
            ),

          // Product Tag
          if (post.product != null)
            GestureDetector(
              onTap: () => context.push('/assembled-products/${post.product!.id}'),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: post.product!.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: post.product!.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                          : Container(width: 50, height: 50, color: AppColors.border),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(post.product!.name,
                              style: AppTextStyles.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('${NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(post.product!.price)}',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.amazonPrice)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

          // Actions: Reactions & Comments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildActionButton(
                  context: context,
                  icon: _getReactionIcon(post.currentUserReaction),
                  label: '${post.reactionCount}',
                  color: post.currentUserReaction != null ? AppColors.amazonBtnSecondary : AppColors.textSecondary,
                  onPressed: () => _showReactionPicker(context),
                ),
                _buildActionButton(
                  context: context,
                  icon: Icons.chat_bubble_outline,
                  label: '${post.commentCount}',
                  onPressed: () => context.push('/post-detail/${post.id}', extra: post),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: AppColors.textSecondary),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    Color color = AppColors.textSecondary,
    required VoidCallback onPressed,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: AppTextStyles.bodySmall.copyWith(color: color)),
    );
  }

  IconData _getReactionIcon(String? reaction) {
    switch (reaction) {
      case 'Like': return Icons.thumb_up;
      case 'Love': return Icons.favorite;
      case 'Haha': return Icons.emoji_emotions;
      case 'Wow': return Icons.sentiment_very_satisfied;
      case 'Sad': return Icons.sentiment_dissatisfied;
      case 'Angry': return Icons.sentiment_very_dissatisfied;
      default: return Icons.thumb_up_outlined;
    }
  }

  void _showReactionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ReactionItem(icon: Icons.thumb_up, color: Colors.blue, type: 'Like', postId: post.id),
              _ReactionItem(icon: Icons.favorite, color: Colors.red, type: 'Love', postId: post.id),
              _ReactionItem(icon: Icons.emoji_emotions, color: Colors.yellow[700]!, type: 'Haha', postId: post.id),
              _ReactionItem(icon: Icons.sentiment_very_satisfied, color: Colors.orange, type: 'Wow', postId: post.id),
              _ReactionItem(icon: Icons.sentiment_dissatisfied, color: Colors.blueGrey, type: 'Sad', postId: post.id),
              _ReactionItem(icon: Icons.sentiment_very_dissatisfied, color: Colors.redAccent, type: 'Angry', postId: post.id),
            ],
          ),
        );
      },
    );
  }

  void _showPostOptions(BuildContext context, String currentUserId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (post.userId == currentUserId) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Chỉnh sửa bài viết'),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Xóa bài viết', style: TextStyle(color: AppColors.error)),
                  onTap: () => Navigator.pop(context),
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.report_problem_outlined),
                  title: const Text('Báo cáo bài viết'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ReactionItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String type;
  final int postId;

  const _ReactionItem({
    required this.icon,
    required this.color,
    required this.type,
    required this.postId,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: color, size: 32),
      onPressed: () {
        context.read<SocialFeedBloc>().add(UpdatePostReaction(postId, type));
        Navigator.pop(context);
      },
    );
  }
}
