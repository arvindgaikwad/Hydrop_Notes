import 'package:flutter/material.dart';
import 'hydrop_theme.dart';

/// 🖋️ INK THEME — Neo-Skeuomorphic
/// Warm paper, thick ink borders, handcrafted journal feel.
class InkTheme extends HydropTheme {
  // ---- Colors ----
  @override
  Color get background => const Color(0xFFF4F2EC);
  @override
  Color get surface => const Color(0xFFF4F2EC);
  @override
  Color get surfaceVariant => const Color(0xFFE8E4D9);
  @override
  Color get sidebarBackground => const Color(0xFFF4F2EC);
  @override
  Color get sidebarText => const Color(0xFF2D2D2D);
  @override
  Color get sidebarTextSecondary => const Color(0xFF64748B);
  @override
  Color get sidebarSelected => const Color(0xFF2D2D2D);
  @override
  Color get primary => const Color(0xFF2D2D2D);
  @override
  Color get primaryVariant => const Color(0xFF1A1A1A);
  @override
  Color get accent => const Color(0xFF6B7280);
  @override
  Color get error => const Color(0xFFEF4444);
  @override
  Color get textPrimary => const Color(0xFF2D2D2D);
  @override
  Color get textSecondary => const Color(0xFF64748B);
  @override
  Color get textDisabled => const Color(0xFF94A3B8);
  @override
  Color get divider => const Color(0xFFDCD8CE);
  @override
  Color get cardBackground => const Color(0xFFF4F2EC);
  @override
  Color get cardBorder => const Color(0xFF2D2D2D);
  @override
  Color get toolbarBackground => const Color(0xFFF4F2EC);
  @override
  Color get iconDefault => const Color(0xFF2D2D2D);
  @override
  Color get iconActive => const Color(0xFF2D2D2D);

  // ---- Typography ----
  @override
  String get fontFamily => 'Kalam';

  // ---- Radii ----
  @override
  double get radiusSm => 4.0;
  @override
  double get radiusMd => 8.0;
  @override
  double get radiusLg => 12.0;
  @override
  double get radiusXl => 20.0;

  // ---- Borders ----
  @override
  BorderSide get borderThin =>
      const BorderSide(color: Color(0xFF2D2D2D), width: 1.0);
  @override
  BorderSide get borderMedium =>
      const BorderSide(color: Color(0xFF2D2D2D), width: 2.0);
  @override
  Border get cardBorderStyle => Border.fromBorderSide(borderMedium);

  // ---- Shadows ----
  @override
  List<BoxShadow> get shadowSmall => [
    BoxShadow(
      color: const Color(0xFF2D2D2D).withValues(alpha: 0.15),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  @override
  List<BoxShadow> get shadowMedium => [
    BoxShadow(
      color: const Color(0xFF2D2D2D).withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  @override
  List<BoxShadow> get shadowLarge => [
    BoxShadow(
      color: const Color(0xFF2D2D2D).withValues(alpha: 0.25),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  // ---- Surface Decorators ----
  @override
  BoxDecoration get raisedSurface => BoxDecoration(
    color: surface,
    border: cardBorderStyle,
    borderRadius: BorderRadius.circular(radiusXl),
    boxShadow: shadowMedium,
  );

  @override
  BoxDecoration get buttonDefault => BoxDecoration(
    color: surface,
    border: cardBorderStyle,
    borderRadius: BorderRadius.circular(radiusLg),
    boxShadow: shadowSmall,
  );

  @override
  BoxDecoration get buttonPressed => BoxDecoration(
    color: surfaceVariant,
    border: cardBorderStyle,
    borderRadius: BorderRadius.circular(radiusLg),
  );

  @override
  BoxDecoration get insetSurface => BoxDecoration(
    color: surfaceVariant,
    border: cardBorderStyle,
    borderRadius: BorderRadius.circular(radiusLg),
  );

  @override
  BoxDecoration get toolbarDecoration => raisedSurface;

  // ---- Theme mode indicator & Backdrop ----
  @override
  bool get useBackdropBlur => false;

  @override
  BoxDecoration get appBackgroundDecoration => BoxDecoration(color: background);

  @override
  Widget applyBackdrop(Widget child, {BorderRadius? borderRadius}) {
    return child;
  }

  @override
  double get blurRadius => 0.0;
}
