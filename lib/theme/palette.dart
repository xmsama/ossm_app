import 'package:flutter/material.dart';

/// Intimate dark palette. One warm-to-cool gradient, no industrial cyan-on-black.
abstract final class OssmPalette {
  static const bg = Color(0xFF100C17);
  static const bgMid = Color(0xFF18121F);
  static const surface = Color(0xFF201927);
  static const surfaceHi = Color(0xFF2C2238);
  static const track = Color(0xFF3A2E46);

  static const pink = Color(0xFFECA1CA);
  static const magenta = Color(0xFFC5A0E6);
  static const violet = Color(0xFFA793E8);
  static const cyan = Color(0xFF94CCCF);

  static const text = Color(0xFFF1EAF4);
  static const textMuted = Color(0xFFB4A7BD);
  static const textDim = Color(0xFF81738D);

  static const connected = Color(0xFF4ADE80);
  static const warning = Color(0xFFFBBF24);
  static const fault = Color(0xFFFF3B6B);

  static const ring = [pink, magenta, violet, cyan, pink];
}
