import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette (الكحلي الداكن والأزرق الملكي المستوحى من التصميم)
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color primaryBlue = Color(0xFF2563EB);

  // Background & Surface
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(
    0xFFFFFFFF,
  ); // تم تصحيحها هنا بإضافة 0xFF

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textLight = Color(0xFF94A3B8);

  // Status & Accents
  static const Color warningOrange = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color successGreen = Color(0xFF16A34A);

  // Seat States (حالات المقاعد في الشاشة التفاعلية)
  static const Color seatSelected = Color(0xFF2563EB);
  static const Color seatAvailable = Color(0xFFE2E8F0);
  static const Color seatLocked = Color(0xFF94A3B8);

  static const Color error = Color(0xFFDC2626);
}
