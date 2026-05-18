import 'package:dartz/dartz.dart';
import 'package:ameko_app/core/errors/failures.dart';
import 'package:ameko_app/features/social/data/models/post_model.dart';
import 'package:ameko_app/features/social/data/models/comment_model.dart';

abstract class SocialRepository {
  // Feed
  Future<Either<Failure, Map<String, dynamic>>> getFeed({String? cursor, int pageSize = 20});
  Future<Either<Failure, Map<String, dynamic>>> getPersonalizedFeed({int page = 1, int size = 20});
  Future<Either<Failure, List<PostModel>>> getUserPosts(String userId, {int page = 1, int size = 20});

  // Post CRUD
  Future<Either<Failure, PostModel>> createPost({
    required String title,
    List<String>? attachmentUrls,
    String? assembledProductId,
  });
  Future<Either<Failure, PostModel>> updatePost(int postId, {required String title});
  Future<Either<Failure, void>> deletePost(int postId);

  // Reactions
  Future<Either<Failure, void>> reactToPost(int postId, String reactionType);
  Future<Either<Failure, void>> deletePostReaction(int postId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getPostReactions(int postId);

  // Comments
  Future<Either<Failure, Map<String, dynamic>>> getComments(int postId, {int page = 1, int size = 20});
  Future<Either<Failure, CommentModel>> addComment(int postId, String content);
  Future<Either<Failure, CommentModel>> updateComment(int postId, int commentId, String content);
  Future<Either<Failure, void>> deleteComment(int postId, int commentId);

  // Follows
  Future<Either<Failure, Map<String, dynamic>>> toggleFollow(String userId);
  Future<Either<Failure, List<Map<String, dynamic>>>> getFollowingList({int page = 1, int size = 20});
  Future<Either<Failure, bool>> checkFollowStatus(String userId);
}
