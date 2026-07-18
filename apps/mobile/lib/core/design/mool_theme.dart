import 'package:flutter/material.dart';

abstract final class MoolColors {
  static const ink = Color(0xFF11163D);
  static const navy = Color(0xFF10156F);
  static const royal = Color(0xFF2636D9);
  static const orange = Color(0xFFFF8B3D);
  static const canvas = Color(0xFFF6F7FC);
  static const muted = Color(0xFF626887);
  static const line = Color(0xFFE1E4F2);
  static const success = Color(0xFF138A55);
}

abstract final class MoolTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: MoolColors.royal,
      brightness: Brightness.light,
      primary: MoolColors.royal,
      secondary: MoolColors.orange,
      surface: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MoolColors.canvas,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: MoolColors.ink,
          fontSize: 36,
          height: 1.05,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
        ),
        headlineMedium: TextStyle(
          color: MoolColors.ink,
          fontSize: 26,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        titleLarge: TextStyle(
          color: MoolColors.ink,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: TextStyle(color: MoolColors.ink, height: 1.45),
        bodyMedium: TextStyle(color: MoolColors.muted, height: 1.45),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: MoolColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: MoolColors.line),
        ),
      ),
    );
  }
}
