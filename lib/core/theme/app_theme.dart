import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        background: AppColors.background,
        surface: AppColors.card,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
        displayMedium: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
        displaySmall: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.bold),
        headlineMedium: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600),
        titleLarge: const TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w600),
        bodyLarge: const TextStyle(color: AppColors.textMain),
        bodyMedium: const TextStyle(color: AppColors.textMain),
        bodySmall: const TextStyle(color: AppColors.textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textMain,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  // Fallback to lightTheme since dark mode is strictly prohibited
  static ThemeData get darkTheme => lightTheme;
}
