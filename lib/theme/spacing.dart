import 'package:flutter/widgets.dart';

import '../core/breakpoints.dart';

abstract final class Space {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0;
  static const s24 = 24.0;
  static const s32 = 32.0;
  static const s40 = 40.0;
  static const s48 = 48.0;
  static const s64 = 64.0;
  static const s80 = 80.0;
  static const s96 = 96.0;
  static const s128 = 128.0;
}

abstract final class Radii {
  static const xs = 8.0;
  static const card = 12.0; // bento cards (observed)
  static const md = 16.0;
  static const panel = 20.0; // nav bar, menu panel
  static const xl = 28.0;
  static const pill = 999.0;

  /// 45° chamfer size for dark bands / photo frame / backplates.
  static const chamfer = 28.0;
  static const chamferSmall = 14.0;
}

abstract final class Layout {
  static const maxContent = 1200.0;
  static const maxStage = 1280.0;
  static const minTouch = 48.0;
  static const headerHeightMobile = 72.0;
  static const headerHeightDesktop = 88.0;

  static double pagePadding(Bp bp) => switch (bp) {
    Bp.mobile => 20,
    Bp.tablet => 32,
    Bp.desktop => 48,
  };

  static double sectionPadding(Bp bp) => switch (bp) {
    Bp.mobile => 48,
    Bp.tablet => 64,
    Bp.desktop => 80,
  };

  static double headerGap(Bp bp) => switch (bp) {
    Bp.mobile => 32,
    Bp.tablet => 40,
    Bp.desktop => 56,
  };

  static double gridGap(Bp bp) => switch (bp) {
    Bp.mobile => 12,
    Bp.tablet => 16,
    Bp.desktop => 16,
  };

  static EdgeInsets page(Bp bp) =>
      EdgeInsets.symmetric(horizontal: pagePadding(bp));
}
