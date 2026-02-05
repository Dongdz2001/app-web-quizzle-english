import 'package:flutter/material.dart';

/// Định nghĩa toàn bộ màu sắc dùng trong app
/// để tái sử dụng ở mọi component.
class AppColors {
  AppColors._();

  // Màu chính theo style pastel giống Canva
  static const Color primary = Color(0xFF6366F1); // Indigo mềm
  static const Color secondary = Color(0xFF22C55E); // Xanh lá tươi
  static const Color accent = Color(0xFFEC4899); // Hồng điểm nhấn

  // Màu nền
  static const Color scaffoldBackground = Color(0xFFF5F7FB);
  static const Color cardBackground = Colors.white;

  // Màu text cơ bản
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF4B5563);
}

