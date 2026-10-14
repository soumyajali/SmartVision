import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = GoogleFonts.interTextTheme(baseTextTheme).copyWith(
      displayLarge: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      displayMedium: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, letterSpacing: -0.5),
      displaySmall: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
      headlineMedium: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w700, letterSpacing: -0.2),
      headlineSmall: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600),
      titleLarge: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w500),
      titleSmall: const TextStyle(color: AppColors.secondaryText, fontWeight: FontWeight.w500),
      bodyLarge: const TextStyle(color: AppColors.primaryText, fontSize: 16),
      bodyMedium: const TextStyle(color: AppColors.primaryText, fontSize: 14),
      bodySmall: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
      labelLarge: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600),
      labelMedium: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
      labelSmall: const TextStyle(color: AppColors.mutedText, fontSize: 10),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.primaryBackground,
      canvasColor: AppColors.secondaryBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryViolet,
        onPrimary: Colors.white,
        secondary: AppColors.brightViolet,
        onSecondary: Colors.white,
        tertiary: AppColors.neonAccent,
        surface: AppColors.cardBackground,
        onSurface: AppColors.primaryText,
        error: AppColors.error,
        onError: Colors.white,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.secondaryBackground,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: AppColors.primaryText),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryViolet,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          side: const BorderSide(color: AppColors.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brightViolet,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.elevatedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.secondaryText),
        hintStyle: const TextStyle(color: AppColors.mutedText),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.secondaryBackground,
        selectedItemColor: AppColors.neonAccent,
        unselectedItemColor: AppColors.mutedText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.secondaryBackground,
        indicatorColor: const Color(0x338B5CF6),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: AppColors.neonAccent, fontSize: 11, fontWeight: FontWeight.bold);
          }
          return const TextStyle(color: AppColors.mutedText, fontSize: 11);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.neonAccent);
          }
          return const IconThemeData(color: AppColors.mutedText);
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primaryViolet,
        inactiveTrackColor: Color(0x338B5CF6),
        thumbColor: AppColors.neonAccent,
        overlayColor: Color(0x268B5CF6),
        trackHeight: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.cardBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: AppColors.secondaryText,
          fontSize: 14,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderSubtle,
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.elevatedSurface,
        contentTextStyle: TextStyle(color: AppColors.primaryText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }

  // Futuristic Black and Violet theme is default
  static ThemeData get lightTheme => darkTheme;
}
