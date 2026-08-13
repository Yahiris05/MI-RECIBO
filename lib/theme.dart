import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryNavy = Color(0xFF051B3B);
  static const Color primaryNavyLight = Color(0xFF143059);
  static const Color primaryNavyDark = Color(0xFF020D1D);
  static const Color accentOrange = Color(0xFFFF6A00);
  static const Color accentOrangeHover = Color(0xFFFF5500);
  static const Color accentOrangeLight = Color(0xFFFFEFE5);
  static const Color bgLanding = Color(0xFFF7F9FC);
  static const Color bgCard = Colors.white;
  static const Color bgApp = Color(0xFFF5F7FA);
  static const Color bgInput = Color(0xFFF4F6F9);
  static const Color textDark = Color(0xFF051B3B);
  static const Color textMuted = Color(0xFF738290);
  static const Color textLight = Colors.white;

  static const Color statusImportantBg = Color(0xFFFFEFE5);
  static const Color statusImportantText = Color(0xFFFF6A00);
  static const Color statusNormalBg = Color(0xFFE5F1FF);
  static const Color statusNormalText = Color(0xFF2E6FF2);
  static const Color statusSuccessBg = Color(0xFFE5F9EB);
  static const Color statusSuccessText = Color(0xFF1B8A3F);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryNavy,
        primary: AppColors.primaryNavy,
        secondary: AppColors.accentOrange,
        background: AppColors.bgApp,
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: AppColors.bgApp,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryNavy,
        brightness: Brightness.dark,
        primary: AppColors.primaryNavyLight,
        secondary: AppColors.accentOrange,
        background: const Color(0xFF0F172A),
      ),
      fontFamily: 'Inter',
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
