import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Leonxlnx design tokens — mirrors web `globals.css` / `leon-overrides.css`.
abstract final class LeonColors {
  static const accent = Color(0xFF1E293B);
  static const accentDark = Color(0xFF0F172A);
  static const accentMid = Color(0xFF334155);
  static const accentLight = Color(0xFFF1F5F9);
  static const accentMuted = Color(0xFFE2E8F0);
  static const accentTint = Color(0x0F1E293B);
  static const canvas = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF0F172A);
  static const secondary = Color(0xFF64748B);
  static const muted = Color(0xFF94A3B8);
  static const label = Color(0xFF6C757D);
  static const border = Color(0xFFE2E8F0);
  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFECFDF5);
  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFFFBEB);
}

abstract final class LeonTypography {
  static TextStyle sans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.ibmPlexSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle heading({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w700,
    Color color = LeonColors.ink,
  }) =>
      sans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: -0.03 * fontSize,
      );

  static TextStyle mono({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  static TextStyle sectionLabel({Color color = LeonColors.label}) => mono(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: 1.2,
      );

  static TextStyle num({
    double fontSize = 18,
    FontWeight fontWeight = FontWeight.w700,
    Color color = LeonColors.ink,
  }) =>
      mono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: -0.02 * fontSize,
      );
}

ThemeData buildLeonTheme() {
  final base = GoogleFonts.ibmPlexSansTextTheme().apply(
    bodyColor: LeonColors.ink,
    displayColor: LeonColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: LeonColors.accent,
      brightness: Brightness.light,
      primary: LeonColors.accent,
      onPrimary: Colors.white,
      secondary: LeonColors.accentMid,
      surface: LeonColors.surface,
      onSurface: LeonColors.ink,
    ),
    scaffoldBackgroundColor: LeonColors.canvas,
    textTheme: base,
    appBarTheme: AppBarTheme(
      backgroundColor: LeonColors.surface,
      foregroundColor: LeonColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: LeonTypography.heading(fontSize: 19),
      iconTheme: const IconThemeData(color: LeonColors.ink),
      actionsIconTheme: const IconThemeData(color: LeonColors.ink),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      color: LeonColors.surface,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: LeonColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: LeonColors.canvas,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LeonColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LeonColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: LeonColors.accent, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      labelStyle: LeonTypography.sans(color: LeonColors.secondary, fontSize: 14),
      hintStyle: LeonTypography.mono(color: LeonColors.muted, fontSize: 13),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: LeonColors.accent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: LeonTypography.sans(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: LeonColors.accent,
        side: const BorderSide(color: LeonColors.accent),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: LeonTypography.sans(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: LeonColors.accent,
        textStyle: LeonTypography.sans(fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: LeonColors.accentLight,
      thickness: 1,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected) ? LeonColors.accent : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? LeonColors.accent.withValues(alpha: 0.4)
              : LeonColors.border),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: LeonColors.accentLight,
      labelStyle: LeonTypography.mono(color: LeonColors.accent, fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: LeonColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: LeonTypography.heading(fontSize: 17),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: LeonColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: LeonTypography.sans(fontSize: 14, color: Colors.white),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: LeonColors.accent,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: LeonColors.accent,
      strokeWidth: 2,
    ),
  );
}

/// Slate hero gradient used on dashboard / machines headers.
const leonHeroGradient = LinearGradient(
  colors: [LeonColors.accentDark, LeonColors.accent, LeonColors.accentMid],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
