import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF2B5FD9);
  static const background = Color(0xFFF4F7FB);
  static const textDark = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const border = Color(0xFFE2E8F0);
  static const infoBg = Color(0xFFEAF0FD);
  static const danger = Color(0xFFDC2626);

  static ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
    scaffoldBackgroundColor: background,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: infoBg,
    ),
  );
}