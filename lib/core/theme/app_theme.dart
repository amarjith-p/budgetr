import 'package:flutter/material.dart';
import '../design/budgetr_colors.dart';
import '../design/budgetr_styles.dart';

class AppTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: BudgetrColors.background,
    useMaterial3: true,

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: BudgetrColors.accent,
      secondary: BudgetrColors.secondary,
      surface: BudgetrColors.cardSurface,
      error: BudgetrColors.error,
      brightness: Brightness.dark,
    ),

    // AppBar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: BudgetrColors.background,
      elevation: 0,
      centerTitle: true,
      shape: Border(
        bottom: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      titleTextStyle: BudgetrStyles.h2,
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      elevation: 0,
      color: BudgetrColors.cardSurface.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BudgetrStyles.radiusM,
        side: BudgetrStyles.glassBorder.top, // using the border side from style
      ),
    ),

    // Bottom Sheet Theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: BudgetrColors.background,
      modalBackgroundColor: BudgetrColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
  );
}
