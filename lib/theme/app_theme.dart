import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Theme Palette
  static const Color primary = Color(0xFF2D5F4C); // Deep forest green
  static const Color accentWarning = Color(0xFFC9822E); // Warm amber
  static const Color danger = Color(0xFFB33A3A); // Muted red
  static const Color background = Color(0xFFFAF8F3); // Warm off-white
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1F2420);
  static const Color textSecondary = Color(0xFF6B7268);
  static const Color border = Color(0xFFE8E4DA);

  // Dark Theme Palette
  static const Color primaryDark = Color(0xFF4A8B71);
  static const Color backgroundDark = Color(0xFF141715);
  static const Color surfaceCardDark = Color(0xFF1E2420);
  static const Color textPrimaryDark = Color(0xFFF1F3F0);
  static const Color textSecondaryDark = Color(0xFF9CA39A);
  static const Color borderDark = Color(0xFF2E3530);

  // Fixed Muted Category Palette
  static const Color catPetrol = Color(0xFFC9822E);
  static const Color catKhana = Color(0xFF6B8E5A);
  static const Color catRent = Color(0xFF5A7A9E);
  static const Color catSim = Color(0xFF9E7A5A);
  static const Color catBike = Color(0xFF8E5A7A);

  static const List<Color> customRotator = [
    Color(0xFF7A9E5A),
    Color(0xFF5A9E8E),
    Color(0xFF9E5A5A),
  ];

  static Color getCategoryColor(String name, String? hex) {
    if (hex != null && hex.isNotEmpty) {
      final value = int.tryParse(hex.replaceFirst('#', '0xFF'));
      if (value != null) return Color(value);
    }
    switch (name.toLowerCase().trim()) {
      case 'petrol':
        return catPetrol;
      case 'khana':
      case 'food':
        return catKhana;
      case 'room rent':
      case 'rent':
        return catRent;
      case 'sim bill':
      case 'sim':
        return catSim;
      case 'bike maintenance':
      case 'bike':
        return catBike;
      default:
        // Hash name to select color from rotator
        final code = name.codeUnits.fold(0, (prev, element) => prev + element);
        return customRotator[code % customRotator.length];
    }
  }
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accentWarning,
        error: AppColors.danger,
        surface: AppColors.surfaceCard,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryDark,
        secondary: AppColors.accentWarning,
        error: AppColors.danger,
        surface: AppColors.surfaceCardDark,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimaryDark,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textPrimaryDark,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textSecondaryDark,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
      ),
    );
  }
}
