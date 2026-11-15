import 'package:flutter/material.dart';

import '../../data/models.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'chip_tag.dart';

/// Ordinal rank block for an [Achievement]:
///
/// ```
/// 01ST
/// / 473 TEAMS
/// [INTERNATIONAL]
/// ```
///
/// The rank is a two-digit display numeral with a small suffix; unranked
/// qualifications show "QUALIFIED". Colour defaults to the ambient
/// `DefaultTextStyle` colour (so it adapts to the enclosing [BentoCard]).
class RankBadge extends StatelessWidget {
  const RankBadge({
    super.key,
    required this.achievement,
    this.large = false,
    this.color,
  });

  final Achievement achievement;

  /// Larger numeral (chapter centre card).
  final bool large;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final a = achievement;
    final fg = color ?? DefaultTextStyle.of(context).style.color;
    final numeral = (large ? t.stat : t.displayM).copyWith(color: fg);
    final numeralSize = numeral.fontSize ?? 40;

    final Widget headline;
    if (a.isRanked) {
      final digits = a.rank!.toString().padLeft(2, '0');
      final suffix = a.ordinal.replaceAll(RegExp(r'[0-9]'), '').toUpperCase();
      headline = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(digits, style: numeral),
          const SizedBox(width: 2),
          Padding(
            padding: EdgeInsets.only(top: numeralSize * 0.08),
            child: Text(
              suffix,
              style: numeral.copyWith(
                fontSize: numeralSize * 0.38,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      );
    } else {
      headline = Text(
        'QUALIFIED',
        style: (large ? t.displayM : t.displayS).copyWith(color: fg),
      );
    }

    final field = a.field;
    final mono = t.label.copyWith(color: fg?.withValues(alpha: 0.72));

    return Semantics(
      label: a.outcome,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: headline,
            ),
            if (field != null) ...[
              const SizedBox(height: Space.s8),
              Text('/ $field TEAMS', style: mono),
            ],
            const SizedBox(height: Space.s12),
            DefaultTextStyle.merge(
              style: TextStyle(color: fg),
              child: ChipTag(
                a.scope == Scope.international ? 'International' : 'National',
                mono: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
