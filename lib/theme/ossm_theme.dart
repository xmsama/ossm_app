import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';
import 'typography.dart';

abstract final class OssmTheme {
  static ThemeData dark() {
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
    );
    const scheme = ColorScheme.dark(
      surface: OssmPalette.surface,
      primary: OssmPalette.magenta,
      secondary: OssmPalette.cyan,
      error: OssmPalette.fault,
      onSurface: OssmPalette.text,
      onPrimary: Color(0xFF281C34),
      outline: Color(0xFF514359),
      outlineVariant: Color(0xFF332A3D),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'OssmSans',
      colorScheme: scheme,
      scaffoldBackgroundColor: OssmPalette.bg,
      splashFactory: InkRipple.splashFactory,
      splashColor: OssmPalette.magenta.withValues(alpha: .08),
      highlightColor: Colors.transparent,
      dividerColor: const Color(0xFF332A3D),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 68,
          fontWeight: FontWeight.w400,
          letterSpacing: -2,
          height: 1.0,
          color: OssmPalette.text,
        ),
        displayMedium: OssmType.page,
        displaySmall: OssmType.page,
        headlineLarge: OssmType.page,
        headlineMedium: OssmType.page,
        headlineSmall: OssmType.page,
        titleLarge: OssmType.section,
        titleMedium: OssmType.section,
        titleSmall: OssmType.label,
        bodyLarge: OssmType.body,
        bodyMedium: OssmType.body,
        bodySmall: OssmType.caption,
        labelLarge: OssmType.label,
        labelMedium: OssmType.secondary,
        labelSmall: OssmType.caption,
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: OssmPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
          side: BorderSide(color: Color(0xFF332A3D), width: .7),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          elevation: 0,
          shape: shape,
          textStyle: OssmType.label.copyWith(fontFamily: 'OssmSans'),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: OssmPalette.text,
          side: const BorderSide(color: Color(0xFF514359), width: .8),
          shape: shape,
          textStyle: OssmType.label.copyWith(fontFamily: 'OssmSans'),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: OssmPalette.magenta,
          shape: shape,
          minimumSize: const Size(48, 44),
          textStyle: OssmType.label.copyWith(fontFamily: 'OssmSans'),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: OssmPalette.bgMid,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        labelStyle: OssmType.secondary,
        hintStyle: OssmType.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: OssmPalette.magenta, width: .8),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: OssmPalette.magenta,
        inactiveTrackColor: OssmPalette.track,
        thumbColor: OssmPalette.magenta,
        overlayColor: OssmPalette.magenta.withValues(alpha: .08),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? OssmPalette.magenta
              : OssmPalette.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? const Color(0xFF554266)
              : OssmPalette.track,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(
          fontFamily: 'OssmSans',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: OssmPalette.text,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'OssmSans',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: OssmPalette.textMuted,
        ),
        iconColor: OssmPalette.textMuted,
        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: OssmPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(24)),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'OssmSans',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: OssmPalette.text,
          height: 1.5,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'OssmSans',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: OssmPalette.textMuted,
          height: 1.7,
        ),
      ),
      iconTheme: const IconThemeData(size: 21, color: OssmPalette.textMuted),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: OssmPalette.bg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      ),
    );
  }
}
