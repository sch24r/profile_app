import 'package:flutter/material.dart';

import 'colors.dart';
import 'typography.dart';

abstract final class AppTheme {
  static final ThemeData light = _build(AppPalette.light);
  static final ThemeData dark = _build(AppPalette.dark);

  static ThemeData _build(AppPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.violet400,
      onSecondary: p.onAccent,
      error: const Color(0xFFB3261E),
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.inkMuted,
      outline: p.hairline,
      outlineVariant: p.hairline,
      surfaceContainerLowest: p.canvas,
      surfaceContainerLow: p.tint50,
      surfaceContainer: p.tint100,
      surfaceContainerHigh: p.tint200,
      inverseSurface: p.deep,
      onInverseSurface: p.onDeep,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.canvas,
      canvasColor: p.canvas,
      fontFamily: AppFonts.sans,
      textTheme: baseTextTheme(p.ink, p.inkMuted),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: p.primary.withValues(alpha: 0.18),
      iconTheme: IconThemeData(color: p.ink, size: 22),
      dividerTheme: DividerThemeData(color: p.hairline, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: TextStyle(color: p.canvas, fontFamily: AppFonts.sans),
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: p.violet300.withValues(alpha: 0.5),
        cursorColor: p.primary,
      ),
      extensions: [p],
    );
  }
}
