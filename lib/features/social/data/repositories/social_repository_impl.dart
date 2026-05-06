import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:ameko_app/core/errors/failures.dart';
import 'package:ameko_app/core/utils/app_logger.dart';
import 'package:ameko_app/features/social/data/models/post_model.dart';
import 'package:ameko_app/features/social/data/models/comment_model.dart';
import 'package:ameko_app/features/social/domain/repositories/social_repository.dart';

class SocialRepositoryImpl implements SocialRepository {
  final Dio _dio;

  SocialRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, Map<String, dynamic>>> getFeed({String? cursor, int pageSize = 20}) async {
    try {
      final response = await _dio.get(
        '/api/v1/SocialCommerce/posts/feed',
        queryParameters: {
          if (cursor != null) 'cursor': cursor,
          'pageSize': pageSize,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Right({
        'items': (data['items'] as List).map((e) => PostModel.fromJson(e)).toList(),
        'nextCursor': data['nextCursor'],
        'hasMore': data['hasMore'],
      });
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getPersonalizedFeed({int page = 1, int size = 20}) async {
    try {
      final response = await _dio.get(
        '/api/v1/SocialCommerce/personalized-feed',
        queryParameters: {'page': page, 'size': size},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Right({
        'items': (data['items'] as List).map((e) => PostModel.fromJson(e)).toList(),
        'hasNextPage': data['hasNextPage'],
        'totalPages': data['totalPages'],
      });
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PostModel>>> getUserPosts(String userId, {int page = 1, int size = 20}) async {
    try {
      final response = await _dio.get(
        '/api/v1/SocialCommerce/users/$userId/posts',
        queryParameters: {'page': page, 'size': size},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Right((data['items'] as List).map((e) => PostModel.fromJson(e)).toList());
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PostModel>> createPost({
    required String title,
    List<String>? attachmentUrls,
    String? assembledProductId,
  }) async {
    try {
      final response = await _dio.post(
        '/api/v1/SocialCommerce/posts',
        data: {
          'title': title,
          if (attachmentUrls != null) 'attachmentUrls': attachmentUrls,
          if (assembledProductId != null) 'assembledProductId': assembledProductId,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Right(PostModel.fromJson(data));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, PostModel>> updatePost(int postId, {required String title}) async {
    try {
      final response = await _dio.put(
        '/api/v1/SocialCommerce/posts/$postId',
        data: {'title': title},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Right(PostModel.fromJson(data));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePost(int postId) async {
    try {
      await _dio.delete('/api/v1/SocialCommerce/posts/$postId');
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reactToPost(int postId, String reactionType) async {
    try {
      await _dio.post(
        '/api/v1/SocialCommerce/posts/$postId/react',
        data: {'type': reactionType},
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePostReaction(int postId) async {
    try {
      await _dio.delete('/api/v1/SocialCommerce/posts/$postId/reactions');
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPostReactions(int postId) async {
    try {
      final response = await _dio.get('/api/v1/SocialCommerce/posts/$postId/reactions');
      final data = response.data['data'] as List;
      return Right(List<Map<String, dynamic>>.from(data));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getComments(int postId, {int page = 1, int size = 20}) async {
    try {
      final response = await _dio.get(
        '/api/v1/SocialCommerce/posts/$postId/comments',
        queryParameters: {'page': page, 'size': size},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Right({
        'items': (data['items'] as List).map((e) => CommentModel.fromJson(e)).toList(),
        'hasNextPage': data['hasNextPage'],
      });
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CommentModel>> addComment(int postId, String content) async {
    try {
      final response = await _dio.post(
        '/api/v1/SocialCommerce/posts/$postId/comments',
        data: {'content': content},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Right(CommentModel.fromJson(data));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CommentModel>> updateComment(int postId, int commentId, String content) async {
    try {
      final response = await _dio.put(
        '/api/v1/SocialCommerce/comments/$commentId',
        data: {'content': content},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Right(CommentModel.fromJson(data));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteComment(int postId, int commentId) async {
    try {
      await _dio.delete('/api/v1/SocialCommerce/comments/$commentId/soft-delete');
      return const Right(null);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> toggleFollow(String userId) async {
    try {
      final response = await _dio.post('/api/v1/follows/toggle/$userId');
      return Right(response.data);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getFollowingList({int page = 1, int size = 20}) async {
    try {
      final response = await _dio.get(
        '/api/v1/follows/following',
        queryParameters: {'page': page, 'size': size},
      );
      return Right(List<Map<String, dynamic>>.from(response.data['items']));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkFollowStatus(String userId) async {
    try {
      final response = await _dio.get('/api/v1/follows/status/$userId');
      return Right(response.data['isFollowing']);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutFailure();
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NoInternetFailure();
    }
    
    final response = e.response;
    if (response != null) {
      if (response.statusCode == 401) return const UnauthorizedFailure();
      
      final data = response.data;
      if (data is Map) {
        final msg = data['message'] ?? data['msg'] ?? data['error'];
        if (msg != null) return ServerFailure(message: msg.toString());
      }
      return const ServerFailure();
    }
    
    return const UnknownFailure();
  }
}
