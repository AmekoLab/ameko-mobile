import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:ameko_app/core/utils/app_logger.dart';

typedef MessageCallback = void Function(Map<String, dynamic> messageData);
typedef ReactionCallback = void Function(Map<String, dynamic> reactionData);
typedef ReadReceiptCallback = void Function(Map<String, dynamic> receiptData);

/// SignalR-based real-time chat service following Nest.js/Next.js architecture.
class ChatService {
  HubConnection? _connection;
  bool _isConnected = false;
  
  final List<MessageCallback> _messageListeners = [];
  final List<ReactionCallback> _reactionListeners = [];
  final List<ReadReceiptCallback> _readReceiptListeners = [];

  Future<void> connect(String hubUrl, {String? token}) async {
    try {
      _connection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory:
                  token != null ? () async => token : null,
              transport: HttpTransportType.WebSockets,
              skipNegotiation: true,
            ),
          )
          .withAutomaticReconnect(
            retryDelays: [0, 2000, 10000, 30000],
          )
          .build();

      // Dual listening for message arrivals
      _connection!.on('ReceiveMessage', _handleMessage);
      _connection!.on('messageReceived', _handleMessage);
      
      // Additional events
      _connection!.on('reactionChanged', _handleReaction);
      _connection!.on('readReceipt', _handleReadReceipt);

      await _connection!.start();
      _isConnected = true;
      appLogger.i('ChatService connected to $hubUrl');
    } catch (e) {
      _isConnected = false;
      appLogger.w('ChatService connection failed: $e');
    }
  }

  void _handleMessage(List<Object?>? args) {
    if (args != null && args.isNotEmpty) {
      // Assuming payload is a Map (Full Message Object) 
      // or [senderId, message] based on prev implementation.
      // We'll support both for flexibility.
      Map<String, dynamic> data;
      if (args[0] is Map) {
        data = Map<String, dynamic>.from(args[0] as Map);
      } else if (args.length >= 2) {
        data = {
          'senderId': args[0].toString(),
          'content': args[1].toString(),
        };
      } else {
        return;
      }
      
      appLogger.d('📨 Chat message received: $data');
      for (final listener in _messageListeners) {
        listener(data);
      }
    }
  }

  void _handleReaction(List<Object?>? args) {
    if (args != null && args.isNotEmpty && args[0] is Map) {
      final data = Map<String, dynamic>.from(args[0] as Map);
      appLogger.d('👍 Reaction changed: $data');
      for (final listener in _reactionListeners) {
        listener(data);
      }
    }
  }

  void _handleReadReceipt(List<Object?>? args) {
    if (args != null && args.isNotEmpty && args[0] is Map) {
      final data = Map<String, dynamic>.from(args[0] as Map);
      appLogger.d('📖 Read receipt: $data');
      for (final listener in _readReceiptListeners) {
        listener(data);
      }
    }
  }

  Future<void> joinConversation(String conversationId) async {
    if (_isConnected && _connection != null) {
      final id = int.tryParse(conversationId);
      if (id != null) {
        await _connection!.invoke('JoinConversation', args: [id]);
      }
    }
  }

  Future<void> leaveConversation(String conversationId) async {
    if (_isConnected && _connection != null) {
      final id = int.tryParse(conversationId);
      if (id != null) {
        await _connection!.invoke('LeaveConversation', args: [id]);
      }
    }
  }

  Future<void> sendMessage(String chatId, String message) async {
    if (_isConnected && _connection != null) {
      try {
        final id = int.tryParse(chatId);
        if (id != null) {
          await _connection!.invoke('SendMessage', args: [
            {
              'conversationId': id,
              'content': message,
              'messageType': 0, // Default to text
            }
          ]);
        }
      } catch (e) {
        appLogger.e('Failed to send SignalR message', error: e);
      }
    }
  }

  void onMessageReceived(MessageCallback callback) => _messageListeners.add(callback);
  void offMessageReceived(MessageCallback callback) => _messageListeners.remove(callback);

  void onReactionChanged(ReactionCallback callback) => _reactionListeners.add(callback);
  void offReactionChanged(ReactionCallback callback) => _reactionListeners.remove(callback);

  void onReadReceipt(ReadReceiptCallback callback) => _readReceiptListeners.add(callback);
  void offReadReceipt(ReadReceiptCallback callback) => _readReceiptListeners.remove(callback);

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.stop();
      _isConnected = false;
      _messageListeners.clear();
      _reactionListeners.clear();
      _readReceiptListeners.clear();
      appLogger.i('ChatService disconnected');
    }
  }

  bool get isConnected => _isConnected;
}
