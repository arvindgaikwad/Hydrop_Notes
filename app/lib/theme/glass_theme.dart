import 'package:flutter/material.dart';
import 'hydrop_theme.dart';

/// 💧 GLASS THEME — Fluid Glass
/// Vibrant gradients, frosted translucent glass panels, deep ocean sidebar.
class GlassTheme extends HydropTheme {
  // ---- Colors ----
  @override
  Color get background => const Color(0xFFF0F4F8); // Base mist
  @override
  Color get surface => const Color(0x33FFFFFF); // Translucent glass (20% white)
  @override
  Color get surfaceVariant => const Color(0x1AFFFFFF); // Frost tint (10% white)
  @override
  Color get sidebarBackground => const Color(0x1A000000); // Very light shadow for sidebar area
  @override
  Color get sidebarText => const Color(0xFFFFFFFF); // White text
  @override
  Color get sidebarTextSecondary => const Color(0xB3FFFFFF); // 70% White text
  @override
  Color get sidebarSelected => const Color(0xFF3498DB); // Vibrant ocean blue glow
  @override
  Color get primary => const Color(0xFF3498DB); // Vibrant ocean blue
  @override
  Color get primaryVariant => const Color(0xFF2980B9); // Deeper ocean
  @override
  Color get accent => const Color(0xFF9B59B6); // Amethyst accent for contrast
  @override
  Color get error => const Color(0xFFE74C3C);

  @override
  Color get textPrimary => const Color(0xFFFFFFFF); // White text for high contrast
  @override
  Color get textSecondary => const Color(0xCCFFFFFF); // 80% white text
  @override
  Color get textDisabled => const Color(0x66FFFFFF); // 40% white text

  @override
  Color get divider => const Color(0x33FFFFFF); // Translucent glass edge
  @override
  Color get cardBackground => const Color(0x4DFFFFFF); // 30% white
  @override
  Color get cardBorder => const Color(0x4DFFFFFF);
  @override
  Color get toolbarBackground => const Color(0x26FFFFFF); // 15% white

  @override
  Color get iconDefault => const Color(0xCCFFFFFF); // 80% white
  @override
  Color get iconActive => const Color(0xFF3498DB);

  // ---- Typography ----
  @override
  String get fontFamily => 'Inter';

  // ---- Radii (more rounded for fluid feel) ----
  @override
  double get radiusSm => 8.0;
  @override
  double get radiusMd => 12.0;
  @override
  double get radiusLg => 16.0;
  @override
  double get radiusXl => 24.0;

  // ---- Borders (subtle glass edges) ----
  @override
  BorderSide get borderThin =>
      BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 1.0);
  @override
  BorderSide get borderMedium =>
      BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.0);
  @override
  Border get cardBorderStyle => Border.fromBorderSide(borderThin);

  // ---- Shadows (soft, diffuse, colored shadows) ----
  @override
  List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: const Color(0xFF3498DB).withValues(alpha: 0.1),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  @override
  List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: const Color(0xFF3498DB).withValues(alpha: 0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
  @override
  List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: const Color(0xFF3498DB).withValues(alpha: 0.2),
      blurRadius: 40,
      offset: const Offset(0, 12),
    ),
  ];

  // ---- Surface Decorators ----
  @override
  BoxDecoration get raisedSurface => BoxDecoration(
    color: toolbarBackground,
    borderRadius: BorderRadius.circular(radiusXl),
    boxShadow: shadowMedium,
    border: Border.fromBorderSide(borderThin),
  );

  @override
  BoxDecoration get buttonDefault => BoxDecoration(
    color: primary,
    borderRadius: BorderRadius.circular(radiusXl),
    boxShadow: shadowSmall,
  );

  @override
  BoxDecoration get buttonPressed => BoxDecoration(
    color: primaryVariant,
    borderRadius: BorderRadius.circular(radiusXl),
  );

  @override
  BoxDecoration get insetSurface => BoxDecoration(
    color: surfaceVariant,
    borderRadius: BorderRadius.circular(radiusLg),
    border: Border.fromBorderSide(borderThin),
  );

  @override
  BoxDecoration get toolbarDecoration => BoxDecoration(
    color: toolbarBackground,
    borderRadius: BorderRadius.circular(radiusXl),
    boxShadow: shadowMedium,
    border: Border.fromBorderSide(borderThin),
  );

  // ---- Frosted glass blur ----
  @override
  bool get useBackdropBlur => true;
  @override
  double get blurRadius => 30.0;

  // ---- New Fluid Glass Extensions ----
  @override
  BoxDecoration get appBackgroundDecoration => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF8ECAE6), // Light blue
        Color(0xFF219EBC), // Mid blue
        Color(0xFF023047), // Deep navy
      ],
    ),
  );

  @override
  Widget applyBackdrop(Widget child, {BorderRadius? borderRadius}) {
    // BackdropFilter is extremely heavy and causes rendering glitches
    // when nested inside AnimatedCrossFade/AnimatedContainer on Windows.
    // Instead of a true blur, we apply a translucent overlay to simulate glass.
    final hasRadius = borderRadius != null && borderRadius != BorderRadius.zero;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x33FFFFFF), // 20% white overlay to simulate glass
        borderRadius: borderRadius ?? BorderRadius.zero,
        border: Border.fromBorderSide(borderThin),
      ),
      // Only apply expensive ClipRRect if we actually have rounded corners
      child: hasRadius
          ? ClipRRect(
              borderRadius: borderRadius,
              child: child,
            )
          : child,
    );
  }
}
