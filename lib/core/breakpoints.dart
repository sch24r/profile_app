import 'package:flutter/widgets.dart';

enum Bp { mobile, tablet, desktop }

abstract final class Breakpoints {
  static const tablet = 600.0;
  static const desktop = 1024.0;

  static Bp of(double width) => width >= desktop
      ? Bp.desktop
      : width >= tablet
      ? Bp.tablet
      : Bp.mobile;
}

extension BreakpointX on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  Bp get bp => Breakpoints.of(screenWidth);
  bool get isMobile => bp == Bp.mobile;
  bool get isTablet => bp == Bp.tablet;
  bool get isDesktop => bp == Bp.desktop;

  /// Fluid value between [min] (at 360 px wide) and [max] (at 1440 px wide).
  double fluid(double min, double max) {
    final t = ((screenWidth - 360) / (1440 - 360)).clamp(0.0, 1.0);
    return min + (max - min) * t;
  }
}
