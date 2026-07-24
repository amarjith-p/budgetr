import 'package:flutter/material.dart';

class AppTokens {
  static const Color primary = Color(0xFF1E1E1E); 
  static const Color primaryLight = Color(0xFF4CAF50); 
  static const Color backgroundLight = Color(0xFFF9FAFB);
  static const Color backgroundDark = Color(0xFF09090B);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF18181B);
  static const Color textLight = Color(0xFF121212);
  static const Color textDark = Color(0xFFF5F5F5);

  static const double bentoRadius = 8.0; 
  static const double padRadius = 8.0;
}

class AppTheme {
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      // Use Display styles for huge Hero amounts
      displayLarge: TextStyle(fontSize: 64, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -2),
      displayMedium: TextStyle(fontSize: 48, fontWeight: FontWeight.w400, color: textColor),
      // Use Headline styles for Page Headers
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -0.5),
      // Use Title styles for Cards
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -1),
      titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.0),
      // Use Label styles for tiny metadata/ALL CAPS headers
      labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: textColor, letterSpacing: 1.0),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.5),
      // Standard body
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textColor),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textColor.withOpacity(0.7)),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
    );
  }

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppTokens.backgroundLight,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTokens.primary,
      brightness: Brightness.light,
      primary: AppTokens.primary,
      surface: AppTokens.surfaceLight,
      onSurface: AppTokens.textLight,
      surfaceContainerHighest: const Color(0xFFE5E5EA), 
    ),
    dividerColor: Colors.black.withOpacity(0.1),
    textTheme: _buildTextTheme(AppTokens.textLight),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppTokens.backgroundDark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppTokens.primary,
      brightness: Brightness.dark,
      primary: Colors.white, 
      surface: AppTokens.surfaceDark,
      onSurface: AppTokens.textDark,
      surfaceContainerHighest: const Color(0xFF242424), 
    ),
    dividerColor: Colors.white.withOpacity(0.15),
    textTheme: _buildTextTheme(AppTokens.textDark),
  );
}