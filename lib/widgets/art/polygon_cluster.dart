import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/context_x.dart';

/// Seeded cluster of flat triangle shards (a broken fan around the centre)
/// plus a few loose fragments and one `flare` spark.
///
/// Geometry is generated once per [seed] in unit space and cached; the
/// painter only scales it, so it is cheap to rebuild. Fills its constraints
/// (160×160 when unbounded). Static — no animation.
class PolygonCluster extends StatelessWidget {
  const PolygonCluster({super.key, this.seed = 7, this.colors});

  final int seed;

  /// Shard colours, cycled (default violet300 / violet400 / tint200).
  /// The spark always uses `palette.flare`.
  final List<Color>? colors;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cs = colors ?? [p.violet300, p.violet400, p.tint200];
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.hasBoundedWidth ? c.maxWidth : 160.0;
        final h = c.hasBoundedHeight ? c.maxHeight : w;
        return ExcludeSemantics(
          child: CustomPaint(
            size: Size(w, h),
            painter: _ClusterPainter(
              shards: _ClusterGeometry.of(seed),
              colors: cs,
              spark: p.flare,
            ),
          ),
        );
      },
    );
  }
}

class _Shard {
  const _Shard(this.a, this.b, this.c, this.colorIndex);
  final Offset a;
  final Offset b;
  final Offset c;
  final int colorIndex;
}

class _ClusterGeometry {
  _ClusterGeometry(this.shards, this.spark);
  final List<_Shard> shards;
  final _Shard spark;

  static final Map<int, _ClusterGeometry> _cache = {};

  /// Scaled shard paths (last entry = spark), cached for the last size.
  Size? _pathSize;
  List<Path> _paths = const [];

  List<Path> pathsFor(Size size) {
    if (size == _pathSize) return _paths;
    final side = math.min(size.width, size.height);
    final dx = (size.width - side) / 2;
    final dy = (size.height - side) / 2;
    Offset m(Offset o) => Offset(dx + o.dx * side, dy + o.dy * side);
    Path tri(_Shard s) => Path()..addPolygon([m(s.a), m(s.b), m(s.c)], true);
    _paths = [for (final s in shards) tri(s), tri(spark)];
    _pathSize = size;
    return _paths;
  }

  static _ClusterGeometry of(int seed) =>
      _cache.putIfAbsent(seed, () => _generate(seed));

  static _ClusterGeometry _generate(int seed) {
    final rnd = math.Random(seed);
    double r(double a, double b) => a + rnd.nextDouble() * (b - a);
    const center = Offset(0.5, 0.52);

    // Jittered ring around the centre; consecutive pairs form a fan.
    const n = 8;
    final start = r(0, math.pi * 2);
    final ring = <Offset>[];
    for (var i = 0; i < n; i++) {
      final ang = start + i * math.pi * 2 / n + r(-0.22, 0.22);
      final rad = r(0.26, 0.44);
      ring.add(center + Offset(math.cos(ang), math.sin(ang)) * rad);
    }

    final shards = <_Shard>[];
    final skip = rnd.nextInt(n);
    for (var i = 0; i < n; i++) {
      if (i == skip) continue;
      final a = ring[i];
      final b = ring[(i + 1) % n];
      // Push each shard outward along its mid-direction → visible gaps.
      final mid = (a + b) / 2 - center;
      final push = mid / mid.distance * r(0.0, 0.035);
      // Pull the apex a little off-centre so shards look broken.
      final apex = center + Offset(r(-0.04, 0.04), r(-0.04, 0.04));
      shards.add(_Shard(a + push, b + push, apex + push, rnd.nextInt(3)));
    }

    // Loose fragments outside the fan.
    for (var i = 0; i < 3; i++) {
      final ang = r(0, math.pi * 2);
      final o = center + Offset(math.cos(ang), math.sin(ang)) * r(0.38, 0.46);
      final s = r(0.04, 0.08);
      final rot = r(0, math.pi * 2);
      Offset v(double k) =>
          o + Offset(math.cos(rot + k), math.sin(rot + k)) * s;
      shards.add(_Shard(v(0), v(2.1), v(4.2), rnd.nextInt(3)));
    }

    // Spark: small sharp triangle near the top-right.
    final so = Offset(r(0.7, 0.82), r(0.12, 0.24));
    final spark = _Shard(
      so,
      so + const Offset(0.06, 0.025),
      so + const Offset(0.015, 0.07),
      0,
    );
    return _ClusterGeometry(shards, spark);
  }
}

class _ClusterPainter extends CustomPainter {
  _ClusterPainter({
    required this.shards,
    required this.colors,
    required this.spark,
  });

  final _ClusterGeometry shards;
  final List<Color> colors;
  final Color spark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || colors.isEmpty) return;
    // Uniform scale into a centred square so shards keep their angles.
    final paths = shards.pathsFor(size);
    final paint = Paint()..isAntiAlias = true;
    for (var i = 0; i < shards.shards.length; i++) {
      paint.color = colors[shards.shards[i].colorIndex % colors.length];
      canvas.drawPath(paths[i], paint);
    }
    paint.color = spark;
    canvas.drawPath(paths.last, paint);
  }

  @override
  bool shouldRepaint(_ClusterPainter old) =>
      old.shards != shards ||
      old.spark != spark ||
      !_sameColors(old.colors, colors);

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
