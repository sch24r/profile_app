import 'package:flutter/widgets.dart';

import '../../theme/spacing.dart';

/// Box corners that can be cut at 45°.
enum Corner { topLeft, topRight, bottomRight, bottomLeft }

/// All four corners — the chamfered-octagon photo frame.
const Set<Corner> allCorners = {
  Corner.topLeft,
  Corner.topRight,
  Corner.bottomRight,
  Corner.bottomLeft,
};

/// Builds a rect path with 45° cuts of [size] on [corners]. The cut is
/// clamped to half the shorter side so it never self-intersects.
Path chamferPath(Rect r, double size, Set<Corner> corners) {
  final c = size.clamp(0.0, r.shortestSide / 2);
  double cut(Corner k) => corners.contains(k) ? c : 0.0;
  final tl = cut(Corner.topLeft);
  final tr = cut(Corner.topRight);
  final br = cut(Corner.bottomRight);
  final bl = cut(Corner.bottomLeft);
  return Path()
    ..moveTo(r.left + tl, r.top)
    ..lineTo(r.right - tr, r.top)
    ..lineTo(r.right, r.top + tr)
    ..lineTo(r.right, r.bottom - br)
    ..lineTo(r.right - br, r.bottom)
    ..lineTo(r.left + bl, r.bottom)
    ..lineTo(r.left, r.bottom - bl)
    ..lineTo(r.left, r.top + tl)
    ..close();
}

/// 45° chamfer clipper. The render object caches the clip until the size
/// changes or [shouldReclip] reports a different geometry.
class ChamferClipper extends CustomClipper<Path> {
  const ChamferClipper({
    this.size = Radii.chamfer,
    this.corners = const {Corner.topLeft},
  });

  final double size;
  final Set<Corner> corners;

  @override
  Path getClip(Size s) => chamferPath(Offset.zero & s, size, corners);

  @override
  bool shouldReclip(ChamferClipper oldClipper) =>
      oldClipper.size != size ||
      oldClipper.corners.length != corners.length ||
      !oldClipper.corners.containsAll(corners);
}

/// Flat [color] box with 45° chamfered [corners] (dark bands, backplates).
/// The child is clipped to the same shape (anti-aliased, no save layer).
class ChamferBox extends StatelessWidget {
  const ChamferBox({
    super.key,
    required this.child,
    required this.color,
    this.chamfer = Radii.chamfer,
    this.corners = const {Corner.topLeft},
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;
  final double chamfer;
  final Set<Corner> corners;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: ChamferClipper(size: chamfer, corners: corners),
      child: ColoredBox(
        color: color,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
