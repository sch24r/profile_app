import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../data/models.dart';
import '../../theme/motion.dart';
import '../motion/viewport_gate.dart';
import '../ui/bento_card.dart';

/// Small flat project illustration (~120×90, 4:3) for a [ProjectArt] kind:
/// terminal, blocks, waveform or bars.
///
/// Resting state is a static frame. When [active] (hover / tap on the card)
/// the art nudges (−5, −5) px ([Motion.chipSwap], expoOut — P12) and its
/// loop runs; the loop is a single controller under a [ViewportGate] and is
/// off under reduced motion. Colours default to the enclosing [BentoCard]:
/// [color] = shapes (tone fg), [onColor] = details drawn on top of shapes
/// (tone fill).
class ProjectArtView extends StatelessWidget {
  const ProjectArtView(
    this.art, {
    super.key,
    this.active = false,
    this.color,
    this.onColor,
  });

  final ProjectArt art;
  final bool active;
  final Color? color;
  final Color? onColor;

  @override
  Widget build(BuildContext context) {
    final tones = BentoCard.tonesOf(context);
    return ExcludeSemantics(
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.hasBoundedWidth ? c.maxWidth : 120.0;
          final h = c.hasBoundedHeight
              ? math.min(c.maxHeight, w * 0.75)
              : w * 0.75;
          return SizedBox(
            width: w,
            height: h,
            child: ViewportGate(
              child: _ArtLoop(
                art: art,
                active: active,
                color: color ?? tones.fg,
                onColor: onColor ?? tones.fill,
                accent: tones.accent,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArtLoop extends StatefulWidget {
  const _ArtLoop({
    required this.art,
    required this.active,
    required this.color,
    required this.onColor,
    required this.accent,
  });

  final ProjectArt art;
  final bool active;
  final Color color;
  final Color onColor;
  final Color accent;

  @override
  State<_ArtLoop> createState() => _ArtLoopState();
}

class _ArtLoopState extends State<_ArtLoop> with TickerProviderStateMixin {
  static const _period = Duration(milliseconds: 2400);

  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: _period,
  );
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: Motion.chipSwap,
  );
  late final Animation<Offset> _offset =
      Tween<Offset>(begin: Offset.zero, end: const Offset(-5, -5)).animate(
        CurvedAnimation(
          parent: _nudge,
          curve: Motion.expoOut,
          reverseCurve: Motion.expoOut.flipped,
        ),
      );

  bool _reduce = false;

  /// True while the loop runs its last cycle out to the rest frame.
  bool _finishing = false;

  /// Bumped per finish run so a stale completion callback is ignored.
  int _finishRun = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = context.reduceMotion;
    _sync(animate: false);
  }

  @override
  void didUpdateWidget(_ArtLoop old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync(animate: true);
  }

  void _sync({required bool animate}) {
    final on = widget.active;
    if (_reduce) {
      _finishing = false;
      _finishRun++;
      _loop.stop();
      _loop.value = 0;
      _nudge.value = on ? 1 : 0;
      return;
    }
    if (on) {
      // Restart the repeat if idle or if it was finishing its last cycle
      // (otherwise re-activating mid-finish would leave the loop stopped).
      if (_finishing || !_loop.isAnimating) {
        _finishing = false;
        _finishRun++;
        _loop.repeat();
      }
      if (animate) {
        _nudge.forward();
      } else {
        _nudge.value = 1;
      }
    } else {
      // Finish the current cycle to the rest frame, then stop.
      if (_loop.isAnimating && !_finishing) {
        _finishing = true;
        final run = ++_finishRun;
        _loop
            .animateTo(1.0, duration: _period * (1 - _loop.value))
            .whenCompleteOrCancel(() {
              if (run != _finishRun) return;
              _finishing = false;
              if (mounted && !widget.active && !_loop.isAnimating) {
                _loop.value = 0;
              }
            });
      }
      if (animate) {
        _nudge.reverse();
      } else {
        _nudge.value = 0;
      }
    }
  }

  @override
  void dispose() {
    _loop.dispose();
    _nudge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = switch (widget.art) {
      ProjectArt.terminal => _TerminalPainter(
        _loop,
        widget.color,
        widget.onColor,
        widget.accent,
      ),
      ProjectArt.blocks => _BlocksPainter(
        _loop,
        widget.color,
        widget.onColor,
        widget.accent,
      ),
      ProjectArt.waveform => _WaveformPainter(
        _loop,
        widget.color,
        widget.onColor,
        widget.accent,
      ),
      ProjectArt.bars => _BarsPainter(
        _loop,
        widget.color,
        widget.onColor,
        widget.accent,
      ),
    };
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _offset,
        builder: (context, child) =>
            Transform.translate(offset: _offset.value, child: child),
        child: CustomPaint(painter: painter, size: Size.infinite),
      ),
    );
  }
}

/// Base: repaints from the loop; subclasses draw in a 120×90 design box
/// scaled uniformly and centred into the actual size.
abstract class _ArtPainter extends CustomPainter {
  _ArtPainter(this.t, this.color, this.onColor, this.accent)
    : super(repaint: t);

  final Animation<double> t;
  final Color color;
  final Color onColor;
  final Color accent;

  static const designW = 120.0;
  static const designH = 90.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final s = math.min(size.width / designW, size.height / designH);
    canvas.save();
    canvas.translate(
      (size.width - designW * s) / 2,
      (size.height - designH * s) / 2,
    );
    canvas.scale(s);
    draw(canvas, t.value);
    canvas.restore();
  }

  void draw(Canvas canvas, double v);

  @override
  bool shouldRepaint(_ArtPainter old) =>
      old.runtimeType != runtimeType ||
      old.t != t ||
      old.color != color ||
      old.onColor != onColor ||
      old.accent != accent;
}

/// Terminal window: title-bar dots, prompt lines that "type" while active,
/// and a blinking block cursor.
class _TerminalPainter extends _ArtPainter {
  _TerminalPainter(super.t, super.color, super.onColor, super.accent);

  static const _lines = [0.62, 0.84, 0.46, 0.7];

  /// Prompt chevrons, one per line (design space, built once).
  static final List<Path> _chevrons = [
    for (var i = 0; i < _lines.length; i++) _chevron(32.0 + i * 12),
  ];

  static Path _chevron(double y) => Path()
    ..moveTo(12, y)
    ..lineTo(17, y + 3)
    ..lineTo(12, y + 6)
    ..lineTo(12, y + 4.4)
    ..lineTo(14.6, y + 3)
    ..lineTo(12, y + 1.6)
    ..close();
  static final _window = RRect.fromRectAndRadius(
    const Rect.fromLTWH(4, 6, 112, 78),
    const Radius.circular(8),
  );

  @override
  void draw(Canvas canvas, double v) {
    final fill = Paint()..color = color;
    canvas.drawRRect(_window, fill);

    final dot = Paint()..color = onColor.withValues(alpha: 0.5);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(14.0 + i * 8, 15), 2.4, dot);
    }
    canvas.drawRect(
      const Rect.fromLTWH(4, 22, 112, 1),
      Paint()..color = onColor.withValues(alpha: 0.2),
    );

    // Typing progress across all lines (v = 0 → fully typed rest frame).
    final typed = v == 0 ? _lines.length.toDouble() : v * (_lines.length + 0.6);
    final line = Paint()..color = onColor.withValues(alpha: 0.85);
    final prompt = Paint()..color = onColor;
    var cursorAt = const Offset(16, 32);
    for (var i = 0; i < _lines.length; i++) {
      final y = 32.0 + i * 12;
      canvas.drawPath(_chevrons[i], prompt);
      final f = (typed - i).clamp(0.0, 1.0);
      if (f <= 0) break;
      final w = 84 * _lines[i] * f;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(22, y + 1, w, 4),
          const Radius.circular(2),
        ),
        line,
      );
      cursorAt = Offset(22 + w + 3, y);
    }

    // Cursor: always on at rest; blinks at ~2.5 Hz while active.
    final on = v == 0 || ((v * 12).floor() % 2 == 0);
    if (on) {
      canvas.drawRect(
        Rect.fromLTWH(cursorAt.dx, cursorAt.dy - 1, 5, 8),
        Paint()..color = onColor,
      );
    }
  }
}

/// 3×3 grid of chamfered blocks with an empty bottom-right slot; while
/// active the accent block slides into the gap and back (sliding puzzle).
class _BlocksPainter extends _ArtPainter {
  _BlocksPainter(super.t, super.color, super.onColor, super.accent);

  static const _cell = 24.0;
  static const _gap = 6.0;
  static const _span = _cell * 3 + _gap * 2;
  static const _origin = Offset(60 - _span / 2, 45 - _span / 2);
  static const _outlined = {2, 6};
  static const _moving = 7;
  static const _empty = 8;

  static Offset _slot(int i) =>
      _origin + Offset((i % 3) * (_cell + _gap), (i ~/ 3) * (_cell + _gap));

  static Path _chamfered(Rect r, double c) => Path()
    ..moveTo(r.left + c, r.top)
    ..lineTo(r.right, r.top)
    ..lineTo(r.right, r.bottom - c)
    ..lineTo(r.right - c, r.bottom)
    ..lineTo(r.left, r.bottom)
    ..lineTo(r.left, r.top + c)
    ..close();

  @override
  void draw(Canvas canvas, double v) {
    final fill = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < 9; i++) {
      if (i == _moving || i == _empty) continue;
      final r = _slot(i) & const Size(_cell, _cell);
      if (_outlined.contains(i)) {
        canvas.drawPath(_chamfered(r.deflate(0.75), 5), stroke);
      } else {
        canvas.drawPath(_chamfered(r, 6), fill);
      }
    }

    // Ping-pong into the empty slot and back, eased, once per loop.
    final tri = v < 0.5 ? v * 2 : (1 - v) * 2;
    final f = Curves.easeInOutCubic.transform(tri);
    final pos = Offset.lerp(_slot(_moving), _slot(_empty), f)!;
    final mr = pos & const Size(_cell, _cell);
    canvas.drawPath(_chamfered(mr, 6), Paint()..color = accent);
    canvas.drawRect(
      Rect.fromLTWH(mr.left + 8, mr.top + 9, 8, 6),
      Paint()..color = onColor,
    );
  }
}

/// Audio waveform bars; the phase scrolls while active.
class _WaveformPainter extends _ArtPainter {
  _WaveformPainter(super.t, super.color, super.onColor, super.accent);

  static const _count = 19;

  @override
  void draw(Canvas canvas, double v) {
    final paint = Paint()..color = color;
    const left = 8.0;
    const step = 104.0 / _count;
    final phase = v * math.pi * 2;
    for (var i = 0; i < _count; i++) {
      final x = left + i * step + step / 2;
      final a =
          math.sin(i * 0.62 + phase) * 0.55 +
          math.sin(i * 1.7 - phase * 2) * 0.3 +
          0.15;
      final env = math.sin(math.pi * (i + 0.5) / _count); // taper at ends
      final h = (8 + 62 * a.abs() * env).clamp(6.0, 72.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, 45), width: step * 0.55, height: h),
          const Radius.circular(2),
        ),
        i == _count ~/ 2 ? (Paint()..color = accent) : paint,
      );
    }
    // Baseline.
    canvas.drawRect(
      const Rect.fromLTWH(4, 44.5, 112, 1),
      Paint()..color = color.withValues(alpha: 0.35),
    );
  }
}

/// Ascending bar chart with a trend line; bars breathe while active.
class _BarsPainter extends _ArtPainter {
  _BarsPainter(super.t, super.color, super.onColor, super.accent);

  static const _heights = [0.28, 0.42, 0.36, 0.58, 0.7, 0.9];

  @override
  void draw(Canvas canvas, double v) {
    final paint = Paint()..color = color;
    const base = 82.0;
    const left = 12.0;
    const w = 12.0;
    const gap = 6.0;
    final pts = <Offset>[];
    for (var i = 0; i < _heights.length; i++) {
      final wobble = v == 0 ? 0.0 : math.sin(v * math.pi * 2 + i * 0.9) * 0.08;
      final h = 70 * (_heights[i] + wobble).clamp(0.1, 1.0);
      final x = left + i * (w + gap);
      final r = Rect.fromLTWH(x, base - h, w, h);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          r,
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        i == _heights.length - 1 ? (Paint()..color = accent) : paint,
      );
      pts.add(Offset(x + w / 2, base - h - 6));
    }
    canvas.drawRect(
      const Rect.fromLTWH(6, base, 108, 1.5),
      Paint()..color = color,
    );
    final trend = Path()..addPolygon(pts, false);
    canvas.drawPath(
      trend,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round,
    );
    for (final pt in pts) {
      canvas.drawCircle(pt, 2.2, Paint()..color = color);
    }
  }
}
