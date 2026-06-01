import 'package:flutter/material.dart';

extension ThemeColors on BuildContext {
  Color get surface => Theme.of(this).colorScheme.surface;
  Color get cardSurface => Theme.of(this).cardColor;
  Color get primary => Theme.of(this).colorScheme.primary;
  Color get onSurface => Theme.of(this).colorScheme.onSurface;
  Color get onSurfaceLow => Theme.of(this).colorScheme.onSurface.withValues(alpha: 0.6);
  Color get scaffoldBg => Theme.of(this).scaffoldBackgroundColor;

  Color accentColor(int index) {
    const accents = [
      Color(0xFFC9A96E), Color(0xFF8B7A8B), Color(0xFFB8736D),
      Color(0xFF6B7D8D), Color(0xFF7A9B7E), Color(0xFFD4A574),
      Color(0xFFA88DB5), Color(0xFF6FB3B8),
    ];
    return accents[index.clamp(0, accents.length - 1)];
  }
}
