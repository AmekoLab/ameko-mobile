import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // --- BỘ MÀU LIGHT RETAIL THEME (CHUẨN AMAZON) ---
  static const Color amazonBg = Color(0xFFFFFFFF);
  static const Color amazonBgSecondary = Color(0xFFF9F9FA);
  static const Color amazonHeader = Color(0xFF131A22);
  static const Color amazonHeaderLight = Color(0xFF232F3E);
  static const Color amazonText = Color(0xFF0F1111);
  static const Color amazonTextMuted = Color(0xFF565959);
  static const Color amazonLink = Color(0xFF2162A1);
  static const Color amazonPrice = Color(0xFFB12704);
  static const Color amazonBtnPrimary = Color(0xFFFFD814);
  static const Color amazonBtnSecondary = Color(0xFFFFA41C);
  static const Color amazonBorder = Color(0xFFD5D9D9);
  static const Color amazonFocus = Color(0xFFE77600);
  static const Color amazonHover = Color(0xFF0C3353);

  // Giữ lại brand cũ tạm thời để các trang chưa sửa không bị lỗi (theo snippet)
  static const Color brandBg = Color(0xFF0F0F10);
  static const Color brandText = Color(0xFFFFFFFF);
  static const Color brandAccent = Color(0xFFE31E24);

  // Mapping core tokens to newer Amazon-based colors
  static const Color primary = amazonHeader;
  static const Color primaryDark = Color(0xFF0D1219); 
  static const Color primaryLight = amazonHeaderLight;
  static const Color primarySurface = Color(0xFFF3F4F6);

  static const Color secondary = amazonBtnSecondary;
  static const Color secondaryDark = Color(0xFFE69100);
  static const Color secondaryLight = Color(0xFFFFBF5A);
  static const Color secondarySurface = Color(0xFFFFF7E6);

  // Background & Surface
  static const Color background = amazonBg;
  static const Color surface = amazonBg;
  static const Color surfaceVariant = amazonBgSecondary;

  // Text
  static const Color textPrimary = amazonText;
  static const Color textSecondary = amazonTextMuted;
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on dark blue primary
  static const Color textOnButton = Color(0xFF0F1111); // Dark text on yellow button

  // Status
  static const Color error = amazonPrice;
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color info = amazonLink;

  // Border & Divider
  static const Color border = amazonBorder;
  static const Color divider = Color(0xFFD5D9D9);

  // Message bubbles (Keep received as white, maybe sent as header color or primary)
  static const Color bubbleSent = amazonBtnPrimary;
  static const Color bubbleReceived = Color(0xFFF3F4F6);

  // Overlay
  static const Color overlay = Color(0x80000000);
}

