import 'package:flutter/material.dart';

class AppColors {
  // Brand gradient colors
  static const Color brandStart = Color(0xFF0B4A3F); // Deep Emerald
  static const Color brandEnd = Color(0xFF143C52);   // Midnight Teal
  
  // Neutral Colors
  static const Color textPrimary = Color(0xFF2A2826);   // Soft charcoal ink
  static const Color textSecondary = Color(0xFF6B655F); // Secondary text
  static const Color background = Color(0xFFFAF7F2);    // Warm ivory
  static const Color cardSurface = Color(0xFFFFFFFF);   // Pure white
  static const Color cardSurfaceAlt = Color(0xFFFDFCFA);
  static const Color border = Color(0xFFE4DFD6);
  
  // Gold Accent (Used sparingly)
  static const Color goldAccent = Color(0xFFB8935A);
  
  // Status Colors (Flat solid colors, never gradients)
  static const Color statusCompleted = Color(0xFF3F6B4F);
  static const Color statusCompletedBg = Color(0xFFE8F0EA);
  static const Color statusCompletedText = Color(0xFF2A4835);
  
  static const Color statusDue = Color(0xFFB9793A);
  static const Color statusDueBg = Color(0xFFF7EDE0);
  static const Color statusDueText = Color(0xFF7A4E1E);
  
  static const Color statusMissed = Color(0xFF7A2B3A);
  static const Color statusMissedBg = Color(0xFFF5E6E9);
  static const Color statusMissedText = Color(0xFF5C1F2A);

  static const Color statusUpcoming = Color(0xFF6B655F);
  static const Color statusUpcomingBg = Color(0xFFF2EFEA);
  static const Color statusUpcomingText = Color(0xFF4A4540);

  static const Color statusUnconfirmed = Color(0xFFE4DFD6);
  static const Color statusUnconfirmedText = Color(0xFF6B655F);

  // Gradient helper
  static const Gradient brandGradient = LinearGradient(
    colors: [brandStart, brandEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient goldGradient = LinearGradient(
    colors: [Color(0xFFC9A468), Color(0xFF9C7A42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.brandStart,
        primary: AppColors.brandStart,
        secondary: AppColors.brandEnd,
        surface: AppColors.cardSurface,
        error: AppColors.statusMissed,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Outfit', // Uses fallback sans-serif if not downloaded
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
