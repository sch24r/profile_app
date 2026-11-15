import 'package:flutter/gestures.dart' show PointerScrollEvent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/context_x.dart';
import '../theme/motion.dart';
import '../widgets/motion/polygon_mask.dart';

/// Intro clock for the home hero (P1–P5), total [IntroScope.total].
///
/// Value is 1.0 when the intro already played, was skipped, or under reduced
/// motion. Consumers derive their own intervals, e.g.
/// `CurvedAnimation(parent: IntroScope.of(context), curve: IntroScope.navDrop)`.
class IntroScope extends InheritedWidget {
  const IntroScope({super.key, required this.intro, required super.child});

  final Animation<double> intro;

  /// Whole intro duration.
  static const total = Duration(milliseconds: 1800);

  /// P1 polygon mask (0–1000 ms).
  static const mask = Interval(0, 1000 / 1800);

  /// P3 CTA morph (400–800 ms).
  static const ctaMorph = Interval(400 / 1800, 800 / 1800);

  /// P4 nav drop (800–1500 ms).
  static const navDrop = Interval(800 / 1800, 1500 / 1800);

  /// P5 photo rise (1000–1800 ms).
  static const photoRise = Interval(1000 / 1800, 1.0);

  /// P5 toast (1000–1300 ms).
  static const toast = Interval(1000 / 1800, 1300 / 1800);

  /// The intro clock, or a completed animation when no intro is running.
  static Animation<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<IntroScope>()?.intro ??
      kAlwaysCompleteAnimation;

  @override
  bool updateShouldNotify(IntroScope oldWidget) => intro != oldWidget.intro;
}

/// Home intro overlay (P1): covers the page with `palette.display`, then a
/// polygon window zooms open (driven by [intro]). Tap, any key or a wheel
/// scroll calls [onSkip]. The owner (SiteShell) removes it once the mask
/// interval is over. Plays once per app session (see [hasPlayed]).
class IntroOverlay extends StatelessWidget {
  const IntroOverlay({super.key, required this.intro, required this.onSkip});

  final Animation<double> intro;
  final VoidCallback onSkip;

  static bool _played = false;

  /// Whether the intro already ran (or was deliberately not run) this session.
  static bool get hasPlayed => _played;

  /// Marks the intro as consumed for this app session.
  static void markPlayed() => _played = true;

  /// Re-arms the once-per-session intro (tests only).
  @visibleForTesting
  static void debugReset() => _played = false;

  /// End of the mask interval on the intro clock for this layout
  /// (900 ms on phones, 1000 ms otherwise).
  static double maskEnd(BuildContext context) =>
      (context.isMobile ? Motion.introMaskMobile : Motion.introMask)
          .inMicroseconds /
      IntroScope.total.inMicroseconds;

  @override
  Widget build(BuildContext context) {
    final end = maskEnd(context);
    return Semantics(
      button: true,
      label: 'Skip intro',
      onTap: onSkip,
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent) {
            onSkip();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Listener(
          onPointerSignal: (e) {
            if (e is PointerScrollEvent) onSkip();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSkip,
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: _IntroCurtainPainter(
                  intro: intro,
                  end: end,
                  color: context.palette.display,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IntroCurtainPainter extends CustomPainter {
  _IntroCurtainPainter({
    required this.intro,
    required this.end,
    required this.color,
  }) : super(repaint: intro);

  final Animation<double> intro;
  final double end;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = end <= 0 ? 1.0 : (intro.value / end).clamp(0.0, 1.0);
    if (t >= 1.0) return;
    if (t <= 0.0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = color);
      return;
    }
    PolygonCurtainPainter(t: t, color: color).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_IntroCurtainPainter old) =>
      old.intro != intro || old.end != end || old.color != color;
}
