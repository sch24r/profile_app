import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../core/max_width.dart';
import '../data/cv.dart';
import '../data/models.dart';
import '../data/sections.dart';
import '../theme/colors.dart';
import '../theme/motion.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/motion/horizontal_rail.dart';
import '../widgets/motion/marquee.dart';
import '../widgets/ui/bento_card.dart';
import '../widgets/ui/chamfer_box.dart';
import '../widgets/ui/chip_tag.dart';
import '../widgets/ui/fit_height.dart';
import '../widgets/ui/pill_button.dart';
import '../widgets/ui/section_header.dart';
import 'see_all.dart';

/// Home row 9 — the Skills preview *is* the ticker (P21): a `deep` band with
/// a 45° chamfered top-left corner, a header with "See all" → /skills, and
/// [Marquee] rows of outlined tiles from [Cv.tickerItems].
///
/// Desktop: 2 rows in opposite directions at [Motion.marqueeStrip] (the items
/// are split between the rows, so no tile text is in both). Mobile / tablet:
/// 1 row at [Motion.marqueeStripMobile]. Every Marquee is ViewportGate'd and
/// static under reduced motion; repeated copies are excluded from semantics.
class SkillsTicker extends StatelessWidget {
  const SkillsTicker({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bp = context.bp;
    final desktop = context.isDesktop;
    const items = Cv.tickerItems;
    final half = (items.length / 2).ceil();

    Widget row(List<String> labels, {bool reverse = false}) => Marquee(
      speed: desktop ? Motion.marqueeStrip : Motion.marqueeStripMobile,
      reverse: reverse,
      gap: Space.s12,
      children: [for (final label in labels) _TickerTile(label)],
    );

    return ChamferBox(
      key: const ValueKey('skills-ticker'),
      color: p.deep,
      corners: const {Corner.topLeft},
      padding: EdgeInsets.symmetric(vertical: Layout.sectionPadding(bp)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const MaxWidth(
            child: SectionHeader(
              eyebrow: 'SKILLS',
              titleLines: ['TOOLS OF', 'THE TRADE'],
              onDark: true,
              trailing: SeeAllButton(
                section: SiteSection.skills,
                variant: PillVariant.outlineOnDark,
              ),
            ),
          ),
          SizedBox(height: Layout.headerGap(bp)),
          if (desktop) ...[
            row(items.sublist(0, half)),
            const SizedBox(height: Space.s16),
            row(items.sublist(half), reverse: true),
          ] else
            row(items),
        ],
      ),
    );
  }
}

/// Outlined ticker tile: 1 px violet300 @ 40 %, radius 8, mono label.
class _TickerTile extends StatelessWidget {
  const _TickerTile(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.xs),
        border: Border.all(color: p.violet300.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.isMobile ? Space.s16 : Space.s20,
          vertical: context.isMobile ? Space.s8 : Space.s12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: p.violet300,
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: 6),
            ),
            const SizedBox(width: Space.s8),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: t.mono.copyWith(color: p.onDeep),
            ),
          ],
        ),
      ),
    );
  }
}

/// /skills body: the 5 skill groups as rail cards of [ChipTag]s
/// (Programming Languages 14, Databases 3, Frameworks 5, Softwares 13,
/// Operating Systems 3).
class SkillsRail extends StatelessWidget {
  const SkillsRail({super.key});

  static const _tones = [
    CardTone.lilac,
    CardTone.periwinkle,
    CardTone.mint,
    CardTone.peach,
    CardTone.surface,
  ];

  @override
  Widget build(BuildContext context) {
    const groups = Cv.skills;
    return HorizontalRail(
      itemCount: groups.length,
      semanticLabel: 'Skill groups',
      itemBuilder: (context, i) => _SkillGroupCard(
        key: ValueKey('card:skills:$i'),
        group: groups[i],
        tone: _tones[i % _tones.length],
      ),
    );
  }
}

class _SkillGroupCard extends StatelessWidget {
  const _SkillGroupCard({super.key, required this.group, required this.tone});

  final SkillGroup group;
  final CardTone tone;

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final tones = tone.resolve(context.palette);
    final chipStyle = tone == CardTone.surface
        ? ChipStyle.filled
        : ChipStyle.onAccent;
    final count = group.items.length;
    return BentoCard(
      tone: tone,
      child: _FillColumn(
        top: [
          Text(group.title, style: t.headingM.copyWith(color: tones.fg)),
          const SizedBox(height: Space.s16),
          Wrap(
            spacing: Space.s8,
            runSpacing: Space.s8,
            children: [
              for (final item in group.items) ChipTag(item, style: chipStyle),
            ],
          ),
        ],
        bottom: [
          const SizedBox(height: Space.s20),
          Semantics(
            label: '$count ${count == 1 ? 'item' : 'items'}',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  count.toString().padLeft(2, '0'),
                  style: t.displayM.copyWith(color: tones.fg),
                ),
                const SizedBox(width: Space.s8),
                Text(
                  count == 1 ? 'ITEM' : 'ITEMS',
                  style: t.label.copyWith(color: tones.fgMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fixed-height card body: [top] at the top and [bottom] pinned to the bottom
/// of the available height, guarded by [FitHeight] (scales down instead of
/// overflowing). Children must not use Expanded/Spacer vertically.
class _FillColumn extends StatelessWidget {
  const _FillColumn({required this.top, this.bottom = const []});

  final List<Widget> top;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => FitHeight(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: box.hasBoundedHeight ? box.maxHeight : 0.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: top,
              ),
              if (bottom.isNotEmpty)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: bottom,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
