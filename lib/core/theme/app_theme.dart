import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF2B5FD9);
  static const background = Color(0xFFF4F7FB);
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const infoBg = Color(0xFFEAF0FD);
  static const danger = Color(0xFFDC2626);

  // Dark mode colours
  static const _darkBackground = Color(0xFF0B1220);
  static const _darkSurface = Color(0xFF111A2B);
  static const _darkBorder = Color(0xFF2A3550);
  static const _darkHint = Color(0xFF94A3B8);

  /// Shared input style. The hint is smaller (13) and subtler than the typed text.
  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color borderColor,
    required Color hint,
  }) {
    OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: c, width: w),
    );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      hintStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: hint,
      ),
      border: b(borderColor),
      enabledBorder: b(borderColor),
      focusedBorder: b(primary, 1.5),
      errorBorder: b(danger),
      focusedErrorBorder: b(danger, 1.5),
    );
  }

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
    scaffoldBackgroundColor: background,
    inputDecorationTheme: _inputTheme(
      fill: Colors.white,
      borderColor: border,
      hint: textMuted,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: infoBg,
    ),
  );

  static ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: _darkBackground,
    inputDecorationTheme: _inputTheme(
      fill: _darkSurface,
      borderColor: _darkBorder,
      hint: _darkHint,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _darkSurface,
      indicatorColor: const Color(0xFF1E2F55),
    ),
  );
}