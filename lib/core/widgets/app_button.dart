import 'package:flutter/material.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';

enum AppButtonVariant { primary, secondary, outline, text }

/// Reusable button with loading state and variant support.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.width,
    this.height = 52,
    this.icon,
    this.enabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final double? width;
  final double height;
  final Widget? icon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && !isLoading && onPressed != null;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: switch (variant) {
        AppButtonVariant.primary => _buildElevatedButton(
            isEnabled,
            bgColor: AppColors.primary,
            fgColor: AppColors.textOnPrimary,
          ),
        AppButtonVariant.secondary => _buildElevatedButton(
            isEnabled,
            bgColor: AppColors.secondary,
            fgColor: AppColors.textOnPrimary,
          ),
        AppButtonVariant.outline => _buildOutlineButton(isEnabled),
        AppButtonVariant.text => _buildTextButton(isEnabled),
      },
    );
  }

  Widget _buildElevatedButton(
    bool isEnabled, {
    required Color bgColor,
    required Color fgColor,
  }) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? bgColor : AppColors.border,
        foregroundColor: fgColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: _buildChild(fgColor),
    );
  }

  Widget _buildOutlineButton(bool isEnabled) {
    return OutlinedButton(
      onPressed: isEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: _buildChild(AppColors.primary),
    );
  }

  Widget _buildTextButton(bool isEnabled) {
    return TextButton(
      onPressed: isEnabled ? onPressed : null,
      child: _buildChild(AppColors.primary),
    );
  }

  Widget _buildChild(Color loaderColor) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(loaderColor),
        ),
      );
    }
    if (icon != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(text, style: AppTextStyles.button),
        ],
      );
    }
    return Text(text, style: AppTextStyles.button);
  }
}
