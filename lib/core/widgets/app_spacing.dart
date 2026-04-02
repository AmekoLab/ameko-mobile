import 'package:flutter/material.dart';

/// Spacing constants for consistent vertical/horizontal gaps throughout the app.
class AppSpacing {
  AppSpacing._();

  // Vertical spacing
  static const Widget v4 = SizedBox(height: 4);
  static const Widget v8 = SizedBox(height: 8);
  static const Widget v12 = SizedBox(height: 12);
  static const Widget v16 = SizedBox(height: 16);
  static const Widget v20 = SizedBox(height: 20);
  static const Widget v24 = SizedBox(height: 24);
  static const Widget v32 = SizedBox(height: 32);
  static const Widget v40 = SizedBox(height: 40);
  static const Widget v48 = SizedBox(height: 48);
  static const Widget v64 = SizedBox(height: 64);

  // Horizontal spacing
  static const Widget h4 = SizedBox(width: 4);
  static const Widget h8 = SizedBox(width: 8);
  static const Widget h12 = SizedBox(width: 12);
  static const Widget h16 = SizedBox(width: 16);
  static const Widget h24 = SizedBox(width: 24);
  static const Widget h32 = SizedBox(width: 32);

  // Padding constants
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
}
