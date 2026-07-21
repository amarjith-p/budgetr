import 'package:flutter/material.dart';

class AppTokens {
  static const Color primary = Color(0xFF1E1E1E); // Swapping to a highly professional solid dark tone
  static const Color primaryLight = Color(0xFF4CAF50); // Minimal green for positive accents
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF09090B);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF18181B);
  
  static const Color textLight = Color(0xFF121212);
  static const Color textDark = Color(0xFFF5F5F5);

  // REDUCED: Creates a sharp, boxy, professional structure
  static const double bentoRadius = 8.0; 
  static const double padRadius = 8.0;
}

class AppTheme {
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textColor),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textColor.withOpacity(0.7)),
    );
  }

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppTokens.backgroundLight,
    // Explicitly mapping your custom tokens to the ColorScheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTokens.primary,
      brightness: Brightness.light,
      primary: AppTokens.primary,
      surface: AppTokens.surfaceLight,
      onSurface: AppTokens.textLight,
      surfaceContainerHighest: const Color(0xFFE5E5EA), // Soft grey for light mode bento blocks
    ),
    // Setting a crisp, professional divider color for your Boxy inputs
    dividerColor: Colors.black.withOpacity(0.1),
    textTheme: _buildTextTheme(AppTokens.textLight),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppTokens.backgroundDark,
    // Explicitly mapping your custom tokens to the ColorScheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTokens.primary,
      brightness: Brightness.dark,
      primary: Colors.white, // High contrast primary for dark mode
      surface: AppTokens.surfaceDark,
      onSurface: AppTokens.textDark,
      surfaceContainerHighest: const Color(0xFF242424), // Elevated grey for dark mode bento blocks
    ),
    // Setting a crisp, professional divider color for your Boxy inputs
    dividerColor: Colors.white.withOpacity(0.15),
    textTheme: _buildTextTheme(AppTokens.textDark),
  );
}