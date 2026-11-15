import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../theme/spacing.dart';
import 'pressable.dart';

/// Fill recipes for [RoundIconButton].
enum RoundVariant { ink, neutral, onDark }

/// Flat circular icon button (menu, close ✕, theme cycle).
///
/// * [RoundVariant.ink] — ink circle (the compact-nav menu button).
/// * [RoundVariant.neutral] — light grey-lilac circle (the menu ✕).
/// * [RoundVariant.onDark] — translucent white circle for dark bands.
///
/// The hit area is at least [Layout.minTouch] on touch layouts even when the
/// visual circle is smaller. Press scales to 0.94; keyboard focus draws a ring.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.variant = RoundVariant.ink,
    this.size = 48,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  /// Tooltip text, also used as the semantics label.
  final String tooltip;
  final RoundVariant variant;

  /// Visual diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (Color fill, Color fg, Color ring) = switch (variant) {
      RoundVariant.ink => (p.ink, p.surface, p.primary),
      RoundVariant.neutral => (p.hoverPill, p.ink, p.primary),
      RoundVariant.onDark => (
        p.onDeep.withValues(alpha: 0.14),
        p.onDeep,
        p.violet300,
      ),
    };

    Widget circle = SizedBox.square(
      dimension: size,
      child: DecoratedBox(
        decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
        child: Center(
          child: Icon(icon, size: size * 0.42, color: fg),
        ),
      ),
    );
    if (onPressed == null) circle = Opacity(opacity: 0.45, child: circle);

    // Pad the hit area up to the minimum touch target on touch layouts.
    final hit = context.isDesktop
        ? size
        : (size < Layout.minTouch ? Layout.minTouch : size);
    if (hit > size) {
      circle = SizedBox.square(
        dimension: hit,
        child: Center(child: circle),
      );
    }

    return Pressable(
      onTap: onPressed,
      circle: true,
      pressScale: 0.94,
      ringColor: ring,
      ringGap: hit > size ? 3 - (hit - size) / 2 : 3,
      tooltip: tooltip,
      semanticLabel: tooltip,
      excludeChildSemantics: true,
      child: circle,
    );
  }
}
