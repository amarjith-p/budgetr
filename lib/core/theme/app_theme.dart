import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.deepVoid,
    fontFamily:
        'SF Pro Display', // Assuming you might use a custom font, otherwise system default

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.royalBlue,
      brightness: Brightness.dark,
      primary: AppColors.royalBlue,
      secondary: AppColors.tealGreen,
      surface: AppColors.deepVoid,
      error: AppColors.dangerRed,
    ),

    useMaterial3: true,

    // Global AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor:
          Colors.transparent, // Transparent by default for Glass effect
      elevation: 0,
      centerTitle: true,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        letterSpacing: 0.5,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),

    // Global Card Theme (Fallback for standard Cards)
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.glassFill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.glassBorder),
      ),
    ),

    // Text Button Theme (Used in your dialogs)
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.royalBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}
