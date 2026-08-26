import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Custom Color System
  static const Color background = Color(0xFF0F1115); // Deep charcoal
  static const Color surface = Color(0x801A1D24); // Dark translucent gray
  static const Color primary = Color(0xFF00FFC2); // Vibrant AI accent (Cyan)
  static const Color success = Color(0xFF00E676); // Detection positive
  static const Color warning = Color(0xFFFFAB00); // Alert accent
  static const Color error = Color(0xFFFF3D00); // Critical alert
  static const Color textHighContrast = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9E9E9E);
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        background: background,
        error: error,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(fontSize: 40, fontWeight: FontWeight.bold, color: textHighContrast),
        displayMedium: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.bold, color: textHighContrast),
        headlineLarge: GoogleFonts.sora(fontSize: 28, fontWeight: FontWeight.w600, color: textHighContrast),
        headlineMedium: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w600, color: textHighContrast),
        bodyLarge: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.normal, color: textHighContrast),
        bodyMedium: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.normal, color: textHighContrast),
        labelSmall: GoogleFonts.sora(fontSize: 11, fontWeight: FontWeight.w500, color: textHighContrast),
      ),
    );
  }
}
