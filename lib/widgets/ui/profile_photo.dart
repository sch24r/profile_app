import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../theme/spacing.dart';
import '../art/monogram.dart';
import 'chamfer_box.dart';

/// Asset paths for the user photo.
abstract final class ProfileAssets {
  static const photo = 'assets/images/profile.jpg';
}

/// The user's photo (the mascot's role), clipped to a chamfered octagon.
///
/// Decodes at a bucketed `cacheWidth` (256 px steps × devicePixelRatio) so
/// size animations don't trigger re-decodes; `gaplessPlayback` avoids
/// flashes. Missing/broken asset → [MonogramArt] fallback.
/// [chamfered] = false → plain rectangle (callers may clip themselves).
class ProfilePhoto extends StatelessWidget {
  const ProfilePhoto({
    super.key,
    this.width,
    this.height,
    this.chamfer = Radii.chamfer,
    this.chamfered = true,
    this.semanticLabel = 'Photo of Marchello Putra Ramadhan',
  });

  final double? width;
  final double? height;
  final double chamfer;
  final bool chamfered;
  final String semanticLabel;

  static int _bucket(double logicalWidth, double dpr) {
    final px = (logicalWidth.isFinite ? logicalWidth : 512) * dpr;
    final b = ((px / 256).ceil() * 256).clamp(256, 2048);
    return b;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    Widget image = LayoutBuilder(
      builder: (context, c) {
        final w = width ?? (c.hasBoundedWidth ? c.maxWidth : 512.0);
        return Image.asset(
          ProfileAssets.photo,
          width: width,
          height: height,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.3),
          cacheWidth: _bucket(w, dpr),
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stack) =>
              MonogramArt(bg: p.deep, fg: p.violet300, accent: p.flare),
        );
      },
    );

    image = ColoredBox(color: p.tint100, child: image);
    if (width != null || height != null) {
      image = SizedBox(width: width, height: height, child: image);
    }
    if (chamfered) {
      image = ClipPath(
        clipper: ChamferClipper(size: chamfer, corners: allCorners),
        child: image,
      );
    }
    return Semantics(image: true, label: semanticLabel, child: image);
  }
}
