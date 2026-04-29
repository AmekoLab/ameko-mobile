import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';

enum PaymentMethod { wallet, vnpay }

/// Card-style payment method selector with animated selection highlight.
class PaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selected;
  final double? walletBalance;
  final ValueChanged<PaymentMethod> onChanged;

  const PaymentMethodSelector({
    super.key,
    required this.selected,
    this.walletBalance,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Phương thức thanh toán',
            style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        _buildOption(
          method: PaymentMethod.wallet,
          icon: Icons.account_balance_wallet_rounded,
          title: 'Ví Ameko',
          subtitle: walletBalance != null
              ? 'Số dư: ${formatter.format(walletBalance!.toInt())}đ'
              : 'Đang tải...',
          isSelected: selected == PaymentMethod.wallet,
        ),
        const SizedBox(height: 10),
        _buildOption(
          method: PaymentMethod.vnpay,
          icon: Icons.credit_card_rounded,
          title: 'VNPAY',
          subtitle: 'ATM, QR Code, Thẻ tín dụng',
          isSelected: selected == PaymentMethod.vnpay,
        ),
      ],
    );
  }

  Widget _buildOption({
    required PaymentMethod method,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.06)
            : Colors.white,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      child: InkWell(
        onTap: () => onChanged(method),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.12)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 2,
                  ),
                  color: isSelected ? AppColors.primary : Colors.transparent,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
