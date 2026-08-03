import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF8B1A1A);
  static const primaryLight = Color(0xFF6B1414);
  static const primaryAccent = Color(0xFFF5C4B3);
  static const background = Color(0xFFfff5f5);
  static const surface = Color(0xFFFFFFFF);
  static const success = Color(0xFF1a7a3c);
  static const successLight = Color(0xFFe8f7ee);
  static const danger = Color(0xFFe74c3c);
  static const dangerLight = Color(0xFFfff3f3);
  static const border = Color(0xFFe8d5d5);
  static const textPrimary = Color(0xFF1a1a2e);
  static const textSecondary = Color(0xFF888888);
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}
