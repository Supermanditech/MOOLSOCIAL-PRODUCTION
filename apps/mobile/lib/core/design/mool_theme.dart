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
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: MoolColors.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: MoolColors.navy,
      ),
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
          backgroundColor: MoolColors.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFE4E4EC),
          disabledForegroundColor: const Color(0xFF8B8DA2),
          minimumSize: const Size.fromHeight(MoolMetrics.compactTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: -.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(MoolMetrics.compactTapTarget),
          foregroundColor: MoolColors.navy,
          backgroundColor: Colors.white.withValues(alpha: .72),
          side: const BorderSide(color: Color(0x32000080)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
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
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
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
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MoolColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MoolColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MoolColors.royal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB42318)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFB42318), width: 1.5),
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
        backgroundColor: const Color(0xFFF0F1F7),
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
      dividerTheme: const DividerThemeData(
        color: MoolColors.line,
        thickness: 1,
        space: 24,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(
            Size(44, MoolMetrics.minimumTapTarget),
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? Colors.white
                : MoolColors.navy,
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? MoolColors.navy
                : Colors.white,
          ),
          side: const WidgetStatePropertyAll(
            BorderSide(color: MoolColors.line),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
