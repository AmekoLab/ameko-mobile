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
  final CheckoutBloc? checkoutBloc;

  const VnpayWebviewScreen({
    super.key,
    required this.paymentUrl,
    this.checkoutBloc,
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
    if (widget.checkoutBloc != null) {
      return BlocProvider.value(
        value: widget.checkoutBloc!,
        child: BlocListener<CheckoutBloc, CheckoutState>(
          listener: (context, state) {
            if (state.status == CheckoutStatus.success && state.result != null) {
              context.pushReplacement('/payment/result', extra: {
                'success': true,
                'paymentMethod': state.result!.paymentMethod,
                'message': state.result!.message ?? 'Thanh toán thành công!',
              });
            } else if (state.status == CheckoutStatus.failure) {
              context.pushReplacement('/payment/result', extra: {
                'success': false,
                'paymentMethod': 'VnPay',
                'message': state.message,
              });
            }
          },
          child: _buildScaffold(context),
        ),
      );
    }

    return _buildScaffold(context);
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
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
                'THANH TOÁN',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Cổng thanh toán',
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
              final host = challenge.protectionSpace.host;
              if (host == '10.0.2.2' || host == 'localhost' || host.startsWith('192.168.')) {
                return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
              }
              return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.CANCEL);
            },
            shouldOverrideUrlLoading: (controller, action) async {
              final url = action.request.url;
              final urlStr = url?.toString() ?? '';

              if (urlStr.startsWith('ameko://payment')) {
                _handleUrlChange(context, urlStr);
                return NavigationActionPolicy.CANCEL;
              }

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
    );
  }

  void _handleUrlChange(BuildContext context, String url) {
    if (_isConfirming) return;

    // Detect Success/Cancel URLs (Generic for Stripe/Direct redirects)
    if (url.contains('payment/success')) {
      Navigator.of(context).pop(true);
      return;
    }
    if (url.contains('payment/cancel')) {
      Navigator.of(context).pop(false);
      return;
    }

    // VNPAY specific logic
    if (url.startsWith('ameko://payment') || url.contains('vnp_ResponseCode')) {
      if (widget.checkoutBloc == null) return;
      
      setState(() => _isConfirming = true);
      final uri = Uri.tryParse(url);
      if (uri != null) {
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

        final params = Map<String, String>.from(uri.queryParameters);
        widget.checkoutBloc!.add(ConfirmVnpayPayment(params));
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
          'Bạn có chắc muốn huỷ thanh toán không?',
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
      Navigator.of(context).pop(false);
    }
  }
}
