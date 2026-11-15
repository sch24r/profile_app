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
import '../widgets/motion/reveal.dart';
import '../widgets/ui/bento_card.dart';
import '../widgets/ui/chip_tag.dart';
import '../widgets/ui/fit_height.dart';
import '../widgets/ui/section_header.dart';
import 'see_all.dart';

/// Home row 3: compact lilac band with the most recent school only
/// (`Cv.education.first`, ITS). No location line (it lives in the hero
/// toast); GPA shown statically. "See all" → About › Education.
class EducationPreview extends StatelessWidget {
  const EducationPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bp = context.bp;
    return ColoredBox(
      color: p.tint100,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Layout.sectionPadding(bp)),
        child: MaxWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionHeader(
                eyebrow: 'EDUCATION',
                titleLines: ['WHERE I', 'LEARN'],
                trailing: SeeAllButton(
                  section: SiteSection.about,
                  tab: 'education',
                ),
              ),
              SizedBox(height: Layout.headerGap(bp)),
              Reveal(
                child: _EducationPreviewCard(
                  key: const ValueKey('card:education:0'),
                  edu: Cv.education.first,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wide surface card on the lilac band: school details left, GPA right
/// (stacked on mobile).
class _EducationPreviewCard extends StatelessWidget {
  const _EducationPreviewCard({super.key, required this.edu});

  final Education edu;

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final tones = CardTone.surface.resolve(context.palette);
    final mobile = context.isMobile;

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _PeriodRow(edu: edu, tones: tones),
        const SizedBox(height: Space.s16),
        Text(edu.school, style: t.headingL.copyWith(color: tones.fg)),
        if (edu.department != null) ...[
          const SizedBox(height: Space.s8),
          Text(edu.department!, style: t.title.copyWith(color: tones.fgMuted)),
        ],
        const SizedBox(height: Space.s4),
        Text(edu.program, style: t.body.copyWith(color: tones.fg)),
      ],
    );

    final score = _Score(edu: edu, tones: tones, large: !mobile);

    return BentoCard(
      padding: EdgeInsets.all(mobile ? Space.s20 : Space.s32),
      child: mobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                details,
                const SizedBox(height: Space.s24),
                score,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: details),
                const SizedBox(width: Space.s32),
                score,
              ],
            ),
    );
  }
}

/// About › Education: both schools as rail cards (ITS, then SMA Negeri 2
/// Kediri) with every field, including location. Scores are static.
class EducationRail extends StatelessWidget {
  const EducationRail({super.key});

  static const _tones = [CardTone.lilac, CardTone.periwinkle];

  @override
  Widget build(BuildContext context) {
    const items = Cv.education;
    return HorizontalRail(
      itemCount: items.length,
      desktopPerView: 2,
      semanticLabel: 'Education',
      itemBuilder: (context, i) => _EducationRailCard(
        key: ValueKey('card:education:$i'),
        edu: items[i],
        tone: _tones[i % _tones.length],
      ),
    );
  }
}

class _EducationRailCard extends StatelessWidget {
  const _EducationRailCard({super.key, required this.edu, required this.tone});

  final Education edu;
  final CardTone tone;

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final tones = tone.resolve(context.palette);
    return BentoCard(
      tone: tone,
      child: _FillColumn(
        top: [
          _PeriodRow(edu: edu, tones: tones),
          const SizedBox(height: Space.s16),
          Text(edu.school, style: t.headingM.copyWith(color: tones.fg)),
          if (edu.department != null) ...[
            const SizedBox(height: Space.s8),
            Text(
              edu.department!,
              style: t.title.copyWith(color: tones.fgMuted),
            ),
          ],
          const SizedBox(height: Space.s4),
          Text(edu.program, style: t.body.copyWith(color: tones.fg)),
          const SizedBox(height: Space.s12),
          Row(
            children: [
              Icon(Icons.place_outlined, size: 16, color: tones.fgMuted),
              const SizedBox(width: Space.s4),
              Flexible(
                child: Text(
                  edu.location,
                  style: t.caption.copyWith(color: tones.fgMuted),
                ),
              ),
            ],
          ),
        ],
        bottom: [
          const SizedBox(height: Space.s16),
          _Score(edu: edu, tones: tones, large: false),
        ],
      ),
    );
  }
}

/// Mono period label + "Now" badge when current.
class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.edu, required this.tones});

  final Education edu;
  final ToneColors tones;

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    return Wrap(
      spacing: Space.s12,
      runSpacing: Space.s8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          edu.period.monoLabel,
          style: t.mono.copyWith(color: tones.fgMuted),
        ),
        if (edu.period.isCurrent)
          ChipTag('Now', style: ChipStyle.filled, dot: tones.accent),
      ],
    );
  }
}

/// Static score: mono label ("GPA") over the display value ("3.66/4.00").
class _Score extends StatelessWidget {
  const _Score({required this.edu, required this.tones, required this.large});

  final Education edu;
  final ToneColors tones;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    return Semantics(
      label: '${edu.scoreLabel} ${edu.scoreText}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            edu.scoreLabel.toUpperCase(),
            style: t.label.copyWith(color: tones.fgMuted),
          ),
          const SizedBox(height: Space.s4),
          Text(
            edu.scoreText,
            style: (large ? t.displayM : t.displayS).copyWith(color: tones.fg),
          ),
        ],
      ),
    );
  }
}

/// Fixed-height card body: [top] at the top and [bottom] pinned to the
/// bottom of the available height (no empty band in the middle of a tall
/// card), guarded by [FitHeight] so it scales down instead of overflowing.
/// Children must not use Expanded/Spacer vertically.
class _FillColumn extends StatelessWidget {
  const _FillColumn({required this.top, this.bottom = const []});

  final List<Widget> top;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final minHeight = box.hasBoundedHeight ? box.maxHeight : 0.0;
        return FitHeight(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
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
        );
      },
    );
  }
}
