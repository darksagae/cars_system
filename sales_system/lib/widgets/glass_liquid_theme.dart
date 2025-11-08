import 'package:flutter/material.dart';
import 'dart:ui';

/// Global theme class for Glass Liquid UI design system
/// Provides consistent colors, spacing, and styling across the app
class GlassLiquidTheme {
  // Private constructor to prevent instantiation
  GlassLiquidTheme._();

  // ========== CORE COLORS ==========
  
  // Background Colors (Dynamic - updated by ThemeProvider)
  static Color _currentBackground = const Color(0xFF0A0A0A);
  static Color _glassPrimary = const Color(0xFF1A1A2E);
  static Color _glassSecondary = const Color(0xFF16213E);
  static Color _glassAccent = const Color(0xFF2A2A3E);

  // Glass Effect Colors
  static const Color glassBorder = Color(0xFF4A5568);
  static const Color glassOverlay = Color(0x1AFFFFFF);
  static const Color glassShadow = Color(0x33000000);
  static const Color glassShadowLarge = Color(0x66000000);

  // Backdrop Filter
  static ImageFilter get backdropBlur => ImageFilter.blur(sigmaX: 16, sigmaY: 16);

  // Accent Colors
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentGreen = Color(0xFF10B981);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentIndigo = Color(0xFF6366F1);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFE2E8F0);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF64748B);

  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ========== SPACING ==========
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;

  // ========== BORDER RADIUS ==========
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 28.0;
  static const double radiusXXLarge = 36.0;

  // ========== TEXT STYLES ==========
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: textTertiary,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.2,
  );

  // ========== GLASS EFFECTS ==========
  static BoxDecoration get glassDecoration => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        glassPrimary.withOpacity(0.8),
        glassSecondary.withOpacity(0.6),
      ],
    ),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(
      color: glassBorder.withOpacity(0.3),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: glassShadow,
        blurRadius: 28,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration get glassCardDecoration => BoxDecoration(
    color: glassPrimary.withOpacity(0.72),
    borderRadius: BorderRadius.circular(radiusXLarge),
    border: Border.all(
      color: glassBorder.withOpacity(0.2),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: glassShadow,
        blurRadius: 20,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static LinearGradient get glassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      glassPrimary.withOpacity(0.8),
      glassSecondary.withOpacity(0.6),
    ],
  );

  // ========== GETTERS FOR DYNAMIC COLORS ==========
  static Color get currentBackground => _currentBackground;
  static Color get glassPrimary => _glassPrimary;
  static Color get glassSecondary => _glassSecondary;
  static Color get glassAccent => _glassAccent;

  // ========== DYNAMIC COLOR UPDATES ==========
  
  /// Updates the background colors dynamically
  /// Called by ThemeProvider when theme changes
  static void updateBackgroundColors({
    Color? primary,
    Color? secondary,
    Color? accent,
  }) {
    if (primary != null) _currentBackground = primary;
    if (secondary != null) _glassPrimary = secondary;
    if (accent != null) _glassSecondary = accent;
  }

  /// Resets to default theme colors
  static void resetToDefault() {
    _currentBackground = const Color(0xFF0A0A0A);
    _glassPrimary = const Color(0xFF1A1A2E);
    _glassSecondary = const Color(0xFF16213E);
    _glassAccent = const Color(0xFF2A2A3E);
  }
}

/// PDF-specific theme colors for PDF generation
class PdfGlassLiquidTheme {
  // Private constructor to prevent instantiation
  PdfGlassLiquidTheme._();

  // PDF Color variants (darker for better print contrast)
  static const Color accentBlue50 = Color(0xFFEFF6FF);
  static const Color accentBlue100 = Color(0xFFDBEAFE);
  static const Color accentBlue200 = Color(0xFFBFDBFE);
  static const Color accentBlue300 = Color(0xFF93C5FD);
  static const Color accentBlue400 = Color(0xFF60A5FA);
  static const Color accentBlue500 = Color(0xFF3B82F6);
  static const Color accentBlue600 = Color(0xFF2563EB);
  static const Color accentBlue700 = Color(0xFF1D4ED8);
  static const Color accentBlue800 = Color(0xFF1E40AF);
  static const Color accentBlue900 = Color(0xFF1E3A8A);

  // Text colors for PDF
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textTertiary = Color(0xFF6B7280);
}