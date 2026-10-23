import 'package:flutter/material.dart';

class DriverColors {
  static const Color primaryGreen = Color(0xFF0A8B42);
  static const Color primaryGreenDark = Color(0xFF065A2A);
  static const Color primaryGreenLight = Color(0xFFE8F5E9);

  static const Color warmYellow = Color(0xFFFFB703);
  static const Color warmYellowDark = Color(0xFFE5A500);

  static const Color deepNavy = Color(0xFF0B3C35);
  static const Color darkTeal = Color(0xFF082823);

  static const Color background = Color(0xFFF8FAF9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E8F0);

  static const Color onlineGreen = Color(0xFF10B981);
  static const Color offlineGray = Color(0xFF94A3B8);
  static const Color busyOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);

  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
}

class DriverTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: DriverColors.background,
      primaryColor: DriverColors.primaryGreen,
      colorScheme: const ColorScheme.light(
        primary: DriverColors.primaryGreen,
        secondary: DriverColors.warmYellow,
        surface: DriverColors.surface,
        background: DriverColors.background,
        error: DriverColors.errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: DriverColors.surface,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 1,
        iconTheme: IconThemeData(color: DriverColors.textMain),
        titleTextStyle: TextStyle(
          color: DriverColors.textMain,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DriverColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: CardTheme(
        color: DriverColors.surface,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DriverColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DriverColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DriverColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DriverColors.primaryGreen, width: 2),
        ),
      ),
    );
  }
}
