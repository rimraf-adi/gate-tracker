import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Dark theme
  static const darkBackground = Color(0xFF0C0C0C);
  static const darkSurface = Color(0xFF161616);
  static const darkerSurface = Color(0xFF080808);

  // Light theme
  static const lightBackground = Color(0xFFF5F3ED);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFF0EDE4);

  // Fixed accent — Mauve
  static const accent = Color(0xFF8B7A8B);
  static const accentLight = Color(0xFFB0A0B0);

  // Text (dark theme)
  static const textDarkPrimary = Color(0xFFE8E6E1);
  static const textDarkSecondary = Color(0xFF9B978E);

  // Text (light theme)
  static const textLightPrimary = Color(0xFF1A1A1A);
  static const textLightSecondary = Color(0xFF6B6B6B);

  // Legacy aliases (replaced by theme-aware calls throughout the codebase)
  static const gold = Color(0xFFC9A96E);
  static const mauve = Color(0xFF8B7A8B);
  static const lavenderPurple = Color(0xFF8B7A8B);
  static const neonPurple = Color(0xFF8B7A8B);
  static const copper = Color(0xFFB8736D);
  static const neonOrange = Color(0xFFB8736D);
  static const neonLime = Color(0xFFC9A96E);
  static const limeGreen = Color(0xFFC9A96E);
  static const slate = Color(0xFF6B7D8D);
  static const cardWhite = Color(0xFF1E1E1E);
  static const lightGray = Color(0xFF2A2A2A);
  static const warmIvory = Color(0xFF161616);
  static const softLavender = Color(0xFF6B7D8D);
  static const textWhite = Color(0xFFE8E6E1);
  static const textGray = Color(0xFF9B978E);
  static const textDark = Color(0xFF0C0C0C);
}

class AppRadius {
  static const small = 12.0;
  static const card = 24.0;
  static const large = 32.0;
  static const pill = 999.0;
}

class AppTheme {
  static ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBackground,
    primaryColor: AppColors.accent,
    cardColor: AppColors.darkSurface,
    dividerColor: AppColors.darkerSurface,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      secondary: AppColors.accent,
      surface: AppColors.darkSurface,
      onSurface: AppColors.textDarkPrimary,
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.outfit(fontSize: 48, fontWeight: FontWeight.w700, height: 1.0, color: AppColors.textDarkPrimary),
      headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
      headlineMedium: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
      titleLarge: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textDarkPrimary),
      titleMedium: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDarkPrimary),
      bodyLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textDarkPrimary),
      bodyMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textDarkPrimary),
      bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textDarkSecondary),
    ),
  );
}
