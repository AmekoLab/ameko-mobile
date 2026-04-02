import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:ameko_app/core/utils/app_logger.dart';

typedef MessageCallback = void Function(String senderId, String message);

/// SignalR-based real-time chat service with mock fallback.
class ChatService {
  HubConnection? _connection;
  bool _isConnected = false;
  final List<MessageCallback> _listeners = [];

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
          .withAutomaticReconnect()
          .build();

      _connection!.on('ReceiveMessage', (args) {
        if (args != null && args.length >= 2) {
          final senderId = args[0].toString();
          final message = args[1].toString();
          appLogger.d('📨 Chat message from $senderId: $message');
          for (final listener in _listeners) {
            listener(senderId, message);
          }
        }
      });

      await _connection!.start();
      _isConnected = true;
      appLogger.i('ChatService connected to $hubUrl');
    } catch (e) {
      _isConnected = false;
      appLogger.w('ChatService connection failed, falling back to mock: $e');
    }
  }

  Future<void> sendMessage(String chatId, String message) async {
    if (_isConnected && _connection != null) {
      try {
        await _connection!.invoke('SendMessage', args: [chatId, message]);
      } catch (e) {
        appLogger.e('Failed to send SignalR message', error: e);
      }
    } else {
      appLogger.d('Mock send: [$chatId] "$message"');
    }
  }

  void onMessageReceived(MessageCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(MessageCallback callback) {
    _listeners.remove(callback);
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.stop();
      _isConnected = false;
      _listeners.clear();
      appLogger.i('ChatService disconnected');
    }
  }

  bool get isConnected => _isConnected;
}
