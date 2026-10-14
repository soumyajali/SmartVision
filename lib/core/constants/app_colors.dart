import 'package:flutter/material.dart';

/// Central Design Tokens for SmartVision AI: Futuristic Black & Violet Theme
class AppColors {
  // Primary Surfaces & Backgrounds
  static const Color primaryBackground = Color(0xFF070B16);
  static const Color secondaryBackground = Color(0xFF0B1424);
  static const Color cardBackground = Color(0xFF111D31);
  static const Color elevatedSurface = Color(0xFF192943);

  // Violets & Accents
  static const Color primaryViolet = Color(0xFF6574E8);
  static const Color brightViolet = Color(0xFF8795FF);
  static const Color deepViolet = Color(0xFF4656C8);
  static const Color neonAccent = Color(0xFF62D8F3);

  // Typography
  static const Color primaryText = Color(0xFFF8F7FC);
  static const Color secondaryText = Color(0xFFAAA4B8);
  static const Color mutedText = Color(0xFF777083);

  // Status & Semantics
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFFB7185);

  // Borders & Dividers (subtle violet-gray with low opacity)
  static const Color border = Color(0x334A6B9E);
  static const Color borderSubtle = Color(0x14FFFFFF); // 8% opacity white
  static const Color borderStrong = Color(0x664A6B9E);

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
    colors: [Color(0xFF14223A), Color(0xFF101A2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1D3153), Color(0xFF101A2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonGlowGradient = LinearGradient(
    colors: [Color(0x3362D8F3), Color(0x054656C8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
