import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/social/data/models/post_model.dart';

class SocialFeedState extends Equatable {
  final List<PostModel> posts;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final bool isPersonalized;

  const SocialFeedState({
    this.posts = const [],
    this.nextCursor,
    this.hasMore = true,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.isPersonalized = false,
  });

  SocialFeedState copyWith({
    List<PostModel>? posts,
    String? nextCursor,
    bool? hasMore,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool? isPersonalized,
  }) {
    return SocialFeedState(
      posts: posts ?? this.posts,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
      isPersonalized: isPersonalized ?? this.isPersonalized,
    );
  }

  @override
  List<Object?> get props => [
        posts,
        nextCursor,
        hasMore,
        isLoading,
        isLoadingMore,
        error,
        isPersonalized,
      ];
}
