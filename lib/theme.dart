// lib/theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // ── Palette ─────────────────────────────────────────────────
  static const bg         = Color(0xFF070B12);
  static const surface    = Color(0xFF0E1520);
  static const surface2   = Color(0xFF151E2E);
  static const border     = Color(0xFF1E2A3A);
  static const accent     = Color(0xFF00D4FF);
  static const accentDim  = Color(0x2600D4FF);
  static const warn       = Color(0xFFFF6B35);
  static const warnDim    = Color(0x26FF6B35);
  static const green      = Color(0xFF00E676);
  static const greenDim   = Color(0x2600E676);
  static const bt         = Color(0xFFB980FF);
  static const btDim      = Color(0x26B980FF);
  static const textPrimary   = Color(0xFFDDE4ED);
  static const textMuted     = Color(0xFF5A6478);

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      surface: surface,
      primary: accent,
      secondary: bt,
      error: warn,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: textPrimary, fontFamily: 'monospace'),
      bodySmall: TextStyle(color: textMuted),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: accent,
      inactiveTrackColor: surface2,
      thumbColor: accent,
      overlayColor: accentDim,
      trackHeight: 3,
    ),
    dividerColor: border,
  );
}
