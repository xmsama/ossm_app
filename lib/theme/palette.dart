import 'package:flutter/material.dart';

/// Intimate dark palette. One warm-to-cool gradient, no industrial cyan-on-black.
abstract final class OssmPalette {
  static const bg = Color(0xFF07040F);
  static const bgMid = Color(0xFF140A22);
  static const surface = Color(0xFF1A1028);
  static const surfaceHi = Color(0xFF26183A);
  static const track = Color(0xFF2C203E);

  static const pink = Color(0xFFFF2D9B);
  static const magenta = Color(0xFFE14BFF);
  static const violet = Color(0xFF8B5CFF);
  static const cyan = Color(0xFF2DE2FF);

  static const text = Color(0xFFF7F2FF);
  static const textMuted = Color(0xFFA498BC);
  static const textDim = Color(0xFF6E6484);

  static const connected = Color(0xFF4ADE80);
  static const warning = Color(0xFFFBBF24);
  static const fault = Color(0xFFFF3B6B);

  static const ring = [pink, magenta, violet, cyan, pink];
}
