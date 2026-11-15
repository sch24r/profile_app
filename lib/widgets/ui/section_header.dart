import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../motion/block_decode_text.dart';

/// Section heading block: mono eyebrow (`// EDUCATION`), P13 block-decode
/// title lines ([AppType.displayL]) and an optional muted lead paragraph.
///
/// [trailing] (e.g. a "See all" pill) sits bottom-right of the title on
/// tablet/desktop when left-aligned, and below the lead otherwise.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.eyebrow,
    required this.titleLines,
    this.lead,
    this.align = CrossAxisAlignment.start,
    this.onDark = false,
    this.onAccent = false,
    this.trailing,
    this.titleStyle,
  });

  /// Eyebrow text; `// ` is prefixed if missing, rendered uppercase.
  final String eyebrow;
  final List<String> titleLines;
  final String? lead;
  final CrossAxisAlignment align;

  /// Use the on-deep colour set (dark bands).
  final bool onDark;

  /// Use the on-accent colour set (periwinkle/mint/peach pastel bands).
  final bool onAccent;
  final Widget? trailing;

  /// Overrides the title style (colour still defaults per [onDark]).
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final centered = align == CrossAxisAlignment.center;
    final textAlign = switch (align) {
      CrossAxisAlignment.center => TextAlign.center,
      CrossAxisAlignment.end => TextAlign.end,
      _ => TextAlign.start,
    };

    final Color eyebrowColor;
    final Color titleColor;
    final Color leadColor;
    if (onAccent) {
      eyebrowColor = p.onAccentMuted;
      titleColor = p.onAccent;
      leadColor = p.onAccentMuted;
    } else if (onDark) {
      eyebrowColor = p.violet300;
      titleColor = p.onDeep;
      leadColor = p.onDeepMuted;
    } else {
      eyebrowColor = p.primary;
      titleColor = p.ink;
      leadColor = p.inkMuted;
    }

    final eb = eyebrow.trimLeft().startsWith('//') ? eyebrow : '// $eyebrow';
    final title = Semantics(
      header: true,
      child: BlockDecodeText(
        titleLines,
        style: (titleStyle ?? t.displayL).copyWith(
          color: titleStyle?.color ?? titleColor,
        ),
        textAlign: textAlign,
      ),
    );

    final sideTrailing = trailing != null && !centered && !context.isMobile;

    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          eb.toUpperCase(),
          style: t.label.copyWith(color: eyebrowColor),
          textAlign: textAlign,
        ),
        const SizedBox(height: Space.s16),
        if (sideTrailing)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: title),
              const SizedBox(width: Space.s24),
              trailing!,
            ],
          )
        else
          title,
        if (lead != null) ...[
          const SizedBox(height: Space.s20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              lead!,
              style: t.bodyL.copyWith(color: leadColor),
              textAlign: textAlign,
            ),
          ),
        ],
        if (trailing != null && !sideTrailing) ...[
          const SizedBox(height: Space.s24),
          trailing!,
        ],
      ],
    );
  }
}
