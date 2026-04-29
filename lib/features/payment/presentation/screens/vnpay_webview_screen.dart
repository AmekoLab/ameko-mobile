import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:go_router/go_router.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_bloc.dart';
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_event.dart';
import 'package:ameko_app/features/payment/presentation/bloc/checkout/checkout_state.dart';
import 'package:url_launcher/url_launcher.dart';

class VnpayWebviewScreen extends StatefulWidget {
  final String paymentUrl;
  final CheckoutBloc checkoutBloc;

  const VnpayWebviewScreen({
    super.key,
    required this.paymentUrl,
    required this.checkoutBloc,
  });

  @override
  State<VnpayWebviewScreen> createState() => _VnpayWebviewScreenState();
}

class _VnpayWebviewScreenState extends State<VnpayWebviewScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.checkoutBloc,
      child: BlocListener<CheckoutBloc, CheckoutState>(
        listener: (context, state) {
          if (state is CheckoutSuccess) {
            context.pushReplacement('/payment/result', extra: {
              'success': true,
              'paymentMethod': state.result.paymentMethod,
              'message': state.result.message ?? 'Thanh toán thành công!',
            });
          } else if (state is CheckoutFailure) {
            context.pushReplacement('/payment/result', extra: {
              'success': false,
              'paymentMethod': 'VnPay',
              'message': state.message,
            });
          }
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: AppColors.textPrimary),
              onPressed: () => _showCancelDialog(context),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.blue[700],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'VNPAY',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Thanh toán',
                  style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
            actions: [
              if (_isConfirming)
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(
                  url: WebUri(widget.paymentUrl),
                ),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  useShouldOverrideUrlLoading: true,
                  allowsInlineMediaPlayback: true,
                ),
                onWebViewCreated: (controller) {
                  _webViewController = controller;
                },
                onLoadStart: (_, url) {
                  setState(() => _isLoading = true);
                  _handleUrlChange(context, url?.toString() ?? '');
                },
                onLoadStop: (_, __) => setState(() => _isLoading = false),
                onReceivedServerTrustAuthRequest: (controller, challenge) async {
                  // Bypass SSL errors for local development (e.g. 10.0.2.2)
                  final host = challenge.protectionSpace.host;
                  if (host == '10.0.2.2' || host == 'localhost' || host.startsWith('192.168.')) {
                    return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
                  }
                  return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.CANCEL);
                },
                shouldOverrideUrlLoading: (controller, action) async {
                  final url = action.request.url;
                  final urlStr = url?.toString() ?? '';

                  // Handle deep links from backend (ameko://payment/callback)
                  if (urlStr.startsWith('ameko://payment')) {
                    _handleUrlChange(context, urlStr);
                    return NavigationActionPolicy.CANCEL;
                  }

                  // Handle banking app schemes (vnpay://, tpb://, etc.)
                  if (url != null && !['http', 'https', 'file', 'chrome', 'data', 'javascript', 'about'].contains(url.scheme)) {
                    if (await canLaunchUrl(Uri.parse(urlStr))) {
                      await launchUrl(Uri.parse(urlStr), mode: LaunchMode.externalApplication);
                      return NavigationActionPolicy.CANCEL;
                    }
                  }

                  _handleUrlChange(context, urlStr);
                  return NavigationActionPolicy.ALLOW;
                },
              ),
              if (_isLoading)
                const LinearProgressIndicator(
                  color: AppColors.primary,
                  backgroundColor: Colors.transparent,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleUrlChange(BuildContext context, String url) {
    if (_isConfirming) return;

    // Detect deep link from backend redirect or VNPAY response parameters
    if (url.startsWith('ameko://payment') || url.contains('vnp_ResponseCode')) {
      setState(() => _isConfirming = true);

      final uri = Uri.tryParse(url);
      if (uri != null) {
        // If it's the deep link, parse query parameters and go to result screen
        if (url.startsWith('ameko://payment')) {
          final queryParams = uri.queryParameters;
          final paid = queryParams['paid'] == '1';
          
          context.pushReplacement('/payment/result', extra: {
            'success': paid,
            'paymentMethod': 'VnPay',
            'message': queryParams['message'] ?? (paid ? 'Thanh toán thành công!' : 'Thanh toán thất bại'),
            'orderId': queryParams['orderId'],
          });
          return;
        }

        // If it's a direct VNPAY return URL (for normal flow), trigger confirmation
        final params = Map<String, String>.from(uri.queryParameters);
        widget.checkoutBloc.add(ConfirmVnpayPayment(params));
      }
    }
  }

  Future<void> _showCancelDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Huỷ thanh toán?', style: AppTextStyles.titleSmall),
        content: Text(
          'Bạn có chắc muốn huỷ thanh toán VNPAY không?',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tiếp tục',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Huỷ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.go('/home');
    }
  }
}
