import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';

abstract final class OssmTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      surface: OssmPalette.bg,
      primary: OssmPalette.magenta,
      secondary: OssmPalette.cyan,
      error: OssmPalette.fault,
      onSurface: OssmPalette.text,
      onPrimary: OssmPalette.text,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: OssmPalette.bg,
      splashFactory: InkRipple.splashFactory,
      splashColor: OssmPalette.magenta.withValues(alpha: 0.12),
      highlightColor: Colors.transparent,
      dividerColor: Colors.transparent,
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
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 72,
          fontWeight: FontWeight.w600,
          letterSpacing: -2,
          height: 0.95,
          color: OssmPalette.text,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: OssmPalette.text,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.4,
          color: OssmPalette.textDim,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: OssmPalette.textMuted,
        ),
      ),
    );
  }
}
