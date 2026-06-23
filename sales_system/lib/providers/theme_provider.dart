import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/glass_liquid_theme.dart';

class ThemeProvider extends ChangeNotifier {
  Color _primaryBackground = const Color(0xFF1A1A1A); // modern_glass default
  Color _secondaryBackground = const Color(0xFF2A2A2A); // modern_glass default
  Color _accentBackground = const Color(0xFF3A3A3A); // modern_glass default
  
  // Dynamic controls (Hue and Intensity)
  // Hue in degrees [0, 360], Intensity [0.0, 1.0]
  double _hue = 220.0;
  double _intensity = 0.6;
  
  // Predefined theme sets inspired by glass liquid UI images
  static const Map<String, Map<String, Color>> _themes = {
    'smart_home': {
      'primary': Color(0xFF1A1A2E),      // Deep navy from smart home UI
      'secondary': Color(0xFF16213E),    // Slightly lighter navy
      'accent': Color(0xFF4A5568),       // Neutral gray accent
    },
    'e_commerce': {
      'primary': Color(0xFF2C2C54),      // Rich purple-gray from furniture UI
      'secondary': Color(0xFF40407A),    // Medium purple
      'accent': Color(0xFF706FD3),       // Light purple accent
    },
    'living_room': {
      'primary': Color(0xFF1E1E2E),      // Warm dark gray from living room UI
      'secondary': Color(0xFF2D2D44),    // Medium warm gray
      'accent': Color(0xFF4A4A6A),       // Soft purple-gray
    },
    'ocean_view': {
      'primary': Color(0xFF2D3748),      // Deep charcoal
      'secondary': Color(0xFF4A5568),    // Medium charcoal
      'accent': Color(0xFF718096),       // Light charcoal
    },
    'modern_glass': {
      'primary': Color(0xFF1A1A1A),      // Pure dark with glass effect
      'secondary': Color(0xFF2A2A2A),    // Slightly lighter
      'accent': Color(0xFF3A3A3A),       // Medium gray
    },
    'frosted_blue': {
      'primary': Color(0xFF2A2A2A),      // Deep frosted gray
      'secondary': Color(0xFF3A3A3A),    // Medium frosted gray
      'accent': Color(0xFF4A4A4A),       // Light frosted gray
    },
  };
  
  String _currentTheme = 'modern_glass';
  static const String _prefsThemeKey = 'nsb_theme_key';
  static const String _prefsHueKey = 'nsb_theme_hue';
  static const String _prefsIntensityKey = 'nsb_theme_intensity';
  static const String _prefsPrimaryArgbKey = 'nsb_theme_primary_argb';
  static const String _prefsSecondaryArgbKey = 'nsb_theme_secondary_argb';
  static const String _prefsAccentArgbKey = 'nsb_theme_accent_argb';

  ThemeProvider() {
    // Initialize global theme colors to match default selection
    GlassLiquidTheme.updateBackgroundColors(
      primary: _primaryBackground,
      secondary: _secondaryBackground,
      accent: _accentBackground,
    );
  }
  
  Color get primaryBackground => _primaryBackground;
  Color get secondaryBackground => _secondaryBackground;
  Color get accentBackground => _accentBackground;
  String get currentTheme => _currentTheme;
  double get hue => _hue;
  double get intensity => _intensity;
  
  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      _primaryBackground,
      _secondaryBackground,
      _accentBackground,
    ],
  );
  
  void updateBackgroundColors({
    Color? primary,
    Color? secondary,
    Color? accent,
  }) {
    bool changed = false;
    
    if (primary != null && primary != _primaryBackground) {
      _primaryBackground = primary;
      changed = true;
    }
    if (secondary != null && secondary != _secondaryBackground) {
      _secondaryBackground = secondary;
      changed = true;
    }
    if (accent != null && accent != _accentBackground) {
      _accentBackground = accent;
      changed = true;
    }
    
    if (changed) {
      _currentTheme = 'custom';
      // Update the global theme
      GlassLiquidTheme.updateBackgroundColors(
        primary: _primaryBackground,
        secondary: _secondaryBackground,
        accent: _accentBackground,
      );
      notifyListeners();
      _persistThemeState();
    }
  }
  
  void setTheme(String themeName) {
    if (_themes.containsKey(themeName)) {
      _currentTheme = themeName;
      final theme = _themes[themeName]!;
      
      _primaryBackground = theme['primary']!;
      _secondaryBackground = theme['secondary']!;
      _accentBackground = theme['accent']!;
      
      // When a predefined theme is selected, approximate hue/intensity
      _hue = HSLColor.fromColor(_primaryBackground).hue;
      _intensity = _estimateIntensityFromColors(
        _primaryBackground,
        _secondaryBackground,
        _accentBackground,
      );
      
      // Update the global theme
      GlassLiquidTheme.updateBackgroundColors(
        primary: _primaryBackground,
        secondary: _secondaryBackground,
        accent: _accentBackground,
      );
      
      notifyListeners();
      _persistThemeState();
    }
  }

  /// Persists preset name, hue, intensity, and the three background colors so startup matches last user choice.
  Future<void> _persistThemeState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsThemeKey, _currentTheme);
      await prefs.setDouble(_prefsHueKey, _hue);
      await prefs.setDouble(_prefsIntensityKey, _intensity);
      await prefs.setInt(_prefsPrimaryArgbKey, _primaryBackground.toARGB32());
      await prefs.setInt(_prefsSecondaryArgbKey, _secondaryBackground.toARGB32());
      await prefs.setInt(_prefsAccentArgbKey, _accentBackground.toARGB32());
    } catch (_) {
      // Ignore persistence errors; theme still works in-memory
    }
  }

  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final p = prefs.getInt(_prefsPrimaryArgbKey);
      final s = prefs.getInt(_prefsSecondaryArgbKey);
      final a = prefs.getInt(_prefsAccentArgbKey);
      if (p != null && s != null && a != null) {
        _primaryBackground = Color(p);
        _secondaryBackground = Color(s);
        _accentBackground = Color(a);
        _hue = prefs.getDouble(_prefsHueKey) ?? _hue;
        _intensity = prefs.getDouble(_prefsIntensityKey) ?? _intensity;
        final name = prefs.getString(_prefsThemeKey);
        if (name != null && name.isNotEmpty) {
          _currentTheme = name;
        }
        GlassLiquidTheme.updateBackgroundColors(
          primary: _primaryBackground,
          secondary: _secondaryBackground,
          accent: _accentBackground,
        );
        notifyListeners();
        return;
      }
      // Legacy: only named preset was saved
      final saved = prefs.getString(_prefsThemeKey);
      if (saved != null && _themes.containsKey(saved)) {
        setTheme(saved);
      }
    } catch (_) {
      // If prefs are unavailable, keep default theme
    }
  }
  
  List<String> get availableThemes => _themes.keys.toList();
  
  void resetToDefault() {
    setTheme('smart_home');
  }

  // ===== Hue/Intensity API =====
  void setHue(double newHue) {
    if (newHue == _hue) return;
    _hue = newHue.clamp(0.0, 360.0);
    _currentTheme = 'custom';
    _applyHueIntensity();
  }
  
  void setIntensity(double newIntensity) {
    if (newIntensity == _intensity) return;
    _intensity = newIntensity.clamp(0.0, 1.0);
    _currentTheme = 'custom';
    _applyHueIntensity();
  }

  void _applyHueIntensity() {
    final colors = _generateColorsFromHueIntensity(_hue, _intensity);
    _primaryBackground = colors[0];
    _secondaryBackground = colors[1];
    _accentBackground = colors[2];
    
    GlassLiquidTheme.updateBackgroundColors(
      primary: _primaryBackground,
      secondary: _secondaryBackground,
      accent: _accentBackground,
    );
    notifyListeners();
    _persistThemeState();
  }

  List<Color> _generateColorsFromHueIntensity(double hue, double intensity) {
    // Saturation fixed for rich glass colors
    const double saturation = 0.60;
    // Map intensity -> lightness bands. Higher intensity => brighter
    double l1 = (0.10 + 0.30 * intensity).clamp(0.0, 0.9);
    double l2 = (0.18 + 0.30 * intensity).clamp(0.0, 0.9);
    double l3 = (0.26 + 0.30 * intensity).clamp(0.0, 0.9);
    final primary = HSLColor.fromAHSL(1.0, hue, saturation, l1).toColor();
    final secondary = HSLColor.fromAHSL(1.0, hue, saturation, l2).toColor();
    final accent = HSLColor.fromAHSL(1.0, hue, saturation, l3).toColor();
    return [primary, secondary, accent];
  }

  double _estimateIntensityFromColors(Color a, Color b, Color c) {
    // Rough estimate based on perceived luminance average
    double lum(Color x) => (0.299 * x.red + 0.587 * x.green + 0.114 * x.blue) / 255.0;
    final avg = (lum(a) + lum(b) + lum(c)) / 3.0;
    // Map luminance roughly back to intensity range
    return avg.clamp(0.0, 1.0);
  }
}
