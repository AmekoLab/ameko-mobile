import 'package:equatable/equatable.dart';
import 'package:ameko_app/features/social/data/models/post_model.dart';

abstract class SocialFeedEvent extends Equatable {
  const SocialFeedEvent();

  @override
  List<Object?> get props => [];
}

class FetchInitialFeed extends SocialFeedEvent {
  final bool isPersonalized;
  const FetchInitialFeed({this.isPersonalized = false});

  @override
  List<Object?> get props => [isPersonalized];
}

class FetchMorePosts extends SocialFeedEvent {}

class AddNewPost extends SocialFeedEvent {
  final PostModel post;
  const AddNewPost(this.post);

  @override
  List<Object?> get props => [post];
}

class UpdatePostReaction extends SocialFeedEvent {
  final int postId;
  final String? reactionType;
  const UpdatePostReaction(this.postId, this.reactionType);

  @override
  List<Object?> get props => [postId, reactionType];
}

class UpdatePostCommentCount extends SocialFeedEvent {
  final int postId;
  final int increment;
  const UpdatePostCommentCount(this.postId, this.increment);

  @override
  List<Object?> get props => [postId, increment];
}
