import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final String paymentMethod;
  final String message;

  const PaymentResultScreen({
    super.key,
    required this.success,
    required this.paymentMethod,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              // ─── Icon ─────────────────────────────────────────
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                builder: (_, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: success
                        ? const Color(0xFF22C55E).withOpacity(0.12)
                        : Colors.red.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    success
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 72,
                    color: success
                        ? const Color(0xFF22C55E)
                        : Colors.red[600],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── Title ────────────────────────────────────────
              Text(
                success ? 'Thanh toán thành công!' : 'Thanh toán thất bại',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                message,
                style: AppTextStyles.body
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // ─── Payment Method Badge ──────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  'Phương thức: $paymentMethod',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),

              const Spacer(),

              // ─── Actions ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/orders'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Xem đơn hàng của tôi',
                    style: AppTextStyles.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Tiếp tục mua sắm',
                    style: AppTextStyles.button
                        .copyWith(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
