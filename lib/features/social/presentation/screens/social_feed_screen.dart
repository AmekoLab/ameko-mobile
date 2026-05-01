import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/social/presentation/bloc/social_feed_bloc.dart';
import 'package:ameko_app/features/social/presentation/bloc/social_feed_event.dart';
import 'package:ameko_app/features/social/presentation/bloc/social_feed_state.dart';
import 'package:ameko_app/features/social/presentation/widgets/post_card.dart';

class SocialFeedScreen extends StatelessWidget {
  const SocialFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SocialFeedBloc, SocialFeedState>(
      builder: (context, state) {
        if (state.isLoading && state.posts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.error != null && state.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${state.error}', style: AppTextStyles.body),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<SocialFeedBloc>().add(FetchInitialFeed(isPersonalized: state.isPersonalized)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<SocialFeedBloc>().add(FetchInitialFeed(isPersonalized: state.isPersonalized));
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: state.posts.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
            itemBuilder: (context, index) {
              if (index == state.posts.length) {
                context.read<SocialFeedBloc>().add(FetchMorePosts());
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return PostCard(post: state.posts[index]);
            },
          ),
        );
      },
    );
  }
}
