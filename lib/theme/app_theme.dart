import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Matte Formal Dark Backgrounds
  static const darkBackground = Color(0xFF0C0C0C);
  static const darkSurface = Color(0xFF161616);
  static const darkerSurface = Color(0xFF080808);

  // Matte Accents (muted, formal)
  static const gold = Color(0xFFC9A96E);
  static const mauve = Color(0xFF8B7A8B);
  static const copper = Color(0xFFB8736D);
  static const slate = Color(0xFF6B7D8D);

  // Legacy accent aliases (map to new matte palette)
  static const neonLime = Color(0xFFC9A96E);
  static const limeGreen = Color(0xFFC9A96E);
  static const neonPurple = Color(0xFF8B7A8B);
  static const lavenderPurple = Color(0xFF8B7A8B);
  static const neonOrange = Color(0xFFB8736D);

  // Surface colors (dark elevated surfaces)
  static const cardWhite = Color(0xFF1E1E1E);
  static const lightGray = Color(0xFF2A2A2A);

  // Gradient helpers
  static const warmIvory = Color(0xFF161616);
  static const softLavender = Color(0xFF6B7D8D);

  // Text Colors (warm, low-contrast)
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
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        primaryColor: AppColors.gold,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.mauve,
          surface: AppColors.darkSurface,
        ),
        textTheme: TextTheme(
          displayLarge: GoogleFonts.outfit(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            height: 1.0,
            color: AppColors.textWhite,
          ),
          headlineLarge: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: AppColors.textWhite,
          ),
          headlineMedium: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textWhite,
          ),
          titleLarge: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textWhite,
          ),
          titleMedium: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textWhite,
          ),
          bodyLarge: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppColors.textWhite,
          ),
          bodyMedium: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textWhite,
          ),
          bodySmall: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.textGray,
          ),
        ),
      );
}
