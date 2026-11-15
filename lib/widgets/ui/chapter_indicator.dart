import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';
import '../motion/story_progress.dart';

/// P15 chapter progress pill (desktop only; `SizedBox.shrink` otherwise).
///
/// Ink pill, 26 px wide, on the right edge and vertically centred (it wraps
/// itself in `Align(centerRight)` + 16 px inset, so drop it straight into a
/// full-size `Stack`). Three steps: inactive 6 px dots, the active step a
/// 6×22 bar that fills with [StoryProgress.activeProgress]. Dot ↔ bar uses
/// [Motion.indicatorStep] with [Motion.indicator] (slight overshoot). Slides
/// out +48 px ([Motion.indicatorSlide], expoOut) when `!progress.visible`.
/// Decorative: excluded from semantics, ignores pointers.
class ChapterIndicator extends StatelessWidget {
  const ChapterIndicator({super.key, required this.progress, this.controller});

  final StoryProgress progress;

  /// Deprecated, ignored. Kept only so existing call sites keep compiling;
  /// the indicator is decorative (no tap-to-scroll).
  final ScrollController? controller;

  static const _chapters = 3;
  static const _width = 26.0;
  static const _dot = 6.0;
  static const _bar = 22.0;
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    if (!context.isDesktop) return const SizedBox.shrink();
    final p = context.palette;
    final reduce = context.reduceMotion;
    final stepDur = reduce ? Duration.zero : Motion.indicatorStep;
    final slideDur = reduce ? Duration.zero : Motion.indicatorSlide;
    final pillColor = p.ink;
    final idle = p.canvas.withValues(alpha: 0.38);
    final fill = p.canvas;

    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: ListenableBuilder(
                listenable: progress,
                builder: (context, _) {
                  final active = progress.active.clamp(0, _chapters - 1);
                  final pill = DecoratedBox(
                    decoration: BoxDecoration(
                      color: pillColor,
                      borderRadius: BorderRadius.circular(_width / 2),
                    ),
                    child: SizedBox(
                      width: _width,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < _chapters; i++) ...[
                              if (i > 0) const SizedBox(height: _gap),
                              _Step(
                                active: i == active,
                                fill: i == active
                                    ? progress.activeProgress.clamp(0.0, 1.0)
                                    : (i < active ? 1.0 : 0.0),
                                duration: stepDur,
                                idle: idle,
                                color: fill,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: progress.visible ? 0 : 1),
                    duration: slideDur,
                    curve: Motion.expoOut,
                    child: pill,
                    builder: (context, v, child) => Transform.translate(
                      offset: Offset(48 * v, 0),
                      child: Opacity(opacity: 1 - v, child: child),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One step: a dot that grows into a filling bar when [active].
class _Step extends StatelessWidget {
  const _Step({
    required this.active,
    required this.fill,
    required this.duration,
    required this.idle,
    required this.color,
  });

  final bool active;
  final double fill;
  final Duration duration;
  final Color idle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        end: active ? ChapterIndicator._bar : ChapterIndicator._dot,
      ),
      duration: duration,
      curve: Motion.indicator,
      builder: (context, h, _) => SizedBox(
        width: ChapterIndicator._dot,
        height: h.clamp(ChapterIndicator._dot, ChapterIndicator._bar + 4),
        child: CustomPaint(
          painter: _StepPainter(
            fill: active ? fill : 0,
            idle: idle,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _StepPainter extends CustomPainter {
  _StepPainter({required this.fill, required this.idle, required this.color});
  final double fill;
  final Color idle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.width / 2);
    final rr = RRect.fromRectAndRadius(Offset.zero & size, r);
    canvas.drawRRect(rr, Paint()..color = idle);
    if (fill <= 0) return;
    canvas.save();
    canvas.clipRRect(rr);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * fill),
      Paint()..color = color,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StepPainter old) =>
      old.fill != fill || old.idle != idle || old.color != color;
}
