import 'package:flutter/material.dart';

/// Quy ước kích thước chữ & text style dùng chung.
class AppFontSizes {
  AppFontSizes._();

  static const double xs = 12;
  static const double sm = 14;
  static const double md = 16;
  static const double lg = 18;
  static const double xl = 20;
  static const double xxl = 24;
}

class AppTextStyles {
  AppTextStyles._();

  // Có thể thay đổi fontFamily sau nếu bạn add custom font
  static const String primaryFontFamily = 'Roboto';

  static TextTheme textTheme = const TextTheme(
    headlineLarge: TextStyle(
      fontSize: AppFontSizes.xxl,
      fontWeight: FontWeight.w700,
      fontFamily: primaryFontFamily,
    ),
    headlineMedium: TextStyle(
      fontSize: AppFontSizes.xl,
      fontWeight: FontWeight.w600,
      fontFamily: primaryFontFamily,
    ),
    headlineSmall: TextStyle(
      fontSize: AppFontSizes.lg,
      fontWeight: FontWeight.w600,
      fontFamily: primaryFontFamily,
    ),
    titleLarge: TextStyle(
      fontSize: AppFontSizes.md,
      fontWeight: FontWeight.w600,
      fontFamily: primaryFontFamily,
    ),
    bodyLarge: TextStyle(
      fontSize: AppFontSizes.md,
      fontWeight: FontWeight.w400,
      fontFamily: primaryFontFamily,
    ),
    bodyMedium: TextStyle(
      fontSize: AppFontSizes.sm,
      fontWeight: FontWeight.w400,
      fontFamily: primaryFontFamily,
    ),
    labelLarge: TextStyle(
      fontSize: AppFontSizes.sm,
      fontWeight: FontWeight.w600,
      fontFamily: primaryFontFamily,
    ),
  );
}

