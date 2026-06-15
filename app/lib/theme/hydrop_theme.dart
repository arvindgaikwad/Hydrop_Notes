import 'package:flutter/material.dart';

/// Abstract base class for all Hydrop themes.
/// Every visual token is defined here. Concrete implementations
/// (InkTheme, GlassTheme) provide the actual values.
abstract class HydropTheme {
  // ---- Colors ----
  Color get background;
  Color get surface;
  Color get surfaceVariant;
  Color get sidebarBackground;
  Color get sidebarText;
  Color get sidebarTextSecondary;
  Color get sidebarSelected;
  Color get primary;
  Color get primaryVariant;
  Color get accent;
  Color get error;
  Color get textPrimary;
  Color get textSecondary;
  Color get textDisabled;
  Color get divider;
  Color get cardBackground;
  Color get cardBorder;
  Color get toolbarBackground;
  Color get iconDefault;
  Color get iconActive;

  // ---- Typography ----
  String get fontFamily;
  FontWeight get fontRegular => FontWeight.w400;
  FontWeight get fontMedium => FontWeight.w500;
  FontWeight get fontBold => FontWeight.w700;

  // ---- Spacing (shared 8pt grid) ----
  double get space4 => 4.0;
  double get space8 => 8.0;
  double get space12 => 12.0;
  double get space16 => 16.0;
  double get space24 => 24.0;
  double get space32 => 32.0;
  double get space48 => 48.0;

  // ---- Radii ----
  double get radiusSm;
  double get radiusMd;
  double get radiusLg;
  double get radiusXl;

  // ---- Borders ----
  BorderSide get borderThin;
  BorderSide get borderMedium;
  Border get cardBorderStyle;

  // ---- Shadows ----
  List<BoxShadow> get shadowSmall;
  List<BoxShadow> get shadowMedium;
  List<BoxShadow> get shadowLarge;

  // ---- Surface Decorators ----
  BoxDecoration get raisedSurface;
  BoxDecoration get buttonDefault;
  BoxDecoration get buttonPressed;
  BoxDecoration get insetSurface;

  // ---- Toolbar ----
  BoxDecoration get toolbarDecoration;

  // ---- Theme mode indicator & Backdrop ----
  bool get useBackdropBlur => false;
  double get blurRadius => 0.0;

  BoxDecoration get appBackgroundDecoration;
  Widget applyBackdrop(Widget child, {BorderRadius? borderRadius});

  // ---- Static accessor via InheritedWidget ----
  static HydropTheme of(BuildContext context) {
    final provider = context
        .dependOnInheritedWidgetOfExactType<HydropThemeProvider>();
    assert(provider != null, 'No HydropThemeProvider found in context');
    return provider!.theme;
  }
}

/// InheritedWidget that distributes the active theme down the widget tree.
class HydropThemeProvider extends InheritedWidget {
  final HydropTheme theme;

  const HydropThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  @override
  bool updateShouldNotify(HydropThemeProvider oldWidget) {
    return theme != oldWidget.theme;
  }
}
