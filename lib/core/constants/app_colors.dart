import 'package:flutter/material.dart';

/// Central Design Tokens for SmartVision AI: Futuristic Black & Violet Theme
class AppColors {
  // Primary Surfaces & Backgrounds
  static const Color primaryBackground = Color(0xFF08070D);
  static const Color secondaryBackground = Color(0xFF100D18);
  static const Color cardBackground = Color(0xFF171221);
  static const Color elevatedSurface = Color(0xFF21182F);

  // Violets & Accents
  static const Color primaryViolet = Color(0xFF8B5CF6);
  static const Color brightViolet = Color(0xFFA78BFA);
  static const Color deepViolet = Color(0xFF6D28D9);
  static const Color neonAccent = Color(0xFFC084FC);

  // Typography
  static const Color primaryText = Color(0xFFF8F7FC);
  static const Color secondaryText = Color(0xFFAAA4B8);
  static const Color mutedText = Color(0xFF777083);

  // Status & Semantics
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFFB7185);

  // Borders & Dividers (subtle violet-gray with low opacity)
  static const Color border = Color(0x268B5CF6); // 15% opacity violet
  static const Color borderSubtle = Color(0x14FFFFFF); // 8% opacity white
  static const Color borderStrong = Color(0x408B5CF6); // 25% opacity violet

  // Backwards-compatible aliases
  static const Color primary = primaryViolet;
  static const Color secondary = brightViolet;
  static const Color aiFeature = neonAccent;
  static const Color background = primaryBackground;
  static const Color card = cardBackground;
  static const Color textMain = primaryText;
  static const Color textSecondary = secondaryText;

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryViolet, deepViolet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF191325), Color(0xFF130E1D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF2A1B4E), Color(0xFF171224)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonGlowGradient = LinearGradient(
    colors: [Color(0x33C084FC), Color(0x056D28D9)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
