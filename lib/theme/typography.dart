import 'package:flutter/material.dart';

import 'palette.dart';

/// One type scale for Chinese, Latin, controls and dialogs.
abstract final class OssmType {
  static const page = TextStyle(
    fontSize: 23,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: OssmPalette.text,
  );
  static const section = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: OssmPalette.text,
  );
  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: OssmPalette.text,
  );
  static const secondary = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: OssmPalette.textMuted,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: OssmPalette.textMuted,
  );
  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );
}
