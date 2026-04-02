import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:ameko_app/core/theme/app_colors.dart';
import 'package:ameko_app/core/theme/app_text_styles.dart';

/// Circular avatar that supports network images with fallback initials.
class AppAvatarCircle extends StatelessWidget {
  const AppAvatarCircle({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 24,
    this.borderColor,
    this.borderWidth = 0,
  });

  final String? imageUrl;
  final String? name;
  final double radius;
  final Color? borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatar = CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder: (context, provider) => CircleAvatar(
          radius: radius,
          backgroundImage: provider,
        ),
        placeholder: (_, __) => _buildInitials(),
        errorWidget: (_, __, ___) => _buildInitials(),
      );
    } else {
      avatar = _buildInitials();
    }

    if (borderWidth > 0) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? AppColors.primary,
            width: borderWidth,
          ),
        ),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildInitials() {
    final initials = _getInitials();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primarySurface,
      child: Text(
        initials,
        style: AppTextStyles.titleSmall.copyWith(
          color: AppColors.primary,
          fontSize: radius * 0.55,
        ),
      ),
    );
  }

  String _getInitials() {
    if (name == null || name!.trim().isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
