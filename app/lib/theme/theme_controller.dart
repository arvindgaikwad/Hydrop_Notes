import 'package:flutter/foundation.dart';
import 'hydrop_theme.dart';
import 'ink_theme.dart';
import 'glass_theme.dart';

/// Controls which theme is active. Widgets listen to this
/// via ListenableBuilder to reactively switch themes.
class ThemeController extends ChangeNotifier {
  static final InkTheme _ink = InkTheme();
  static final GlassTheme _glass = GlassTheme();

  HydropTheme _current = _ink; // Default to Ink

  HydropTheme get current => _current;

  bool get isGlass => _current is GlassTheme;
  bool get isInk => _current is InkTheme;

  String _inkFontFamily = 'Kalam';
  String get inkFontFamily => _inkFontFamily;

  void setInkFont(String fontName) {
    if (_inkFontFamily != fontName) {
      _inkFontFamily = fontName;
      notifyListeners();
    }
  }

  void setInk() {
    if (_current is! InkTheme) {
      _current = _ink;
      notifyListeners();
    }
  }

  void setGlass() {
    if (_current is! GlassTheme) {
      _current = _glass;
      notifyListeners();
    }
  }

  void toggle() {
    _current = isGlass ? _ink : _glass;
    notifyListeners();
  }
}
