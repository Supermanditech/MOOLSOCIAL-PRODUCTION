import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'mool_colors.dart';
import 'mool_design_system.dart';

export 'mool_colors.dart';

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
      fontFamily: 'Inter',
      colorScheme: scheme,
      scaffoldBackgroundColor: MoolColors.canvas,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: MoolColors.ink,
          fontSize: 30,
          height: 1.08,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
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
          minimumSize: const Size.fromHeight(MoolMetrics.compactTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MoolRadii.control),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(MoolMetrics.compactTapTarget),
          foregroundColor: MoolColors.navy,
          side: const BorderSide(color: MoolColors.navy),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MoolRadii.control),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            MoolMetrics.minimumTapTarget,
            MoolMetrics.minimumTapTarget,
          ),
          foregroundColor: MoolColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MoolRadii.control),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
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
          borderRadius: BorderRadius.circular(MoolRadii.control),
          borderSide: const BorderSide(color: MoolColors.navy),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MoolRadii.control),
          borderSide: const BorderSide(color: MoolColors.navy),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: Colors.white,
        modalElevation: 0,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(MoolRadii.sheet),
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(MoolRadii.card)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xF21B1B2F),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MoolRadii.control),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFF0F1F8),
        selectedColor: MoolColors.navy,
        labelStyle: const TextStyle(
          color: MoolColors.navy,
          fontWeight: FontWeight.w700,
        ),
        secondaryLabelStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: const StadiumBorder(),
        side: BorderSide.none,
      ),
    );
  }
}
