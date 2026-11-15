import 'package:flutter/material.dart';

import '../core/breakpoints.dart';

abstract final class AppFonts {
  static const display = 'Unbounded';
  static const sans = 'PlusJakartaSans';
  static const mono = 'JetBrainsMono';
}

TextStyle _s(
  String family,
  double size,
  double weight, {
  double height = 1.3,
  double trackingEm = 0,
  List<FontFeature>? features,
}) => TextStyle(
  fontFamily: family,
  fontSize: size,
  fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
  fontVariations: [FontVariation.weight(weight)],
  height: height,
  letterSpacing: size * trackingEm,
  fontFeatures: features,
  leadingDistribution: TextLeadingDistribution.even,
);

/// Fluid type scale (docs/spec.md §1.2). Colours are NOT set here — they come
/// from DefaultTextStyle / the caller via `.copyWith(color: ...)`.
///
/// Usage: `final t = AppType.of(context); Text('x', style: t.headingM)`.
class AppType {
  AppType._(this._c);
  factory AppType.of(BuildContext context) => AppType._(context);
  final BuildContext _c;

  double _f(double min, double max) => _c.fluid(min, max);

  /// Hero name: giant blocky caps.
  TextStyle get heroName => _s(
    AppFonts.display,
    (_c.screenWidth * (_c.isMobile ? 0.13 : 0.105)).clamp(38.0, 168.0),
    900,
    height: 0.95,
    trackingEm: -0.02,
  );
  TextStyle get displayL =>
      _s(AppFonts.display, _f(34, 96), 800, height: 0.95, trackingEm: -0.02);
  TextStyle get displayM =>
      _s(AppFonts.display, _f(26, 56), 800, height: 0.98, trackingEm: -0.01);
  TextStyle get displayS =>
      _s(AppFonts.display, _f(22, 32), 800, height: 1.0, trackingEm: -0.01);
  TextStyle get stat => _s(
    AppFonts.display,
    _f(40, 72),
    800,
    height: 1.0,
    features: const [FontFeature.tabularFigures()],
  );
  TextStyle get headingL =>
      _s(AppFonts.sans, _f(24, 36), 700, height: 1.1, trackingEm: -0.02);
  TextStyle get headingM =>
      _s(AppFonts.sans, _f(20, 26), 700, height: 1.15, trackingEm: -0.01);
  TextStyle get title => _s(AppFonts.sans, _f(17, 19), 600, height: 1.3);
  TextStyle get bodyL =>
      _s(AppFonts.sans, _f(17, 20), 400, height: 1.5, trackingEm: -0.01);
  TextStyle get body => _s(AppFonts.sans, _f(15, 16), 400, height: 1.55);
  TextStyle get caption => _s(AppFonts.sans, _f(13, 14), 500, height: 1.45);
  TextStyle get label =>
      _s(AppFonts.mono, _f(12, 13), 500, height: 1.3, trackingEm: 0.08);
  TextStyle get mono => _s(AppFonts.mono, _f(13, 14), 500, height: 1.4);
  TextStyle get button => _s(AppFonts.sans, 15, 600, height: 1.0);
  TextStyle get buttonCaps =>
      _s(AppFonts.sans, 13, 700, height: 1.0, trackingEm: 0.04);
}

/// Non-fluid base text theme used by ThemeData (Material widgets fallback).
TextTheme baseTextTheme(Color ink, Color muted) => TextTheme(
  displayLarge: _s(AppFonts.display, 57, 800).copyWith(color: ink),
  headlineMedium: _s(AppFonts.sans, 28, 700).copyWith(color: ink),
  titleLarge: _s(AppFonts.sans, 20, 700).copyWith(color: ink),
  titleMedium: _s(AppFonts.sans, 16, 600).copyWith(color: ink),
  bodyLarge: _s(AppFonts.sans, 16, 400, height: 1.55).copyWith(color: ink),
  bodyMedium: _s(AppFonts.sans, 15, 400, height: 1.55).copyWith(color: ink),
  bodySmall: _s(AppFonts.sans, 13, 500).copyWith(color: muted),
  labelLarge: _s(AppFonts.sans, 15, 600).copyWith(color: ink),
  labelSmall: _s(AppFonts.mono, 12, 500).copyWith(color: muted),
);
