import 'package:flutter/material.dart';

class AppColors {
  // Text Colors
  static const Color text50 = Color(0xFFEDFDE7);
  static const Color text100 = Color(0xFFDBFBD0);
  static const Color text200 = Color(0xFFB6F7A1);
  static const Color text300 = Color(0xFF92F471);
  static const Color text400 = Color(0xFF6EF042);
  static const Color text500 = Color(0xFF49EC13);
  static const Color text600 = Color(0xFF3BBD0F);
  static const Color text700 = Color(0xFF2C8E0B);
  static const Color text800 = Color(0xFF1D5E08);
  static const Color text900 = Color(0xFF0F2F04);
  static const Color text950 = Color(0xFF071802);

  // Background Colors
  static const Color background50 = Color(0xFFECFDE7);
  static const Color background100 = Color(0xFFDAFCCF);
  static const Color background200 = Color(0xFFB4F8A0);
  static const Color background300 = Color(0xFF8FF570);
  static const Color background400 = Color(0xFF6AF240);
  static const Color background500 = Color(0xFF44EE11);
  static const Color background600 = Color(0xFF37BF0D);
  static const Color background700 = Color(0xFF298F0A);
  static const Color background800 = Color(0xFF1B5F07);
  static const Color background900 = Color(0xFF0E3003);
  static const Color background950 = Color(0xFF071802);

  // Primary Colors
  static const Color primary50 = Color(0xFFEEFDE7);
  static const Color primary100 = Color(0xFFDDFCCF);
  static const Color primary200 = Color(0xFFBCF8A0);
  static const Color primary300 = Color(0xFF9AF570);
  static const Color primary400 = Color(0xFF78F240);
  static const Color primary500 = Color(0xFF57EE11);
  static const Color primary600 = Color(0xFF45BF0D);
  static const Color primary700 = Color(0xFF348F0A);
  static const Color primary800 = Color(0xFF235F07);
  static const Color primary900 = Color(0xFF113003);
  static const Color primary950 = Color(0xFF091802);

  // Secondary Colors
  static const Color secondary50 = Color(0xFFE7FDF5);
  static const Color secondary100 = Color(0xFFD0FBEB);
  static const Color secondary200 = Color(0xFFA0F8D8);
  static const Color secondary300 = Color(0xFF71F4C4);
  static const Color secondary400 = Color(0xFF41F1B0);
  static const Color secondary500 = Color(0xFF12ED9D);
  static const Color secondary600 = Color(0xFF0EBE7D);
  static const Color secondary700 = Color(0xFF0B8E5E);
  static const Color secondary800 = Color(0xFF075F3F);
  static const Color secondary900 = Color(0xFF042F1F);
  static const Color secondary950 = Color(0xFF021810);

  // Accent Colors
  static const Color accent50 = Color(0xFFE7FDFD);
  static const Color accent100 = Color(0xFFCFFBFC);
  static const Color accent200 = Color(0xFFA0F7F8);
  static const Color accent300 = Color(0xFF70F3F5);
  static const Color accent400 = Color(0xFF40EFF2);
  static const Color accent500 = Color(0xFF11EBEE);
  static const Color accent600 = Color(0xFF0DBCBF);
  static const Color accent700 = Color(0xFF0A8D8F);
  static const Color accent800 = Color(0xFF075E5F);
  static const Color accent900 = Color(0xFF032F30);
  static const Color accent950 = Color(0xFF021718);

  // Convenience properties for common usage
  static Color get primary => primary500;
  static Color get secondary => secondary500;
  static Color get accent => accent500;
  
  // Background colors based on theme
  static Color get background => background50;
  static Color get surface => background50;
  static Color get surfaceDark => background950;
  
  // Text colors based on theme
  static Color get textPrimary => text900;
  static Color get textSecondary => text700;
  static Color get textLight => text50;
  
  // Gradients
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [Color(0xFF78F240), Color(0xFF57EE11), Color(0xFF45BF0D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get secondaryGradient => const LinearGradient(
    colors: [Color(0xFF41F1B0), Color(0xFF12ED9D), Color(0xFF0EBE7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get accentGradient => const LinearGradient(
    colors: [Color(0xFF40EFF2), Color(0xFF11EBEE), Color(0xFF0DBCBF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Additional gradients with different directions
  static LinearGradient get primaryGradientDiagonal => LinearGradient(
    colors: [primary400, primary500, primary600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get secondaryGradientDiagonal => LinearGradient(
    colors: [secondary400, secondary500, secondary600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get accentGradientDiagonal => LinearGradient(
    colors: [accent400, accent500, accent600],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

// import 'package:flutter/material.dart';

// class AppColors {
//   // Text Colors
//   static const Color text50 = Color(0xFFEDFDE7);
//   static const Color text100 = Color(0xFFDBFBD0);
//   static const Color text200 = Color(0xFFB6F7A1);
//   static const Color text300 = Color(0xFF92F471);
//   static const Color text400 = Color(0xFF6EF042);
//   static const Color text500 = Color(0xFF49EC13);
//   static const Color text600 = Color(0xFF3BBD0F);
//   static const Color text700 = Color(0xFF2C8E0B);
//   static const Color text800 = Color(0xFF1D5E08);
//   static const Color text900 = Color(0xFF0F2F04);
//   static const Color text950 = Color(0xFF071802);

//   // Background Colors
//   static const Color background50 = Color(0xFFECFDE7);
//   static const Color background100 = Color(0xFFDAFCCF);
//   static const Color background200 = Color(0xFFB4F8A0);
//   static const Color background300 = Color(0xFF8FF570);
//   static const Color background400 = Color(0xFF6AF240);
//   static const Color background500 = Color(0xFF44EE11);
//   static const Color background600 = Color(0xFF37BF0D);
//   static const Color background700 = Color(0xFF298F0A);
//   static const Color background800 = Color(0xFF1B5F07);
//   static const Color background900 = Color(0xFF0E3003);
//   static const Color background950 = Color(0xFF071802);

//   // Primary Colors
//   static const Color primary50 = Color(0xFFEEFDE7);
//   static const Color primary100 = Color(0xFFDDFCCF);
//   static const Color primary200 = Color(0xFFBCF8A0);
//   static const Color primary300 = Color(0xFF9AF570);
//   static const Color primary400 = Color(0xFF78F240);
//   static const Color primary500 = Color(0xFF57EE11);
//   static const Color primary600 = Color(0xFF45BF0D);
//   static const Color primary700 = Color(0xFF348F0A);
//   static const Color primary800 = Color(0xFF235F07);
//   static const Color primary900 = Color(0xFF113003);
//   static const Color primary950 = Color(0xFF091802);

//   // Secondary Colors
//   static const Color secondary50 = Color(0xFFE7FDF5);
//   static const Color secondary100 = Color(0xFFD0FBEB);
//   static const Color secondary200 = Color(0xFFA0F8D8);
//   static const Color secondary300 = Color(0xFF71F4C4);
//   static const Color secondary400 = Color(0xFF41F1B0);
//   static const Color secondary500 = Color(0xFF12ED9D);
//   static const Color secondary600 = Color(0xFF0EBE7D);
//   static const Color secondary700 = Color(0xFF0B8E5E);
//   static const Color secondary800 = Color(0xFF075F3F);
//   static const Color secondary900 = Color(0xFF042F1F);
//   static const Color secondary950 = Color(0xFF021810);

//   // Accent Colors
//   static const Color accent50 = Color(0xFFE7FDFD);
//   static const Color accent100 = Color(0xFFCFFBFC);
//   static const Color accent200 = Color(0xFFA0F7F8);
//   static const Color accent300 = Color(0xFF70F3F5);
//   static const Color accent400 = Color(0xFF40EFF2);
//   static const Color accent500 = Color(0xFF11EBEE);
//   static const Color accent600 = Color(0xFF0DBCBF);
//   static const Color accent700 = Color(0xFF0A8D8F);
//   static const Color accent800 = Color(0xFF075E5F);
//   static const Color accent900 = Color(0xFF032F30);
//   static const Color accent950 = Color(0xFF021718);

//   // Convenience properties for common usage
//   static Color get primary => primary500;
//   static Color get secondary => secondary500;
//   static Color get accent => accent500;
  
//   // Background colors based on theme
//   static Color get background => background50;
//   static Color get surface => background50;
//   static Color get surfaceDark => background950;
  
//   // Text colors based on theme
//   static Color get textPrimary => text900;
//   static Color get textSecondary => text700;
//   static Color get textLight => text50;
  
//   // Gradients
//   static LinearGradient get primaryGradient => LinearGradient(
//     colors: [primary400, primary500, primary600],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
  
//   static LinearGradient get accentGradient => LinearGradient(
//     colors: [accent400, accent500, accent600],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
  
//   static LinearGradient get secondaryGradient => LinearGradient(
//     colors: [secondary400, secondary500, secondary600],
//     begin: Alignment.topLeft,
//     end: Alignment.bottomRight,
//   );
// }


// // import 'package:flutter/material.dart';

// // class AppColors {
// //   // Primary Colors
// //   static const Color primary = Color(0xFF6C63FF);
// //   static const Color primaryLight = Color(0xFF8B83FF);
// //   static const Color primaryDark = Color(0xFF4A43D1);
  
// //   // Secondary Colors
// //   static const Color secondary = Color(0xFFFF6584);
// //   static const Color secondaryLight = Color(0xFFFF8CA3);
// //   static const Color secondaryDark = Color(0xFFD14A66);
  
// //   // Neutral Colors
// //   static const Color background = Color(0xFFF5F5FA);
// //   static const Color surface = Color(0xFFFFFFFF);
// //   static const Color surfaceDark = Color(0xFF1A1A2E);
  
// //   // Text Colors
// //   static const Color textPrimary = Color(0xFF1A1A2E);
// //   static const Color textSecondary = Color(0xFF6B6B7A);
// //   static const Color textLight = Color(0xFFFFFFFF);
  
// //   // Gradients
// //   static const LinearGradient primaryGradient = LinearGradient(
// //     colors: [primary, primaryLight],
// //     begin: Alignment.topLeft,
// //     end: Alignment.bottomRight,
// //   );
  
// //   static const LinearGradient accentGradient = LinearGradient(
// //     colors: [secondary, secondaryLight],
// //     begin: Alignment.topLeft,
// //     end: Alignment.bottomRight,
// //   );
// // }