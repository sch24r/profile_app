import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../core/theme_controller.dart';
import 'round_icon_button.dart';
import 'segmented_pill.dart';

/// Light / Dark / System switch bound to [ThemeScope].
///
/// Full: a [SegmentedPill] (P25 thumb; the app's 200 ms palette lerp does P20).
/// [compact]: a single round icon button that cycles
/// Light → Dark → System (nav bar).
class ThemeSwitch extends StatelessWidget {
  const ThemeSwitch({super.key, this.compact = false, this.onDark = false});

  final bool compact;

  /// Colour set for dark bands.
  final bool onDark;

  static const _order = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

  static String _label(ThemeMode m) => switch (m) {
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
    ThemeMode.system => 'System',
  };

  static IconData _icon(ThemeMode m) => switch (m) {
    ThemeMode.light => Icons.light_mode_outlined,
    ThemeMode.dark => Icons.dark_mode_outlined,
    ThemeMode.system => Icons.brightness_auto_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);
    final mode = controller.value;

    if (compact) {
      final next = _order[(_order.indexOf(mode) + 1) % _order.length];
      return RoundIconButton(
        icon: _icon(mode),
        tooltip: 'Theme: ${_label(mode)}. Switch to ${_label(next)}',
        variant: onDark ? RoundVariant.onDark : RoundVariant.neutral,
        size: context.isDesktop ? 40 : 44,
        onPressed: () => controller.set(next),
      );
    }

    return SegmentedPill<ThemeMode>(
      options: [for (final m in _order) (m, _label(m))],
      value: mode,
      onChanged: controller.set,
      dense: true,
      onDark: onDark,
    );
  }
}
