import 'package:flutter/material.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';

enum SnackBarType { success, error, info, warning }

/// Static helpers to show styled SnackBars from anywhere.
class AppSnackBar {
  AppSnackBar._();

  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message: message, type: SnackBarType.success, duration: duration);
  }

  static void showError(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(context, message: message, type: SnackBarType.error, duration: duration);
  }

  static void showInfo(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message: message, type: SnackBarType.info, duration: duration);
  }

  static void showWarning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(context, message: message, type: SnackBarType.warning, duration: duration);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_iconForType(type), color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _colorForType(type),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static Color _colorForType(SnackBarType type) => switch (type) {
        SnackBarType.success => AppColors.success,
        SnackBarType.error => AppColors.error,
        SnackBarType.warning => AppColors.warning,
        SnackBarType.info => AppColors.info,
      };

  static IconData _iconForType(SnackBarType type) => switch (type) {
        SnackBarType.success => Icons.check_circle_outline,
        SnackBarType.error => Icons.error_outline,
        SnackBarType.warning => Icons.warning_amber_outlined,
        SnackBarType.info => Icons.info_outline,
      };
}
