import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ameko_app/features/social/data/models/post_model.dart';
import 'package:ameko_app/features/social/data/models/comment_model.dart';
import 'package:ameko_app/features/social/domain/repositories/social_repository.dart';

abstract class PostDetailEvent extends Equatable {
  const PostDetailEvent();
  @override
  List<Object?> get props => [];
}

class FetchComments extends PostDetailEvent {
  final int postId;
  const FetchComments(this.postId);
  @override
  List<Object?> get props => [postId];
}

class AddCommentRequested extends PostDetailEvent {
  final int postId;
  final String content;
  const AddCommentRequested(this.postId, this.content);
  @override
  List<Object?> get props => [postId, content];
}

class PostDetailState extends Equatable {
  final PostModel? post;
  final List<CommentModel> comments;
  final bool isLoadingComments;
  final bool hasMoreComments;
  final int currentCommentPage;
  final String? error;

  const PostDetailState({
    this.post,
    this.comments = const [],
    this.isLoadingComments = false,
    this.hasMoreComments = true,
    this.currentCommentPage = 0,
    this.error,
  });

  PostDetailState copyWith({
    PostModel? post,
    List<CommentModel>? comments,
    bool? isLoadingComments,
    bool? hasMoreComments,
    int? currentCommentPage,
    String? error,
  }) {
    return PostDetailState(
      post: post ?? this.post,
      comments: comments ?? this.comments,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      currentCommentPage: currentCommentPage ?? this.currentCommentPage,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [post, comments, isLoadingComments, hasMoreComments, currentCommentPage, error];
}

class PostDetailBloc extends Bloc<PostDetailEvent, PostDetailState> {
  final SocialRepository _repository;

  PostDetailBloc({required SocialRepository repository, PostModel? initialPost})
      : _repository = repository,
        super(PostDetailState(post: initialPost)) {
    on<FetchComments>(_onFetchComments);
    on<AddCommentRequested>(_onAddCommentRequested);
  }

  Future<void> _onFetchComments(FetchComments event, Emitter<PostDetailState> emit) async {
    if (state.isLoadingComments || !state.hasMoreComments) return;

    emit(state.copyWith(isLoadingComments: true));

    final result = await _repository.getComments(event.postId, page: state.currentCommentPage + 1);

    result.fold(
      (failure) => emit(state.copyWith(isLoadingComments: false, error: failure.message)),
      (data) {
        final newComments = data['items'] as List<CommentModel>;
        
        // Filter out any duplicates that might have been fetched or added optimistically
        final existingIds = state.comments.map((c) => c.id).toSet();
        final uniqueNewComments = newComments.where((c) => !existingIds.contains(c.id)).toList();
        
        final hasMore = data['hasNextPage'] == true && uniqueNewComments.isNotEmpty;
        
        emit(state.copyWith(
          isLoadingComments: false,
          comments: [...state.comments, ...uniqueNewComments],
          hasMoreComments: hasMore,
          currentCommentPage: state.currentCommentPage + 1,
        ));
      },
    );
  }

  Future<void> _onAddCommentRequested(AddCommentRequested event, Emitter<PostDetailState> emit) async {
    // We could do optimistic update here if we have user info
    final result = await _repository.addComment(event.postId, event.content);

    result.fold(
      (failure) => emit(state.copyWith(error: failure.message)),
      (comment) {
        emit(state.copyWith(
          comments: [comment, ...state.comments],
          post: state.post?.copyWith(commentCount: (state.post?.commentCount ?? 0) + 1),
        ));
      },
    );
  }
}
