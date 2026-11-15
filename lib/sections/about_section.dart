import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../data/cv.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/art/polygon_cluster.dart';
import '../widgets/motion/horizontal_rail.dart';
import '../widgets/ui/bento_card.dart';
import '../widgets/ui/fit_height.dart';
import '../widgets/ui/proficiency_meter.dart';
import '../widgets/ui/profile_photo.dart';

/// About › Profile tab body: a [HorizontalRail] of the profile card (photo +
/// `Cv.profile`), the three interest cards and the languages card.
class ProfileRail extends StatelessWidget {
  const ProfileRail({super.key});

  /// Profile card + interests + languages.
  static int get itemCount => 1 + Cv.interests.length + 1;

  @override
  Widget build(BuildContext context) {
    final interests = Cv.interests.length;
    return HorizontalRail(
      itemCount: itemCount,
      semanticLabel: 'Profile',
      itemBuilder: (context, i) {
        if (i == 0) {
          return const ProfileCard(key: ValueKey('card:profile:0'));
        }
        if (i <= interests) {
          return InterestCard(
            key: ValueKey('card:interests:${i - 1}'),
            index: i - 1,
            fill: true,
          );
        }
        return const LanguagesCard(
          key: ValueKey('card:languages:0'),
          fill: true,
        );
      },
    );
  }
}

/// Card tone per interest (CV order): Cyber Security deep, System
/// Administration lilac, Web App Development periwinkle.
CardTone interestTone(int index) => switch (index) {
  0 => CardTone.deep,
  1 => CardTone.lilac,
  _ => CardTone.periwinkle,
};

/// Mono eyebrow used at the top of the About cards.
class _CardLabel extends StatelessWidget {
  const _CardLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tones = BentoCard.tonesOf(context);
    return Text(
      text.toUpperCase(),
      style: AppType.of(context).label.copyWith(color: tones.fgMuted),
    );
  }
}

/// Fixed-size card body: decoration art bottom-right (decorative, outside the
/// fit guard) and [content] scaled down only if it would overflow.
class _FilledBody extends StatelessWidget {
  const _FilledBody({required this.content, this.seed});

  final Widget content;
  final int? seed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tones = BentoCard.tonesOf(context);
    return LayoutBuilder(
      builder: (context, c) {
        final art = seed == null
            ? 0.0
            : math.min(c.maxWidth, c.maxHeight) * 0.42;
        return Stack(
          fit: StackFit.expand,
          children: [
            if (art >= 48)
              Positioned(
                right: -Space.s8,
                bottom: -Space.s8,
                width: art,
                height: art,
                child: ExcludeSemantics(
                  child: PolygonCluster(
                    seed: seed!,
                    colors: tones.fill == p.deep
                        ? [p.violet400, p.primary, p.violet300]
                        : [p.violet300, p.violet400, p.tint200],
                  ),
                ),
              ),
            FitHeight(child: content),
          ],
        );
      },
    );
  }
}

/// One CV interest group: title + CV text verbatim.
///
/// [fill] = true → sized by its parent (rail / pinned bento card), content
/// guarded by [FitHeight] with a decorative polygon cluster; false → intrinsic
/// height (Home mobile / tablet stacks).
class InterestCard extends StatelessWidget {
  const InterestCard({super.key, required this.index, this.fill = false});

  final int index;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final group = Cv.interests[index];
    final content = _InterestContent(index: index);
    return Semantics(
      container: true,
      label: 'Interest: ${group.title}',
      child: BentoCard(
        tone: interestTone(index),
        child: fill
            ? _FilledBody(content: content, seed: 11 + index * 7)
            : content,
      ),
    );
  }
}

class _InterestContent extends StatelessWidget {
  const _InterestContent({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final tones = BentoCard.tonesOf(context);
    final group = Cv.interests[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CardLabel('// Interest 0${index + 1}'),
        const SizedBox(height: Space.s12),
        Text(group.title, style: t.headingM.copyWith(color: tones.fg)),
        const SizedBox(height: Space.s8),
        Text(group.items, style: t.body.copyWith(color: tones.fg)),
      ],
    );
  }
}

/// Languages (mint): one row per CV language — name, [ProficiencyMeter] and
/// the CV proficiency label.
class LanguagesCard extends StatelessWidget {
  const LanguagesCard({super.key, this.fill = false});

  final bool fill;

  @override
  Widget build(BuildContext context) {
    const content = _LanguagesContent();
    return Semantics(
      container: true,
      label: 'Languages',
      child: BentoCard(
        tone: CardTone.mint,
        child: fill ? const _FilledBody(content: content) : content,
      ),
    );
  }
}

class _LanguagesContent extends StatelessWidget {
  const _LanguagesContent();

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final tones = BentoCard.tonesOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _CardLabel('// Languages'),
        for (final lang in Cv.languages) ...[
          const SizedBox(height: Space.s16),
          Text(lang.name, style: t.title.copyWith(color: tones.fg)),
          const SizedBox(height: Space.s8),
          ProficiencyMeter(
            level: lang.level,
            color: tones.accent,
            trackColor: tones.fg.withValues(alpha: 0.14),
          ),
          const SizedBox(height: Space.s4),
          Text(lang.label, style: t.caption.copyWith(color: tones.fgMuted)),
        ],
      ],
    );
  }
}

/// Profile card for the About › Profile rail: [ProfilePhoto] (monogram
/// fallback) + `Cv.profile` verbatim. Fills its parent.
class ProfileCard extends StatelessWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    return Semantics(
      container: true,
      label: 'Profile',
      child: BentoCard(
        child: LayoutBuilder(
          builder: (context, c) {
            final tones = BentoCard.tonesOf(context);
            // Short mobile rail cards: a small avatar keeps the paragraph
            // at (nearly) full size inside the fit guard.
            final photo = context.isMobile
                ? 48.0
                : math.min(
                    c.maxWidth * 0.34,
                    c.maxHeight.isFinite ? c.maxHeight * 0.3 : 140.0,
                  );
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ProfilePhoto(
                      width: photo,
                      height: photo * 1.15,
                      chamfer: Radii.chamferSmall,
                    ),
                    const SizedBox(width: Space.s16),
                    const Expanded(child: _CardLabel('// Profile')),
                  ],
                ),
                SizedBox(height: context.isMobile ? Space.s12 : Space.s16),
                Text(
                  Cv.profile,
                  style: (context.isMobile ? t.caption : t.body).copyWith(
                    color: tones.fg,
                    height: context.isMobile ? 1.4 : 1.5,
                  ),
                ),
              ],
            );
            return FitHeight(child: content);
          },
        ),
      ),
    );
  }
}
