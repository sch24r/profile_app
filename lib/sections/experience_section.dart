import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../core/max_width.dart';
import '../data/cv.dart';
import '../data/models.dart';
import '../data/sections.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/motion/horizontal_rail.dart';
import '../widgets/motion/sticky_story.dart';
import '../widgets/ui/bento_card.dart';
import '../widgets/ui/chamfer_box.dart';
import '../widgets/ui/chip_tag.dart';
import '../widgets/ui/fit_height.dart';
import '../widgets/ui/section_header.dart';
import 'see_all.dart';

/// Home row 4 — Work preview (P23 sticky story over the 2 most recent roles).
///
/// Each fact appears once: the role card visual holds org + dates, the item
/// holds role + bullets (verbatim).
class WorkPreview extends StatelessWidget {
  const WorkPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final bp = context.bp;
    final roles = Cv.recentOccupations(2);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Layout.sectionPadding(bp)),
      child: MaxWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionHeader(
              eyebrow: 'Experience',
              titleLines: ['WORK'],
              trailing: SeeAllButton(
                section: SiteSection.experience,
                tab: 'work',
              ),
            ),
            SizedBox(height: Layout.headerGap(bp)),
            StickyStory(
              items: [
                for (var i = 0; i < roles.length; i++)
                  _WorkStoryItem(
                    key: ValueKey('card:work:$i'),
                    experience: roles[i],
                  ),
              ],
              visualBuilder: (context, i) =>
                  _RoleVisual(experience: roles[i], index: i),
            ),
          ],
        ),
      ),
    );
  }
}

/// The P23 "role card": org + dates + mono badge on a violet chamfered
/// backplate whose chamfer corners swap per item.
class _RoleVisual extends StatelessWidget {
  const _RoleVisual({required this.experience, required this.index});

  final Experience experience;
  final int index;

  static const _offset = 14.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final even = index.isEven;
    final backCorners = even
        ? const {Corner.topLeft, Corner.bottomRight}
        : const {Corner.topRight, Corner.bottomLeft};
    final frontCorners = even
        ? const {Corner.topLeft}
        : const {Corner.topRight};
    return Stack(
      children: [
        Positioned(
          left: _offset,
          top: _offset,
          right: 0,
          bottom: 0,
          child: ChamferBox(
            color: p.violet400,
            corners: backCorners,
            child: const SizedBox.expand(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: _offset, bottom: _offset),
          child: ChamferBox(
            color: p.deep,
            corners: frontCorners,
            padding: EdgeInsets.all(context.isMobile ? Space.s24 : Space.s32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ChipTag(
                  'Role ${_two(index + 1)}',
                  style: ChipStyle.onDark,
                  mono: true,
                  dot: p.violet300,
                ),
                const SizedBox(height: Space.s24),
                Text(
                  experience.org,
                  style: t.headingL.copyWith(color: p.onDeep),
                ),
                const SizedBox(height: Space.s16),
                Text(
                  experience.period.monoLabel,
                  style: t.mono.copyWith(color: p.violet300),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkStoryItem extends StatelessWidget {
  const _WorkStoryItem({super.key, required this.experience});

  final Experience experience;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(experience.role, style: t.headingL.copyWith(color: p.ink)),
        const SizedBox(height: Space.s16),
        CvBullets(
          experience.bullets,
          style: t.bodyL.copyWith(color: p.inkMuted),
          dotColor: p.primary,
        ),
      ],
    );
  }
}

/// Experience › Work: the 4 occupations, newest first.
class WorkRail extends StatelessWidget {
  const WorkRail({super.key});

  @override
  Widget build(BuildContext context) {
    final roles = Cv.recentOccupations(4);
    return HorizontalRail(
      itemCount: roles.length,
      semanticLabel: 'Work',
      itemBuilder: (context, i) => ExperienceCard(
        key: ValueKey('card:work:$i'),
        experience: roles[i],
        tone: i.isEven ? CardTone.surface : CardTone.lilac,
      ),
    );
  }
}

/// Fixed-height rail card for an [Experience] (occupation or organization):
/// period, org, role, optional location, bullets (verbatim).
class ExperienceCard extends StatelessWidget {
  const ExperienceCard({
    super.key,
    required this.experience,
    this.tone = CardTone.surface,
    this.showLocation = true,
    this.fit = true,
  });

  final Experience experience;
  final CardTone tone;
  final bool showLocation;

  /// Wrap the content in [FitHeight] (fixed-height rail cards).
  final bool fit;

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final tones = tone.resolve(context.palette);
    final mobile = context.isMobile;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          experience.period.monoLabel,
          style: t.label.copyWith(color: tones.accent),
        ),
        const SizedBox(height: Space.s12),
        Text(
          experience.org,
          style: (mobile ? t.caption : t.title).copyWith(
            color: tones.fg,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Space.s8),
        Text(
          experience.role,
          style: (mobile ? t.title : t.headingM).copyWith(color: tones.fg),
        ),
        if (showLocation) ...[
          const SizedBox(height: Space.s8),
          Text(
            experience.location,
            style: t.caption.copyWith(color: tones.fgMuted),
          ),
        ],
        SizedBox(height: mobile ? Space.s12 : Space.s16),
        CvBullets(
          experience.bullets,
          style: t.body.copyWith(color: tones.fgMuted),
          dotColor: tones.accent,
        ),
      ],
    );
    return BentoCard(
      tone: tone,
      child: fit ? FitHeight(child: content) : content,
    );
  }
}

/// CV bullets, verbatim, each with a small square marker.
class CvBullets extends StatelessWidget {
  const CvBullets(
    this.bullets, {
    super.key,
    required this.style,
    required this.dotColor,
    this.spacing = Space.s8,
  });

  final List<String> bullets;
  final TextStyle style;
  final Color dotColor;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final fontSize = style.fontSize ?? 15;
    final lineH = fontSize * (style.height ?? 1.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < bullets.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: (lineH - 6) / 2),
                child: ColoredBox(
                  color: dotColor,
                  child: const SizedBox.square(dimension: 6),
                ),
              ),
              const SizedBox(width: Space.s12),
              Expanded(child: Text(bullets[i], style: style)),
            ],
          ),
        ],
      ],
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');
