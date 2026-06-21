import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'color_palette.dart';
import 'typography.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary500,
      secondary: AppColors.secondary500,
      surface: AppColors.background50,
      background: AppColors.background50,
      onPrimary: AppColors.text950,
      onSecondary: AppColors.text950,
      onSurface: AppColors.text900,
      onBackground: AppColors.text900,
      primaryContainer: AppColors.primary100,
      secondaryContainer: AppColors.secondary100,
      tertiary: AppColors.accent500,
      tertiaryContainer: AppColors.accent100,
    ),
    scaffoldBackgroundColor: AppColors.background50,
    fontFamily: GoogleFonts.inter().fontFamily,
    
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.text900),
      titleTextStyle: AppTypography.titleLarge.copyWith(
        color: AppColors.text900,
      ),
    ),
    
    textTheme: TextTheme(
      displayLarge: AppTypography.headlineLarge.copyWith(color: AppColors.text900),
      displayMedium: AppTypography.headlineMedium.copyWith(color: AppColors.text900),
      displaySmall: AppTypography.headlineSmall.copyWith(color: AppColors.text900),
      headlineMedium: AppTypography.titleLarge.copyWith(color: AppColors.text900),
      headlineSmall: AppTypography.titleMedium.copyWith(color: AppColors.text800),
      titleLarge: AppTypography.titleSmall.copyWith(color: AppColors.text900),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.text800),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.text700),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.text600),
      labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.text900),
      labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.text700),
      labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.text600),
    ),
    
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      color: AppColors.background50,
      surfaceTintColor: AppColors.primary100,
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        foregroundColor: AppColors.text950,
        backgroundColor: AppColors.primary500,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary600,
        side: BorderSide(color: AppColors.primary300),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    iconTheme: IconThemeData(
      color: AppColors.text800,
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary500,
      secondary: AppColors.secondary500,
      surface: AppColors.background950,
      background: AppColors.background950,
      onPrimary: AppColors.text50,
      onSecondary: AppColors.text50,
      onSurface: AppColors.text50,
      onBackground: AppColors.text50,
      primaryContainer: AppColors.primary800,
      secondaryContainer: AppColors.secondary800,
      tertiary: AppColors.accent500,
      tertiaryContainer: AppColors.accent800,
    ),
    scaffoldBackgroundColor: AppColors.background950,
    fontFamily: GoogleFonts.inter().fontFamily,
    
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: Colors.transparent,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.text50),
      titleTextStyle: AppTypography.titleLarge.copyWith(
        color: AppColors.text50,
      ),
    ),
    
    textTheme: TextTheme(
      displayLarge: AppTypography.headlineLarge.copyWith(color: AppColors.text50),
      displayMedium: AppTypography.headlineMedium.copyWith(color: AppColors.text50),
      displaySmall: AppTypography.headlineSmall.copyWith(color: AppColors.text50),
      headlineMedium: AppTypography.titleLarge.copyWith(color: AppColors.text50),
      headlineSmall: AppTypography.titleMedium.copyWith(color: AppColors.text100),
      titleLarge: AppTypography.titleSmall.copyWith(color: AppColors.text50),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.text100),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.text200),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.text300),
      labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.text50),
      labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.text200),
      labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.text300),
    ),
    
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      color: AppColors.background900,
      surfaceTintColor: AppColors.primary800,
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 2,
        foregroundColor: AppColors.text50,
        backgroundColor: AppColors.primary600,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary400,
        side: BorderSide(color: AppColors.primary700),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    iconTheme: IconThemeData(
      color: AppColors.text100,
    ),
  );
}

// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'color_palette.dart';
// import 'typography.dart';

// class AppTheme {
//   static ThemeData lightTheme = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.light,
//     colorScheme: const ColorScheme.light(
//       primary: AppColors.primary,
//       secondary: AppColors.secondary,
//       surface: AppColors.surface,
//       background: AppColors.background,
//       onPrimary: Colors.white,
//       onSecondary: Colors.white,
//       onSurface: AppColors.textPrimary,
//       onBackground: AppColors.textPrimary,
//     ),
//     scaffoldBackgroundColor: AppColors.background,
//     fontFamily: GoogleFonts.inter().fontFamily,
    
//     appBarTheme: AppBarTheme(
//       elevation: 0,
//       backgroundColor: Colors.transparent,
//       centerTitle: true,
//       iconTheme: IconThemeData(color: AppColors.textPrimary),
//       titleTextStyle: AppTypography.titleLarge,
//     ),
    
//     textTheme: TextTheme(
//       displayLarge: AppTypography.headlineLarge,
//       displayMedium: AppTypography.headlineMedium,
//       displaySmall: AppTypography.headlineSmall,
//       headlineMedium: AppTypography.titleLarge,
//       headlineSmall: AppTypography.titleMedium,
//       titleLarge: AppTypography.titleSmall,
//       bodyLarge: AppTypography.bodyLarge,
//       bodyMedium: AppTypography.bodyMedium,
//       bodySmall: AppTypography.bodySmall,
//       labelLarge: AppTypography.labelLarge,
//       labelMedium: AppTypography.labelMedium,
//       labelSmall: AppTypography.labelSmall,
//     ),
    
//     cardTheme: CardThemeData(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       clipBehavior: Clip.antiAlias,
//     ),
    
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         elevation: 2,
//         padding: const EdgeInsets.symmetric(
//           horizontal: 24,
//           vertical: 12,
//         ),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     ),
    
//     iconTheme: const IconThemeData(
//       color: AppColors.textPrimary,
//     ),
//   );
  
//   static ThemeData darkTheme = ThemeData(
//     useMaterial3: true,
//     brightness: Brightness.dark,
//     colorScheme: const ColorScheme.dark(
//       primary: AppColors.primary,
//       secondary: AppColors.secondary,
//       surface: AppColors.surfaceDark,
//       background: Color(0xFF0F0F1A),
//       onPrimary: Colors.white,
//       onSecondary: Colors.white,
//       onSurface: Colors.white,
//       onBackground: Colors.white,
//     ),
//     scaffoldBackgroundColor: const Color(0xFF0F0F1A),
//     fontFamily: GoogleFonts.inter().fontFamily,
    
//     appBarTheme: AppBarTheme(
//       elevation: 0,
//       backgroundColor: Colors.transparent,
//       centerTitle: true,
//       iconTheme: IconThemeData(color: Colors.white),
//       titleTextStyle: AppTypography.titleLarge.copyWith(
//         color: Colors.white,
//       ),
//     ),
    
//     textTheme:  TextTheme(
//       displayLarge: AppTypography.headlineLarge.copyWith(color: Colors.white),
//       displayMedium: AppTypography.headlineMedium.copyWith(color: Colors.white),
//       displaySmall: AppTypography.headlineSmall.copyWith(color: Colors.white),
//       headlineMedium: AppTypography.titleLarge.copyWith(color: Colors.white),
//       headlineSmall: AppTypography.titleMedium.copyWith(color: Colors.white),
//       titleLarge: AppTypography.titleSmall.copyWith(color: Colors.white),
//       bodyLarge: AppTypography.bodyLarge.copyWith(color: Colors.white),
//       bodyMedium: AppTypography.bodyMedium.copyWith(color: Colors.white70),
//       bodySmall: AppTypography.bodySmall.copyWith(color: Colors.white60),
//       labelLarge: AppTypography.labelLarge.copyWith(color: Colors.white),
//       labelMedium: AppTypography.labelMedium.copyWith(color: Colors.white70),
//       labelSmall: AppTypography.labelSmall.copyWith(color: Colors.white60),
//     ),
    
//     cardTheme: CardThemeData(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16),
//       ),
//       clipBehavior: Clip.antiAlias,
//       color: const Color(0xFF1A1A2E),
//     ),
    
//     elevatedButtonTheme: ElevatedButtonThemeData(
//       style: ElevatedButton.styleFrom(
//         elevation: 2,
//         padding: const EdgeInsets.symmetric(
//           horizontal: 24,
//           vertical: 12,
//         ),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//         ),
//       ),
//     ),
    
//     iconTheme: const IconThemeData(
//       color: Colors.white,
//     ),
//   );
// }