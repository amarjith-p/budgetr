import 'package:flutter/material.dart';

/// Centralized Design Token System
/// Single source of truth for UI metrics, replacing inline hardcoded values.
class DesignTokens {
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;

  // Border Radii
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;

  // Component Shapes
  static final ShapeBorder bottomSheetShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
  );
  
  static final ShapeBorder cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radiusMd),
  );

  // Paddings
  static const EdgeInsets pagePadding = EdgeInsets.all(spacingMd);
  static const EdgeInsets bottomSheetPadding = EdgeInsets.all(spacingLg);
}