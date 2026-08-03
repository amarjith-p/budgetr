import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTokens {
  static const Color primary = Color(0xFF1E1E1E); 
  static const Color primaryLight = Color(0xFF4CAF50); 
  static const Color backgroundLight = Color(0xFFF9FAFB);
  
  // --- UPDATED NAVY DARK TOKENS ---
  static const Color backgroundDark = Color(0xFF0B1121); // Deepest Midnight Navy
  static const Color surfaceLight = Colors.white;
  static const Color surfaceDark = Color(0xFF131C35);    // Elevated Navy Surface
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
      seedColor: const Color(0xFF3B82F6), // Vibrant Electric Blue accent
      brightness: Brightness.dark,
      primary: const Color.fromARGB(255, 184, 184, 184), 
      surface: AppTokens.surfaceDark,
      onSurface: AppTokens.textDark,
      surfaceContainerHighest: const Color(0xFF1E294B), // Highest Navy for inputs/highlights
      onSurfaceVariant: const Color(0xFF94A3B8), // Soft slate secondary text
      error: const Color(0xFFEF4444),
      outline: const Color(0xFF2A3655), // Soft Navy Border
    ),
    dividerColor: const Color(0xFF2A3655),
    textTheme: _buildTextTheme(AppTokens.textDark),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: AppTokens.backgroundDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
    ),
    
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppTokens.surfaceDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}