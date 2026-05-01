import 'package:ameko_app/core/utils/app_logger.dart';
import 'package:ameko_app/features/social/data/models/post_model.dart';
import 'package:signalr_netcore/signalr_client.dart';

typedef PostCreatedCallback = void Function(PostModel post);
typedef SocialReactionCallback = void Function(Map<String, dynamic> reactionData);
typedef CommentAddedCallback = void Function(Map<String, dynamic> commentData);

class SocialSignalRService {
  HubConnection? _connection;
  bool _isConnected = false;

  final List<PostCreatedCallback> _postCreatedListeners = [];
  final List<SocialReactionCallback> _reactionListeners = [];
  final List<CommentAddedCallback> _commentListeners = [];

  Future<void> connect(String hubUrl, {String? token}) async {
    try {
      _connection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: token != null ? () async => token : null,
              transport: HttpTransportType.WebSockets,
              skipNegotiation: true,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _connection!.on('postCreated', _handlePostCreated);
      _connection!.on('reactionChanged', _handleReactionChanged);
      _connection!.on('commentAdded', _handleCommentAdded);

      await _connection!.start();
      _isConnected = true;
      appLogger.i('SocialSignalRService connected');
    } catch (e) {
      _isConnected = false;
      appLogger.e('SocialSignalRService connection failed: $e');
    }
  }

  void _handlePostCreated(List<Object?>? args) {
    if (args != null && args.isNotEmpty && args[0] is Map) {
      final post = PostModel.fromJson(Map<String, dynamic>.from(args[0] as Map));
      for (var listener in _postCreatedListeners) {
        listener(post);
      }
    }
  }

  void _handleReactionChanged(List<Object?>? args) {
    if (args != null && args.isNotEmpty && args[0] is Map) {
      final data = Map<String, dynamic>.from(args[0] as Map);
      for (var listener in _reactionListeners) {
        listener(data);
      }
    }
  }

  void _handleCommentAdded(List<Object?>? args) {
    if (args != null && args.isNotEmpty && args[0] is Map) {
      final data = Map<String, dynamic>.from(args[0] as Map);
      for (var listener in _commentListeners) {
        listener(data);
      }
    }
  }

  void onPostCreated(PostCreatedCallback callback) => _postCreatedListeners.add(callback);
  void onReactionChanged(SocialReactionCallback callback) => _reactionListeners.add(callback);
  void onCommentAdded(CommentAddedCallback callback) => _commentListeners.add(callback);

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.stop();
      _isConnected = false;
    }
  }
}
