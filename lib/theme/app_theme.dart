import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary Palette - Deep Emerald & Mint Gold
  static const Color primary = Color(0xFF1E4D3B);
  static const Color primaryLight = Color(0xFF2E6F56);
  static const Color primaryAccent = Color(0xFF10B981); // Vibrant mint green accent
  static const Color accentWarning = Color(0xFFF59E0B); // Amber warning
  static const Color danger = Color(0xFFEF4444); // Coral Red
  static const Color info = Color(0xFF3B82F6); // Electric Blue

  // Light Theme Surfaces (Warm Studio Tone)
  static const Color background = Color(0xFFF8F7F4);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF2EFE9);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E2D9);
  static const Color borderSubtle = Color(0xFFF0EDE5);

  // Dark Theme Palette (Sleek Obsidian & Emerald Glass)
  static const Color primaryDark = Color(0xFF34D399);
  static const Color backgroundDark = Color(0xFF0F1412);
  static const Color surfaceCardDark = Color(0xFF181F1C);
  static const Color surfaceSecondaryDark = Color(0xFF222B27);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color borderDark = Color(0xFF27322D);
  static const Color borderSubtleDark = Color(0xFF1F2824);

  // Dynamic Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E4D3B), Color(0xFF113226)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradientLight = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAF7)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    colors: [Color(0xFF1E2622), Color(0xFF161C19)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroGradientDark = LinearGradient(
    colors: [Color(0xFF1A3D30), Color(0xFF0F261E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Fixed Category Palette
  static const Color catPetrol = Color(0xFFD97706);
  static const Color catKhana = Color(0xFF10B981);
  static const Color catRent = Color(0xFF3B82F6);
  static const Color catSim = Color(0xFF8B5CF6);
  static const Color catBike = Color(0xFFEC4899);

  static const List<Color> customRotator = [
    Color(0xFF10B981),
    Color(0xFF06B6D4),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFFEC4899),
  ];

  static Color getCategoryColor(String name, String? hex) {
    if (hex != null && hex.isNotEmpty) {
      final value = int.tryParse(hex.replaceFirst('#', '0xFF'));
      if (value != null) return Color(value);
    }
    switch (name.toLowerCase().trim()) {
      case 'petrol':
      case 'fuel':
        return catPetrol;
      case 'khana':
      case 'food':
      case 'dining':
        return catKhana;
      case 'room rent':
      case 'rent':
      case 'housing':
        return catRent;
      case 'sim bill':
      case 'sim':
      case 'mobile':
        return catSim;
      case 'bike maintenance':
      case 'bike':
      case 'transport':
        return catBike;
      default:
        final code = name.codeUnits.fold(0, (prev, element) => prev + element);
        return customRotator[code % customRotator.length];
    }
  }
}

class AppShadows {
  static List<BoxShadow> get softLight => [
        BoxShadow(
          color: const Color(0xFF111827).withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF111827).withOpacity(0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get softDark => [
        BoxShadow(
          color: Colors.black.withOpacity(0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get heroGlow => [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.25),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryAccent,
        error: AppColors.danger,
        surface: AppColors.surfaceCard,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
          color: AppColors.textPrimary,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
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
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
        secondary: AppColors.primaryAccent,
        error: AppColors.danger,
        surface: AppColors.surfaceCardDark,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderDark,
        thickness: 1,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.0,
          color: AppColors.textPrimaryDark,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: AppColors.textPrimaryDark,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w700,
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
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: AppColors.textSecondaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceCardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
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
