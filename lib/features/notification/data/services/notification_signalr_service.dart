import 'package:ameko_app/core/utils/app_logger.dart';
import 'package:ameko_app/features/notification/data/models/notification_model.dart';
import 'package:signalr_netcore/signalr_client.dart';

typedef NotificationCallback = void Function(NotificationModel notification);

class NotificationSignalRService {
  HubConnection? _connection;
  bool _isConnected = false;
  final List<NotificationCallback> _listeners = [];

  Future<void> connect(String hubUrl, {Future<String?> Function()? accessTokenFactory}) async {
    if (_isConnected) return;

    try {
      _connection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: accessTokenFactory != null
                  ? () async {
                      final token = await accessTokenFactory();
                      return token ?? '';
                    }
                  : null,
              transport: HttpTransportType.WebSockets,
              skipNegotiation: true,
            ),
          )
          .withAutomaticReconnect()
          .build();

      _connection!.on('notificationReceived', _handleNotificationReceived);

      _connection!.onclose(({error}) {
        _isConnected = false;
        appLogger.w('NotificationSignalRService connection closed: $error');
      });

      await _connection!.start();
      _isConnected = true;
      appLogger.i('NotificationSignalRService connected');
    } catch (e) {
      _isConnected = false;
      appLogger.e('NotificationSignalRService connection failed: $e');
    }
  }

  void _handleNotificationReceived(List<Object?>? args) {
    if (args != null && args.isNotEmpty && args[0] is Map) {
      try {
        final data = Map<String, dynamic>.from(args[0] as Map);
        final notification = NotificationModel.fromJson(data);
        for (var listener in _listeners) {
          listener(notification);
        }
      } catch (e) {
        appLogger.e('Error parsing notification from SignalR: $e');
      }
    }
  }

  void onNotificationReceived(NotificationCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(NotificationCallback callback) {
    _listeners.remove(callback);
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.stop();
      _isConnected = false;
    }
  }
}
