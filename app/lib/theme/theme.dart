import 'package:flutter/material.dart';

/// Design Tokens for Hydrop Notes (Neo-Skeuomorphic UI Kit)
/// This theme is designed to look like a tactile, wireframe blueprint
/// with paper backgrounds, crisp ink borders, and realistic soft shadows.
class AppTheme {
  // ---------------------------------------------------------------------------
  // 1. Color Palette (Monochromatic / Wireframe)
  // ---------------------------------------------------------------------------

  static const Color paperBackground = Color(
    0xFFF4F2EC,
  ); // Warm off-white paper
  static const Color ink = Color(
    0xFF2D2D2D,
  ); // Dark grey/black ink for text/borders
  static const Color insetBackground = Color(
    0xFFE8E4D9,
  ); // Slightly darker for inset areas

  // We keep a subtle accent for things like selections, but it should be muted
  static const Color accent = Color(0xFF6B7280); // Muted grey for selections
  static const Color primary = Color(0xFF2D2D2D); // Primary is just ink
  static const Color error = Color(0xFFEF4444); // Red for destructive actions

  // Legacy mappings for compatibility (will be phased out)
  static const Color background = paperBackground;
  static const Color surface = paperBackground;
  static const Color gridLine = Color(
    0xFFDCD8CE,
  ); // Slightly darker than paper for grids
  static const Color textPrimary = ink;
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF94A3B8);

  // ---------------------------------------------------------------------------
  // 2. Spatial Scale (8pt Grid System)
  // ---------------------------------------------------------------------------
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space48 = 48.0;

  // ---------------------------------------------------------------------------
  // 3. Typography (Base scale)
  // ---------------------------------------------------------------------------
  static const FontWeight fontRegular = FontWeight.w400;
  static const FontWeight fontMedium = FontWeight.w500;
  static const FontWeight fontBold = FontWeight.w700;

  // ---------------------------------------------------------------------------
  // 4. Borders & Radii (Neo-Skeuo Rules)
  // ---------------------------------------------------------------------------
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 20.0;

  static const BorderSide borderSide1px = BorderSide(color: ink, width: 1.0);
  static const BorderSide borderSide2px = BorderSide(color: ink, width: 2.0);
  static const BorderSide borderSide4px = BorderSide(color: ink, width: 4.0);

  static const Border border1px = Border.fromBorderSide(borderSide1px);
  static const Border border2px = Border.fromBorderSide(borderSide2px);
  static const Border border4px = Border.fromBorderSide(borderSide4px);

  // ---------------------------------------------------------------------------
  // 4. Elevation Levels (Shadows)
  // ---------------------------------------------------------------------------
  static List<BoxShadow> level1Shadow = [
    BoxShadow(
      color: ink.withValues(alpha: 0.15),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> level2Shadow = [
    BoxShadow(
      color: ink.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> level3Shadow = [
    BoxShadow(
      color: ink.withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // ---------------------------------------------------------------------------
  // 5. Surface Decorators (Tactile States)
  // ---------------------------------------------------------------------------

  /// Base unpressed surface (e.g. toolbars, floating panels)
  static BoxDecoration get raisedSurface => BoxDecoration(
    color: paperBackground,
    border: border2px,
    borderRadius: BorderRadius.circular(radiusXl),
    boxShadow: level2Shadow,
  );

  /// Default button state
  static BoxDecoration get buttonDefault => BoxDecoration(
    color: paperBackground,
    border: border2px,
    borderRadius: BorderRadius.circular(radiusLg),
    boxShadow: level1Shadow,
  );

  /// Pressed button state (tactile inset)
  static BoxDecoration get buttonPressed => BoxDecoration(
    color: insetBackground,
    border: border2px,
    borderRadius: BorderRadius.circular(radiusLg),
    // Removed drop shadow to simulate pushing down into the paper
  );

  /// Inset panels (like minimap or text fields)
  static BoxDecoration get insetSurface => BoxDecoration(
    color: insetBackground,
    border: border2px,
    borderRadius: BorderRadius.circular(radiusLg),
    // Simulate inner shadow with an inner border or just relying on color contrast
    // Since native Flutter BoxDecoration doesn't support inner shadow easily,
    // the darker insetBackground + thick border creates the illusion.
  );
}
