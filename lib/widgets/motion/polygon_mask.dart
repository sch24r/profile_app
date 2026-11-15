import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';
import 'in_view.dart';

// ─────────────────────────────────────────────────────────────────────────
// Geometry
// ─────────────────────────────────────────────────────────────────────────

/// The signature window, in units of its own width (x ∈ [-0.5, 0.5]),
/// listed clockwise around the anchor point (0, 0), y pointing down.
///
/// An angular octagon: square top-left shoulder, a V-notch at the top
/// centre, a chamfered top-right corner, a long inward diagonal on the right,
/// a narrower foot, a chamfered bottom-left corner and one stepped notch on
/// the left edge. The anchor sits just under the V so the window grows out of
/// the notch.
const List<Offset> _kUnitPolygon = [
  Offset(-0.50, -0.40), // top-left shoulder
  Offset(-0.13, -0.40),
  Offset(0.00, -0.25), // V-notch
  Offset(0.13, -0.40),
  Offset(0.34, -0.40),
  Offset(0.50, -0.24), // top-right chamfer
  Offset(0.50, 0.06),
  Offset(0.28, 0.28), // inward diagonal
  Offset(0.28, 0.38),
  Offset(-0.20, 0.38), // foot
  Offset(-0.36, 0.22), // bottom-left chamfer
  Offset(-0.36, -0.08),
  Offset(-0.50, -0.08), // stepped notch
];

/// Scale buckets per e-fold of log-scale. 8000 → 0.0125 % relative step,
/// i.e. well under a pixel even at full zoom.
const double _kBucketsPerE = 8000;
const int _kCacheSize = 12;

@immutable
class _ShapeKey {
  const _ShapeKey(this.size, this.bucket, this.center);
  final Size size;
  final int bucket;
  final Offset center;

  @override
  bool operator ==(Object other) =>
      other is _ShapeKey &&
      other.size == size &&
      other.bucket == bucket &&
      other.center == center;

  @override
  int get hashCode => Object.hash(size, bucket, center);
}

/// Small LRU of built paths (insertion-ordered map; hits move to the end).
final LinkedHashMap<_ShapeKey, Path> _shapeCache =
    LinkedHashMap<_ShapeKey, Path>();

/// The signature angular octagon with a V-notch at top and one stepped notch,
/// centred at [center] (defaults to the middle of [size]).
///
/// `scale == 1.0` means the shape's width equals the diagonal of [size]; at
/// the end of the zoom (`polygonZoomScale(1) == 2.6`) the window covers any
/// aspect ratio from tall phones to ultrawide. Paths are cached per
/// (size, scale bucket, center); treat the returned path as read-only.
Path polygonShape(Size size, double scale, {Offset? center}) {
  final c = center ?? size.center(Offset.zero);
  final bucket = (math.log(math.max(scale, 1e-6)) * _kBucketsPerE).round();
  final key = _ShapeKey(size, bucket, c);

  final hit = _shapeCache.remove(key);
  if (hit != null) {
    _shapeCache[key] = hit;
    return hit;
  }

  final diagonal = math.sqrt(
    size.width * size.width + size.height * size.height,
  );
  final w = math.exp(bucket / _kBucketsPerE) * diagonal;
  final path = Path()
    ..addPolygon([
      for (final p in _kUnitPolygon) Offset(c.dx + p.dx * w, c.dy + p.dy * w),
    ], true);

  _shapeCache[key] = path;
  if (_shapeCache.length > _kCacheSize) {
    _shapeCache.remove(_shapeCache.keys.first);
  }
  return path;
}

final double _lnMin = math.log(0.04);
final double _lnMax = math.log(2.6);

/// Log-space zoom: `s = exp(lerp(ln 0.04, ln 2.6, Motion.zoom.transform(t)))`.
/// [t] is clamped to 0..1.
double polygonZoomScale(double t) {
  final k = Motion.zoom.transform(t.clamp(0.0, 1.0));
  return math.exp(_lnMin + (_lnMax - _lnMin) * k);
}

// ─────────────────────────────────────────────────────────────────────────
// Clipper + curtain painter (P1)
// ─────────────────────────────────────────────────────────────────────────

/// Clips to the zooming polygon window. `t == 0` → nothing visible,
/// `t >= 1` → the whole box (no polygon edges left at rest).
class PolygonClipper extends CustomClipper<Path> {
  PolygonClipper({required this.t, this.center, super.reclip});

  /// Zoom progress 0..1 (linear; the zoom curve is applied internally).
  final double t;

  /// Anchor of the window in local coordinates (default: box centre).
  final Offset? center;

  @override
  Path getClip(Size size) {
    if (t <= 0) return Path();
    if (t >= 1) return Path()..addRect(Offset.zero & size);
    return polygonShape(size, polygonZoomScale(t), center: center);
  }

  @override
  bool shouldReclip(PolygonClipper oldClipper) =>
      oldClipper.t != t || oldClipper.center != center;
}

/// Paints an overlay of [color] covering the box EXCEPT a polygon window that
/// zooms open with [t] (0 = fully covered, 1 = fully open).
class PolygonCurtainPainter extends CustomPainter {
  PolygonCurtainPainter({
    required this.t,
    required this.color,
    this.center,
    super.repaint,
  });

  final double t;
  final Color color;
  final Offset? center;

  final Paint _paint = Paint()..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    if (t >= 1) return;
    final rect = Offset.zero & size;
    _paint.color = color;
    if (t <= 0) {
      canvas.drawRect(rect, _paint);
      return;
    }
    // Even-odd: the rect minus the window. Cheaper than Path.combine.
    final curtain = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addPath(
        polygonShape(size, polygonZoomScale(t), center: center),
        Offset.zero,
      );
    canvas
      ..save()
      ..clipRect(rect)
      ..drawPath(curtain, _paint)
      ..restore();
  }

  @override
  bool shouldRepaint(PolygonCurtainPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.color != color ||
      oldDelegate.center != center;
}

// ─────────────────────────────────────────────────────────────────────────
// P24 scroll-in reveal
// ─────────────────────────────────────────────────────────────────────────

/// P24 one-shot scroll-in reveal: [child] is clipped by a growing polygon from
/// [origin] when [fraction] (default 30 %) of it is in view.
/// Motion.polyReveal, expoOut in log-scale space. Once finished the clip is
/// switched off (Clip.none) so the child renders bare. reduceMotion → child.
class PolygonReveal extends StatefulWidget {
  const PolygonReveal({
    super.key,
    required this.child,
    this.origin = const Alignment(-0.4, 0),
    this.fraction = 0.3,
    this.duration = Motion.polyReveal,
  });

  final Widget child;

  /// Where the window grows from, relative to the child's box.
  final Alignment origin;

  /// Visible fraction that triggers the reveal.
  final double fraction;
  final Duration duration;

  @override
  State<PolygonReveal> createState() => _PolygonRevealState();
}

class _PolygonRevealState extends State<PolygonReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener(_onStatus);
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.expoOut,
  );
  bool _triggered = false;
  bool _done = false;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_done) {
      setState(() => _done = true);
    }
  }

  void _trigger() {
    if (_triggered) return;
    _triggered = true;
    // Called from a build callback: start on the next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(PolygonReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = widget.duration;
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return widget.child;
    return InView(
      fraction: widget.fraction,
      builder: (context, inView, child) {
        if (inView) _trigger();
        return ClipPath(
          clipper: _RevealClipper(_curve, widget.origin),
          clipBehavior: _done ? Clip.none : Clip.antiAlias,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Reclips on every animation tick (paint only, no rebuild).
class _RevealClipper extends CustomClipper<Path> {
  _RevealClipper(this.animation, this.origin) : super(reclip: animation);

  final Animation<double> animation;
  final Alignment origin;

  static final double _lnEnd = math.log(3.0);

  @override
  Path getClip(Size size) {
    final v = animation.value;
    if (v <= 0) return Path();
    if (v >= 1) return Path()..addRect(Offset.zero & size);
    final s = math.exp(_lnMin + (_lnEnd - _lnMin) * v);
    return polygonShape(size, s, center: origin.withinRect(Offset.zero & size));
  }

  @override
  bool shouldReclip(_RevealClipper oldClipper) =>
      oldClipper.animation != animation || oldClipper.origin != origin;
}
