import 'package:flutter/material.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';

/// Styled divider with optional centered label.
class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.label,
    this.color,
    this.thickness = 1,
    this.margin = const EdgeInsets.symmetric(vertical: 8),
  });

  final String? label;
  final Color? color;
  final double thickness;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final dividerColor = color ?? AppColors.border;

    if (label != null) {
      return Padding(
        padding: margin,
        child: Row(
          children: [
            Expanded(
              child: Divider(
                color: dividerColor,
                thickness: thickness,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label!,
                style: AppTextStyles.caption,
              ),
            ),
            Expanded(
              child: Divider(
                color: dividerColor,
                thickness: thickness,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: margin,
      child: Divider(
        color: dividerColor,
        thickness: thickness,
        height: thickness,
      ),
    );
  }
}
