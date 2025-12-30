import 'package:flutter/material.dart';

class AppColors {
  // --- Backgrounds ---
  static const Color deepVoid = Color(0xff050505); // Main background
  static const Color darkCard = Color(0xff0D1B2A); // Fallback for opaque cards

  // --- Accents (Neon/Aurora) ---
  static const Color royalBlue = Color(0xFF4361EE);
  static const Color deepPurple = Color(0xFF7209B7);
  static const Color electricPink = Color(0xFFF72585);
  static const Color vibrantOrange = Color(0xFFFF9F1C);
  static const Color tealGreen = Color(0xFF2EC4B6);
  static const Color dangerRed = Color(0xFFE63946);
  static const Color successGreen = Color(0xFF00E676);

  // --- Semantic Colors (Stats & Indicators) ---
  // Added these to fix the "undefined getter" error
  static const Color negativeRed = Color(
    0xFFFF4D6D,
  ); // Brighter red for negative values
  static const Color positiveGreen = Color(
    0xFF00E676,
  ); // Alias for successGreen

  // --- Text Colors ---
  static const Color textPrimary = Colors.white;
  static Color textSecondary = Colors.white.withOpacity(0.7);
  static Color textTertiary = Colors.white.withOpacity(0.4);

  // --- Glassmorphism System ---
  static Color glassBorder = Colors.white.withOpacity(0.12);
  static Color glassFill = Colors.white.withOpacity(0.05);
  static Color glassFillActive = Colors.white.withOpacity(0.10);

  // --- Centralized Gradients ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [royalBlue, deepPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dangerGradient = LinearGradient(
    colors: [dangerRed, Color(0xFF990000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [tealGreen, successGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
