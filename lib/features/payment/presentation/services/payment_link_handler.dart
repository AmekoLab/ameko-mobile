import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class PaymentLinkHandler {
  final GoRouter router;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  PaymentLinkHandler(this.router);

  void init() {
    _appLinks = AppLinks();

    // Handle links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('AppLinks Error: $err');
    });

    // Handle initial link (if app was opened via deep link)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received Deep Link: $uri');
    
    // Check if it's our payment callback
    // ameko://payment/callback?paid=1&orderId=...
    if (uri.scheme == 'ameko' && uri.host == 'payment' && uri.path == '/callback') {
      final queryParams = uri.queryParameters;
      final paid = queryParams['paid'] == '1';
      final message = queryParams['message'] ?? (paid ? 'Thanh toán thành công' : 'Thanh toán thất bại');
      
      router.pushReplacement('/payment/result', extra: {
        'success': paid,
        'paymentMethod': 'VnPay',
        'message': message,
      });
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
