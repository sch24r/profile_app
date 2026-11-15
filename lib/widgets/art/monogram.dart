import 'package:flutter/widgets.dart';

import '../../core/context_x.dart';

/// "MR" polygon monogram — original angular block letters built from quads
/// and triangles (no font), on a flat [bg] with one [accent] shard.
///
/// Fills its constraints (falls back to 160×160 when unbounded). Letter
/// geometry is defined once in a 116×80 design box and the scaled [Path]s
/// are cached per size.
class MonogramArt extends StatelessWidget {
  const MonogramArt({super.key, this.fg, this.bg, this.accent});

  /// Letter colour (default `palette.violet300`).
  final Color? fg;

  /// Background (default `palette.deep`).
  final Color? bg;

  /// Shard colour (default `palette.flare`).
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.hasBoundedWidth ? c.maxWidth : 160.0;
        final h = c.hasBoundedHeight ? c.maxHeight : w;
        return ExcludeSemantics(
          child: CustomPaint(
            size: Size(w, h),
            painter: MonogramPainter(
              fg: fg ?? p.violet300,
              bg: bg ?? p.deep,
              accent: accent ?? p.flare,
            ),
          ),
        );
      },
    );
  }
}

/// Paints the monogram. Public so splash-like surfaces can reuse it.
class MonogramPainter extends CustomPainter {
  MonogramPainter({required this.fg, required this.bg, required this.accent});

  final Color fg;
  final Color bg;
  final Color accent;

  // Design box 116 × 80.
  static const _boxW = 116.0;
  static const _boxH = 80.0;

  static const List<List<Offset>> _letters = [
    // M — left stem with a chamfered top-left.
    [Offset(0, 8), Offset(8, 0), Offset(16, 0), Offset(16, 80), Offset(0, 80)],
    // M — right stem with a chamfered top-right.
    [
      Offset(36, 0),
      Offset(44, 0),
      Offset(52, 8),
      Offset(52, 80),
      Offset(36, 80),
    ],
    // M — the V band between the stems.
    [
      Offset(16, 0),
      Offset(26, 26),
      Offset(36, 0),
      Offset(36, 22),
      Offset(26, 48),
      Offset(16, 22),
    ],
    // R — stem.
    [Offset(60, 0), Offset(76, 0), Offset(76, 80), Offset(60, 80)],
    // R — leg.
    [Offset(84, 44), Offset(100, 44), Offset(116, 80), Offset(100, 80)],
  ];

  // R — bowl (outer) with its counter (hole), filled even-odd.
  static const _bowl = [
    Offset(76, 0),
    Offset(102, 0),
    Offset(114, 12),
    Offset(114, 32),
    Offset(102, 44),
    Offset(76, 44),
  ];
  static const _counter = [
    Offset(76, 14),
    Offset(94, 14),
    Offset(98, 18),
    Offset(98, 26),
    Offset(94, 30),
    Offset(76, 30),
  ];

  // Accent shard under the M's notch.
  static const _shard = [Offset(19, 58), Offset(33, 58), Offset(26, 72)];

  static final Map<Size, ({Path letters, Path shard, Path backShard})> _cache =
      {};

  static ({Path letters, Path shard, Path backShard}) _paths(Size size) {
    final hit = _cache[size];
    if (hit != null) return hit;
    if (_cache.length > 24) _cache.clear();

    final s = (size.width * 0.58 / _boxW).clamp(0.0, size.height * 0.5 / _boxH);
    final dx = (size.width - _boxW * s) / 2;
    final dy = (size.height - _boxH * s) / 2;
    Offset m(Offset o) => Offset(dx + o.dx * s, dy + o.dy * s);
    Path poly(List<Offset> pts) =>
        Path()..addPolygon([for (final o in pts) m(o)], true);

    final letters = Path()..fillType = PathFillType.evenOdd;
    for (final l in _letters) {
      letters.addPath(poly(l), Offset.zero);
    }
    letters
      ..addPath(poly(_bowl), Offset.zero)
      ..addPath(poly(_counter), Offset.zero);

    // Large faint shard anchored bottom-right of the canvas.
    final back = Path()
      ..addPolygon([
        Offset(size.width, size.height * 0.42),
        Offset(size.width, size.height),
        Offset(size.width * 0.52, size.height),
      ], true);

    final r = (letters: letters, shard: poly(_shard), backShard: back);
    _cache[size] = r;
    return r;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final paths = _paths(size);
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    canvas.drawPath(
      paths.backShard,
      Paint()..color = fg.withValues(alpha: 0.12),
    );
    canvas.drawPath(paths.letters, Paint()..color = fg);
    canvas.drawPath(paths.shard, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(MonogramPainter old) =>
      old.fg != fg || old.bg != bg || old.accent != accent;
}
