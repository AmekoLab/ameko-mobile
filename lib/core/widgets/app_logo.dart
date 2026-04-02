import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';

/// App logo rendered from SVG asset. Optionally shows app name below.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 80,
    this.showName = false,
    this.nameStyle,
  });

  final double size;
  final bool showName;
  final TextStyle? nameStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.1),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: SvgPicture.asset(
            'assets/svg/logo.svg',
            width: size * 0.8,
            height: size * 0.8,
            fit: BoxFit.contain,
          ),
        ),
        if (showName) ...[
          const SizedBox(height: 12),
          Text(
            'Ameko',
            style: nameStyle ?? AppTextStyles.appName,
          ),
        ],
      ],
    );
  }
}
