import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_palette.dart';
import 'typography.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      background: AppColors.background,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
      onBackground: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: GoogleFonts.inter().fontFamily,
    
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: AppTypography.titleLarge,
    ),
    
    textTheme: TextTheme(
      displayLarge: AppTypography.headlineLarge,
      displayMedium: AppTypography.headlineMedium,
      displaySmall: AppTypography.headlineSmall,
      headlineMedium: AppTypography.titleLarge,
      headlineSmall: AppTypography.titleMedium,
      titleLarge: AppTypography.titleSmall,
      bodyLarge: AppTypography.bodyLarge,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelLarge: AppTypography.labelLarge,
      labelMedium: AppTypography.labelMedium,
      labelSmall: AppTypography.labelSmall,
    ),
    
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    iconTheme: const IconThemeData(
      color: AppColors.textPrimary,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surfaceDark,
      background: Color(0xFF0F0F1A),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.white,
      onBackground: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0F1A),
    fontFamily: GoogleFonts.inter().fontFamily,
    
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: AppTypography.titleLarge.copyWith(
        color: Colors.white,
      ),
    ),
    
    textTheme:  TextTheme(
      displayLarge: AppTypography.headlineLarge.copyWith(color: Colors.white),
      displayMedium: AppTypography.headlineMedium.copyWith(color: Colors.white),
      displaySmall: AppTypography.headlineSmall.copyWith(color: Colors.white),
      headlineMedium: AppTypography.titleLarge.copyWith(color: Colors.white),
      headlineSmall: AppTypography.titleMedium.copyWith(color: Colors.white),
      titleLarge: AppTypography.titleSmall.copyWith(color: Colors.white),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: Colors.white),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: Colors.white70),
      bodySmall: AppTypography.bodySmall.copyWith(color: Colors.white60),
      labelLarge: AppTypography.labelLarge.copyWith(color: Colors.white),
      labelMedium: AppTypography.labelMedium.copyWith(color: Colors.white70),
      labelSmall: AppTypography.labelSmall.copyWith(color: Colors.white60),
    ),
    
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF1A1A2E),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    iconTheme: const IconThemeData(
      color: Colors.white,
    ),
  );
}