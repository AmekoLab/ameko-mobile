import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/features/social/data/models/post_model.dart';
import 'package:ameko_app/features/social/domain/repositories/social_repository.dart';
import 'package:ameko_app/features/social/presentation/bloc/social_feed_event.dart';
import 'package:ameko_app/features/social/presentation/bloc/social_feed_state.dart';

class SocialFeedBloc extends Bloc<SocialFeedEvent, SocialFeedState> {
  final SocialRepository _repository;
  final Set<int> _loadedPostIds = {};

  SocialFeedBloc({required SocialRepository repository})
      : _repository = repository,
        super(const SocialFeedState()) {
    on<FetchInitialFeed>(_onFetchInitialFeed);
    on<FetchMorePosts>(_onFetchMorePosts);
    on<AddNewPost>(_onAddNewPost);
    on<UpdatePostReaction>(_onUpdatePostReaction);
    on<UpdatePostCommentCount>(_onUpdatePostCommentCount);
  }

  Future<void> _onFetchInitialFeed(
    FetchInitialFeed event,
    Emitter<SocialFeedState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null, isPersonalized: event.isPersonalized));
    _loadedPostIds.clear();

    final result = event.isPersonalized
        ? await _repository.getPersonalizedFeed()
        : await _repository.getFeed();

    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (data) {
        final posts = data['items'] as List<PostModel>;
        for (var post in posts) {
          _loadedPostIds.add(post.id);
        }
        emit(state.copyWith(
          isLoading: false,
          posts: posts,
          nextCursor: data['nextCursor'],
          hasMore: data['hasMore'] ?? data['hasNextPage'] ?? false,
        ));
      },
    );
  }

  Future<void> _onFetchMorePosts(
    FetchMorePosts event,
    Emitter<SocialFeedState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));

    final result = state.isPersonalized
        ? await _repository.getPersonalizedFeed(page: (state.posts.length ~/ 20) + 1)
        : await _repository.getFeed(cursor: state.nextCursor);

    result.fold(
      (failure) => emit(state.copyWith(isLoadingMore: false, error: failure.message)),
      (data) {
        final newPosts = data['items'] as List<PostModel>;
        final deduplicatedPosts = newPosts.where((post) => _loadedPostIds.add(post.id)).toList();

        emit(state.copyWith(
          isLoadingMore: false,
          posts: [...state.posts, ...deduplicatedPosts],
          nextCursor: data['nextCursor'],
          hasMore: data['hasMore'] ?? data['hasNextPage'] ?? false,
        ));
      },
    );
  }

  void _onAddNewPost(AddNewPost event, Emitter<SocialFeedState> emit) {
    if (_loadedPostIds.add(event.post.id)) {
      emit(state.copyWith(posts: [event.post, ...state.posts]));
    }
  }

  void _onUpdatePostReaction(UpdatePostReaction event, Emitter<SocialFeedState> emit) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == event.postId) {
        final currentReaction = post.currentUserReaction;
        final newReaction = event.reactionType;

        int reactionCount = post.reactionCount;
        if (currentReaction == null && newReaction != null) {
          reactionCount++;
        } else if (currentReaction != null && newReaction == null) {
          reactionCount--;
        }

        return post.copyWith(
          currentUserReaction: newReaction,
          reactionCount: reactionCount,
        );
      }
      return post;
    }).toList();

    emit(state.copyWith(posts: updatedPosts));
  }

  void _onUpdatePostCommentCount(UpdatePostCommentCount event, Emitter<SocialFeedState> emit) {
    final updatedPosts = state.posts.map((post) {
      if (post.id == event.postId) {
        return post.copyWith(commentCount: post.commentCount + event.increment);
      }
      return post;
    }).toList();

    emit(state.copyWith(posts: updatedPosts));
  }
}
