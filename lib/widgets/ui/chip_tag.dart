import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';

/// Visual recipes for [ChipTag].
///
/// * [outline] — transparent, 1 px border in the ambient text colour.
/// * [filled] — `tint100` fill, ink text (on canvas / surface).
/// * [onDark] — translucent border, `onDeep` text (deep panels).
/// * [onAccent] — white chip with fixed dark ink (pastel cards; the P12 chip).
enum ChipStyle { outline, filled, onDark, onAccent }

/// Small pill tag (skills, scopes, dates). Static — no hover motion.
class ChipTag extends StatelessWidget {
  const ChipTag(
    this.label, {
    super.key,
    this.style = ChipStyle.outline,
    this.dot,
    this.mono = false,
  });

  final String label;
  final ChipStyle style;

  /// Optional 6 px leading dot in this colour (decorative).
  final Color? dot;

  /// Mono uppercase label ([AppType.label]) instead of the sans caption.
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final ambient = DefaultTextStyle.of(context).style.color ?? p.ink;

    final (Color? fill, Color fg, Color? border) = switch (style) {
      ChipStyle.outline => (null, ambient, ambient.withValues(alpha: 0.28)),
      ChipStyle.filled => (p.tint100, p.ink, null),
      ChipStyle.onDark => (
        p.onDeep.withValues(alpha: 0.06),
        p.onDeep,
        p.onDeep.withValues(alpha: 0.3),
      ),
      ChipStyle.onAccent => (p.onDeep, p.onAccent, null),
    };

    final textStyle = (mono ? t.label : t.caption.copyWith(height: 1.2))
        .copyWith(color: fg, fontWeight: mono ? null : FontWeight.w600);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: border == null ? null : Border.all(color: border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.s12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              DecoratedBox(
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                child: const SizedBox.square(dimension: 6),
              ),
              const SizedBox(width: Space.s8),
            ],
            Flexible(
              child: Text(
                mono ? label.toUpperCase() : label,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
