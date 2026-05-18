import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/social/data/models/post_model.dart';
import 'package:ameko_app/features/social/presentation/bloc/post_detail_bloc.dart';
import 'package:ameko_app/features/social/presentation/widgets/post_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  final PostModel? initialPost;

  const PostDetailScreen({super.key, required this.postId, this.initialPost});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Bài viết', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary)),
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: BlocBuilder<PostDetailBloc, PostDetailState>(
        builder: (context, state) {
          if (state.post == null && state.isLoadingComments) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    if (state.post != null) PostCard(post: state.post!),
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('Bình luận', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: state.comments.length + (state.hasMoreComments ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.comments.length) {
                          context.read<PostDetailBloc>().add(FetchComments(widget.postId));
                          return const Center(child: CircularProgressIndicator());
                        }
                        final comment = state.comments[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: comment.avatarUrl != null ? CachedNetworkImageProvider(comment.avatarUrl!) : null,
                            child: comment.avatarUrl == null ? Text(comment.username[0].toUpperCase()) : null,
                          ),
                          title: Text(comment.fullName, style: AppTextStyles.titleSmall),
                          subtitle: Text(comment.content, style: AppTextStyles.body),
                        );
                      },
                    ),
                  ],
                ),
              ),
              _buildCommentInput(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Viết bình luận...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  fillColor: AppColors.surfaceVariant,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primary),
              onPressed: () {
                final content = _commentController.text.trim();
                if (content.isNotEmpty) {
                  context.read<PostDetailBloc>().add(AddCommentRequested(widget.postId, content));
                  _commentController.clear();
                  FocusScope.of(context).unfocus();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
