import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.deepVoid,
    fontFamily: 'SF Pro Display',

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.royalBlue,
      brightness: Brightness.dark,
      primary: AppColors.royalBlue,
      secondary: AppColors.tealGreen,
      surface: AppColors.deepVoid,
      onSurface: AppColors.textPrimary,
      error: AppColors.dangerRed,
    ),

    useMaterial3: true,

    // --- Global AppBar Theme ---
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false, // Changed to False for Left Alignment
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
        fontFamily: 'SF Pro Display',
        letterSpacing: 0.5,
      ),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),

    // --- Glass Card Theme ---
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.glassFill,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.glassBorder),
      ),
    ),

    // --- Inputs / TextFields ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.glassFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.royalBlue, width: 1.5),
      ),
    ),

    // --- Dialogs ---
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.deepVoid.withOpacity(0.95),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.glassBorder),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    ),
  );
}
