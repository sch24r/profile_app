import 'package:flutter/material.dart';

/// All colour tokens for the app. Two instances: [AppPalette.light] and
/// [AppPalette.dark]. Access with `context.palette` (see core/context_x.dart).
///
/// Text rules (WCAG AA):
/// * On canvas / surface / tint50 / tint100 / tint200 use [ink], [inkMuted] or [primary].
/// * On [deep] use [onDeep], [onDeepMuted] or [violet300].
/// * On the pastel accent cards ([periwinkle], [mint], [peach], [violet400])
///   ALWAYS use [onAccent] / [onAccentMuted] (fixed dark ink in both themes).
/// * [flare] is decoration only — never text.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.tint50,
    required this.tint100,
    required this.tint200,
    required this.violet300,
    required this.violet400,
    required this.primary,
    required this.primaryPressed,
    required this.onPrimary,
    required this.deep,
    required this.onDeep,
    required this.onDeepMuted,
    required this.display,
    required this.ink,
    required this.inkMuted,
    required this.hairline,
    required this.periwinkle,
    required this.mint,
    required this.peach,
    required this.flare,
    required this.onAccent,
    required this.onAccentMuted,
    required this.scrim,
    required this.hoverPill,
  });

  final Brightness brightness;

  /// Page background.
  final Color canvas;

  /// Cards, nav bar, chips.
  final Color surface;
  final Color tint50;
  final Color tint100;
  final Color tint200;
  final Color violet300;
  final Color violet400;
  final Color primary;
  final Color primaryPressed;
  final Color onPrimary;

  /// Dark panels (stats, contact, ticker band, intro overlay in light theme).
  final Color deep;
  final Color onDeep;
  final Color onDeepMuted;

  /// Giant display headline colour (hero name). The intro / route overlay uses
  /// the same colour so the name looks "carved" out of it (pattern P2).
  final Color display;

  /// Main text.
  final Color ink;
  final Color inkMuted;
  final Color hairline;

  /// Pastel accent card fills — text on them is always [onAccent].
  final Color periwinkle;
  final Color mint;
  final Color peach;

  /// Decoration only.
  final Color flare;
  final Color onAccent;
  final Color onAccentMuted;

  /// Menu scrim / frame colour.
  final Color scrim;

  /// Nav-link hover pill.
  final Color hoverPill;

  bool get isDark => brightness == Brightness.dark;

  static const light = AppPalette(
    brightness: Brightness.light,
    canvas: Color(0xFFF7F3FF),
    surface: Color(0xFFFFFFFF),
    tint50: Color(0xFFF1E9FF),
    tint100: Color(0xFFEBDDFF),
    tint200: Color(0xFFDCC6FF),
    violet300: Color(0xFFC9A2FF),
    violet400: Color(0xFFB78BFF),
    primary: Color(0xFF6B3FD9),
    primaryPressed: Color(0xFF5328B8),
    onPrimary: Color(0xFFFFFFFF),
    deep: Color(0xFF2A0E57),
    onDeep: Color(0xFFFFFFFF),
    onDeepMuted: Color(0xFFB9A8DA),
    display: Color(0xFF2A0E57),
    ink: Color(0xFF1C0A3A),
    inkMuted: Color(0xFF584A75),
    hairline: Color(0xFFE4DAF7),
    periwinkle: Color(0xFFDCE4FF),
    mint: Color(0xFFDDF6C9),
    peach: Color(0xFFFFE1D3),
    flare: Color(0xFFFF6B4A),
    onAccent: Color(0xFF1C0A3A),
    onAccentMuted: Color(0xFF4A3D66),
    scrim: Color(0xFFDCC6FF),
    hoverPill: Color(0xFFEDE6FB),
  );

  static const dark = AppPalette(
    brightness: Brightness.dark,
    canvas: Color(0xFF100A1F),
    surface: Color(0xFF1A1230),
    tint50: Color(0xFF160F29),
    tint100: Color(0xFF251842),
    tint200: Color(0xFF33215C),
    violet300: Color(0xFFC9A2FF),
    violet400: Color(0xFFA987F0),
    primary: Color(0xFFB79BFF),
    primaryPressed: Color(0xFF9C7BF5),
    onPrimary: Color(0xFF1C0A3A),
    deep: Color(0xFF2E1466),
    onDeep: Color(0xFFFFFFFF),
    onDeepMuted: Color(0xFFC9B8EA),
    display: Color(0xFFE6D8FF),
    ink: Color(0xFFF2ECFF),
    inkMuted: Color(0xFFB9A8DA),
    hairline: Color(0xFF2C2148),
    periwinkle: Color(0xFFC9D3F5),
    mint: Color(0xFFCBE6B6),
    peach: Color(0xFFF0CDBD),
    flare: Color(0xFFFF7A5C),
    onAccent: Color(0xFF1C0A3A),
    onAccentMuted: Color(0xFF3F3358),
    scrim: Color(0xFF33215C),
    hoverPill: Color(0xFF2A1D47),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      tint50: l(tint50, other.tint50),
      tint100: l(tint100, other.tint100),
      tint200: l(tint200, other.tint200),
      violet300: l(violet300, other.violet300),
      violet400: l(violet400, other.violet400),
      primary: l(primary, other.primary),
      primaryPressed: l(primaryPressed, other.primaryPressed),
      onPrimary: l(onPrimary, other.onPrimary),
      deep: l(deep, other.deep),
      onDeep: l(onDeep, other.onDeep),
      onDeepMuted: l(onDeepMuted, other.onDeepMuted),
      display: l(display, other.display),
      ink: l(ink, other.ink),
      inkMuted: l(inkMuted, other.inkMuted),
      hairline: l(hairline, other.hairline),
      periwinkle: l(periwinkle, other.periwinkle),
      mint: l(mint, other.mint),
      peach: l(peach, other.peach),
      flare: l(flare, other.flare),
      onAccent: l(onAccent, other.onAccent),
      onAccentMuted: l(onAccentMuted, other.onAccentMuted),
      scrim: l(scrim, other.scrim),
      hoverPill: l(hoverPill, other.hoverPill),
    );
  }
}

/// Fill + foreground pair for a card. Use [CardTone.resolve] to get colours.
enum CardTone { surface, tint, lilac, periwinkle, mint, peach, violet, deep }

@immutable
class ToneColors {
  const ToneColors(this.fill, this.fg, this.fgMuted, this.accent);
  final Color fill;
  final Color fg;
  final Color fgMuted;
  final Color accent;
}

extension CardToneX on CardTone {
  ToneColors resolve(AppPalette p) => switch (this) {
    CardTone.surface => ToneColors(p.surface, p.ink, p.inkMuted, p.primary),
    CardTone.tint => ToneColors(p.tint50, p.ink, p.inkMuted, p.primary),
    CardTone.lilac => ToneColors(p.tint100, p.ink, p.inkMuted, p.primary),
    CardTone.periwinkle => ToneColors(
      p.periwinkle,
      p.onAccent,
      p.onAccentMuted,
      const Color(0xFF3A2C8F),
    ),
    CardTone.mint => ToneColors(
      p.mint,
      p.onAccent,
      p.onAccentMuted,
      const Color(0xFF2F5A1F),
    ),
    CardTone.peach => ToneColors(
      p.peach,
      p.onAccent,
      p.onAccentMuted,
      const Color(0xFF8A2E14),
    ),
    CardTone.violet => ToneColors(
      p.violet400,
      p.onAccent,
      p.onAccentMuted,
      p.onAccent,
    ),
    CardTone.deep => ToneColors(p.deep, p.onDeep, p.onDeepMuted, p.violet300),
  };
}
