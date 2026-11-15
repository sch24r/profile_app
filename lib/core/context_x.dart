import 'package:flutter/material.dart';

import '../theme/colors.dart';
import 'breakpoints.dart';

export 'breakpoints.dart';

extension ContextX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  /// Global reduced-motion gate. When true every primitive must jump to its
  /// end state, loops stop, intro is skipped, nothing pins.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// Pinned/scrubbed desktop stages (P7–P10, P9c) are enabled.
  bool get pinEnabled => isDesktop && !reduceMotion;

  /// Pointer effects (tilt, look, hover accordion) — desktop only.
  bool get pointerEffects => isDesktop && !reduceMotion;
}
