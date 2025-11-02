import 'package:flutter/material.dart';

class ColorUtils {
  /// Converte um inteiro ARGB (0xAARRGGBB) para Color do Flutter.
  static Color? fromArgbInt(dynamic value) {
    if (value is int) return Color(value);
    return null;
  }
}
