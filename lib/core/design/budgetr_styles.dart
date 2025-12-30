// lib/core/design/budgetr_styles.dart
import 'package:flutter/material.dart';
import 'budgetr_colors.dart';

class BudgetrStyles {
  BudgetrStyles._();

  // --- Text Styles ---
  static const TextStyle h1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: BudgetrColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: BudgetrColors.textPrimary,
    letterSpacing: 0.25,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: BudgetrColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: BudgetrColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: BudgetrColors.textTertiary,
    letterSpacing: 1.0,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle inputNumber = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: BudgetrColors.textPrimary,
  );

  // --- Borders & Radius ---
  static final BorderRadius radiusS = BorderRadius.circular(8);
  static final BorderRadius radiusM = BorderRadius.circular(16);
  static final BorderRadius radiusL = BorderRadius.circular(24);
  static final BorderRadius radiusFull = BorderRadius.circular(999);

  static Border glassBorder = Border.all(
    color: Colors.white.withOpacity(0.1),
    width: 1,
  );

  // --- Shadows ---
  static List<BoxShadow> glowBoxShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.15),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];
}
