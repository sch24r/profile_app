import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../core/max_width.dart';
import '../data/cv.dart';
import '../data/models.dart';
import '../data/sections.dart';
import '../shell/site_shell.dart';
import '../theme/colors.dart';
import '../theme/motion.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/art/polygon_cluster.dart';
import '../widgets/motion/block_decode_text.dart';
import '../widgets/motion/horizontal_rail.dart';
import '../widgets/motion/in_view.dart';
import '../widgets/motion/pinned_stage.dart';
import '../widgets/motion/reveal.dart';
import '../widgets/motion/story_progress.dart';
import '../widgets/ui/bento_card.dart';
import '../widgets/ui/chip_tag.dart';
import '../widgets/ui/fit_height.dart';
import '../widgets/ui/pill_button.dart';
import '../widgets/ui/rank_badge.dart';
import '../widgets/ui/section_header.dart';
import 'see_all.dart';

const _eyebrow = 'ACHIEVEMENTS';
const _titleLines = ['CAPTURE', 'THE FLAG'];

/// Side-card tones, in podium order 1..4 (index 0 is the centre card).
const _sideTones = [
  CardTone.mint,
  CardTone.periwinkle,
  CardTone.peach,
  CardTone.surface,
];

/// Home row 5 — "CAPTURE / THE FLAG" (chapter 2).
///
/// Desktop ([BuildContext.pinEnabled]): P9b inside a 2.0 vh [PinnedStage]. A
/// `deep` full-bleed panel (the seam) carries the P13 headline at ~2.75×; as
/// the stage scrubs, the panel insets into the centre bento column while
/// washing to light, the title scales to 1× and cross-fades white → ink, the
/// centre card content cross-fades in and the four side cards rise (P10).
/// Reports `StoryProgress` chapter 1.
///
/// Mobile / tablet / reduced motion: a `deep` panel that insets to the page
/// padding and washes to light once (Motion.insetClip) when 35 % in view;
/// cards stacked (tablet: 2-up rows of equal height) with [Reveal].
///
/// Content: `Cv.podiumByRecency` — centre = GEMATIK V 2nd, sides = the other
/// four in order. Each card shows its team count once (via [RankBadge]).
class AchievementsChapter extends StatelessWidget {
  const AchievementsChapter({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.pinEnabled) {
      return PinnedStage(
        scrollLength: 2.0,
        onProgress: (p) => StoryProgressScope.maybeOf(context)?.report(1, p),
        builder: (context, progress) => _PinnedAchievements(progress: progress),
      );
    }
    return const _StackedAchievements();
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Desktop: P9b pinned stage
// ─────────────────────────────────────────────────────────────────────────

/// Progress phases (no hold longer than 0.15).
abstract final class _P {
  // 0.00–0.08: hold — the P13 headline reads on the deep panel.
  static const insetBegin = 0.08;
  static const insetEnd = 0.58;
  static const colorBegin = 0.22;
  static const colorEnd = 0.50;
  static const contentBegin = 0.48;
  static const contentEnd = 0.66;
  static const riseBegin = 0.40;
  static const riseEnd = 0.90;
  // 0.90–1.00: bento hold.
}

/// Stage geometry, computed once per layout.
@immutable
class _Geometry {
  factory _Geometry(Size size, double top, AppType t) {
    final w = size.width;
    final h = size.height;
    final titleFont = (w * 0.045).clamp(40.0, 64.0);
    final eyebrowH = (t.label.fontSize ?? 13) * 1.4;
    final titleH = titleFont * 0.92 * 2 + 8;
    final headerTop = top;
    final titleTop = headerTop + eyebrowH + Space.s8;
    final bentoTop = titleTop + titleH + Space.s24;
    const bottom = Space.s40;
    final bentoH = math.max(240.0, h - bentoTop - bottom);
    final bentoW = math.min(1040.0, w - 96);
    const gap = Space.s16;
    final col = (bentoW - gap * 2) / 3;
    final left = (w - bentoW) / 2;
    final half = (bentoH - gap) / 2;
    final centre = Rect.fromLTWH(left + col + gap, bentoTop, col, bentoH);
    final sides = [
      Rect.fromLTWH(left, bentoTop, col, half),
      Rect.fromLTWH(left, bentoTop + half + gap, col, half),
      Rect.fromLTWH(left + (col + gap) * 2, bentoTop, col, half),
      Rect.fromLTWH(left + (col + gap) * 2, bentoTop + half + gap, col, half),
    ];
    // Title starts centred in the viewport at ~2.75× (clamped to fit).
    final titleCentreY = titleTop + titleH / 2;
    final startScale = math.min(2.75, (h * 0.62) / titleH);
    return _Geometry._(
      size: size,
      titleFont: titleFont,
      headerTop: headerTop,
      titleTop: titleTop,
      titleH: titleH,
      bentoLeft: left,
      bentoWidth: bentoW,
      centre: centre,
      sides: sides,
      titleStartDy: h / 2 - titleCentreY,
      titleStartScale: startScale,
    );
  }

  const _Geometry._({
    required this.size,
    required this.titleFont,
    required this.headerTop,
    required this.titleTop,
    required this.titleH,
    required this.bentoLeft,
    required this.bentoWidth,
    required this.centre,
    required this.sides,
    required this.titleStartDy,
    required this.titleStartScale,
  });

  final Size size;
  final double titleFont;
  final double headerTop;
  final double titleTop;
  final double titleH;
  final double bentoLeft;
  final double bentoWidth;
  final Rect centre;
  final List<Rect> sides;
  final double titleStartDy;
  final double titleStartScale;
}

class _PinnedAchievements extends StatelessWidget {
  const _PinnedAchievements({required this.progress});

  final ValueListenable<double> progress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final podium = Cv.podiumByRecency;
    final top = SiteShell.headerClearance(context);

    return ColoredBox(
      color: p.canvas,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, c) {
            final g = _Geometry(c.biggest, top, t);
            final contentFade = _Seg(
              progress,
              _P.contentBegin,
              _P.contentEnd,
              Motion.sineOut,
            );
            return Stack(
              children: [
                // P9b panel: full-bleed deep → centre column, washing light.
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _InsetPanelPainter(
                        progress: progress,
                        target: g.centre,
                        from: p.deep,
                        to: p.tint100,
                      ),
                    ),
                  ),
                ),
                // Centre card content (cross-fades in on the washed panel).
                Positioned.fromRect(
                  rect: g.centre,
                  child: FadeTransition(
                    opacity: contentFade,
                    child: _CentreCard(
                      key: const ValueKey('card:podium:0'),
                      achievement: podium.first,
                      pinned: true,
                    ),
                  ),
                ),
                // P10: side cards rise together, linear, no fade.
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: progress,
                      builder: (context, child) {
                        final r = seg(progress.value, _P.riseBegin, _P.riseEnd);
                        return Transform.translate(
                          offset: Offset(
                            0,
                            g.size.height * Motion.riseFromVh * (1 - r),
                          ),
                          child: child,
                        );
                      },
                      child: Stack(
                        children: [
                          for (var i = 1; i < podium.length && i <= 4; i++)
                            Positioned.fromRect(
                              rect: g.sides[i - 1],
                              child: _PodiumCard(
                                key: ValueKey('card:podium:$i'),
                                achievement: podium[i],
                                tone: _sideTones[i - 1],
                                pinned: true,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Eyebrow + See all (arrive with the end layout).
                Positioned(
                  left: g.bentoLeft,
                  width: g.bentoWidth,
                  top: g.headerTop,
                  height: g.titleTop - g.headerTop + g.titleH,
                  child: FadeTransition(
                    opacity: contentFade,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            '// $_eyebrow',
                            style: t.label.copyWith(color: p.primary),
                          ),
                        ),
                        const Align(
                          alignment: Alignment.bottomRight,
                          child: SeeAllButton(
                            section: SiteSection.achievements,
                            tab: 'podium',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // P13 headline, scaled 2.75 → 1 and white → ink.
                Positioned(
                  left: 0,
                  right: 0,
                  top: g.titleTop,
                  height: g.titleH,
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: progress,
                      builder: (context, _) {
                        final v = progress.value;
                        final m = seg(
                          v,
                          _P.insetBegin,
                          _P.insetEnd,
                          Curves.easeInOutCubic,
                        );
                        final scale =
                            g.titleStartScale + (1 - g.titleStartScale) * m;
                        final dy = g.titleStartDy * (1 - m);
                        final color = Color.lerp(
                          p.onDeep,
                          p.ink,
                          seg(v, _P.colorBegin, _P.colorEnd, Motion.sineOut),
                        )!;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..translateByDouble(0, dy, 0, 1)
                            ..scaleByDouble(scale, scale, 1, 1),
                          child: Center(
                            child: Semantics(
                              header: true,
                              child: BlockDecodeText(
                                _titleLines,
                                style: t.displayL.copyWith(
                                  fontSize: g.titleFont,
                                ),
                                color: color,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Paints the P9b panel: an RRect lerping from the full stage (r 0) to
/// [target] (r 12), colour [from] → [to]. Repaints with [progress] only.
class _InsetPanelPainter extends CustomPainter {
  _InsetPanelPainter({
    required this.progress,
    required this.target,
    required this.from,
    required this.to,
  }) : super(repaint: progress);

  final ValueListenable<double> progress;
  final Rect target;
  final Color from;
  final Color to;

  @override
  void paint(Canvas canvas, Size size) {
    final v = progress.value;
    final m = seg(v, _P.insetBegin, _P.insetEnd, Curves.easeInOutCubic);
    final wash = seg(v, _P.colorBegin, _P.insetEnd, Motion.sineOut);
    final rect = Rect.lerp(Offset.zero & size, target, m)!;
    final r = Radius.circular(Radii.card * m);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, r),
      Paint()..color = Color.lerp(from, to, wash)!,
    );
  }

  @override
  bool shouldRepaint(_InsetPanelPainter old) =>
      old.progress != progress ||
      old.target != target ||
      old.from != from ||
      old.to != to;
}

// ─────────────────────────────────────────────────────────────────────────
// Mobile / tablet / reduced motion
// ─────────────────────────────────────────────────────────────────────────

class _StackedAchievements extends StatelessWidget {
  const _StackedAchievements();

  @override
  Widget build(BuildContext context) {
    final bp = context.bp;
    final podium = Cv.podiumByRecency;
    final columns = context.isMobile ? 1 : 2;
    final gap = Layout.gridGap(bp);

    final cards = <Widget>[
      Reveal(
        child: _CentreCard(
          key: const ValueKey('card:podium:0'),
          achievement: podium.first,
        ),
      ),
      SizedBox(height: gap),
      if (columns == 1)
        for (var i = 1; i < podium.length; i++) ...[
          Reveal(
            index: i,
            child: _PodiumCard(
              key: ValueKey('card:podium:$i'),
              achievement: podium[i],
              tone: _sideTones[(i - 1) % _sideTones.length],
            ),
          ),
          if (i < podium.length - 1) SizedBox(height: gap),
        ]
      else
        for (var i = 1; i < podium.length; i += 2) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = i; j < i + 2; j++) ...[
                  if (j > i) SizedBox(width: gap),
                  Expanded(
                    child: j < podium.length
                        ? Reveal(
                            index: j,
                            child: _PodiumCard(
                              key: ValueKey('card:podium:$j'),
                              achievement: podium[j],
                              tone: _sideTones[(j - 1) % _sideTones.length],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
          if (i + 2 < podium.length) SizedBox(height: gap),
        ],
    ];

    return _InsetPanelSection(
      cards: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: cards,
      ),
    );
  }
}

/// Deep panel that insets to the page padding (clip tween, not layout) and
/// washes to light once when 35 % in view. Reduced motion → end state.
class _InsetPanelSection extends StatelessWidget {
  const _InsetPanelSection({required this.cards});

  final Widget cards;

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return _InsetPanelFrame(t: 1, child: cards);
    return InView(
      child: cards,
      builder: (context, inView, child) => TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: inView ? 1 : 0),
        duration: Motion.insetClip,
        curve: Motion.expoOut,
        child: child,
        builder: (context, t, child) => _InsetPanelFrame(t: t, child: child!),
      ),
    );
  }
}

class _InsetPanelFrame extends StatelessWidget {
  const _InsetPanelFrame({required this.t, required this.child});

  final double t;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t2 = AppType.of(context);
    final bp = context.bp;
    final pad = Layout.pagePadding(bp);
    final light = t >= 0.5;
    return CustomPaint(
      painter: _MobilePanelPainter(
        t: t,
        inset: pad,
        color: Color.lerp(p.deep, p.tint100, t)!,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Layout.sectionPadding(bp)),
        child: MaxWidth(
          maxWidth: Layout.maxContent - Space.s32,
          padded: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: pad + Space.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SectionHeader(
                  eyebrow: _eyebrow,
                  titleLines: _titleLines,
                  onDark: !light,
                  titleStyle: t2.displayL.copyWith(
                    color: Color.lerp(p.onDeep, p.ink, t),
                  ),
                  trailing: SeeAllButton(
                    section: SiteSection.achievements,
                    tab: 'podium',
                    variant: light
                        ? PillVariant.outline
                        : PillVariant.outlineOnDark,
                  ),
                ),
                SizedBox(height: Layout.headerGap(bp)),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MobilePanelPainter extends CustomPainter {
  const _MobilePanelPainter({
    required this.t,
    required this.inset,
    required this.color,
  });

  final double t;
  final double inset;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final dx = inset * t;
    final rect = Rect.fromLTRB(dx, 0, size.width - dx, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(Radii.md * t)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_MobilePanelPainter old) =>
      old.t != t || old.inset != inset || old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────
// Home cards
// ─────────────────────────────────────────────────────────────────────────

/// Centre card: RankBadge (large, with team count + scope), event,
/// organiser, mono date. [pinned] → fixed height (FitHeight guard + art).
class _CentreCard extends StatelessWidget {
  const _CentreCard({
    super.key,
    required this.achievement,
    this.pinned = false,
  });

  final Achievement achievement;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final a = achievement;
    final content = Builder(
      builder: (context) {
        final tones = BentoCard.tonesOf(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(a.date.mono, style: t.label.copyWith(color: tones.fgMuted)),
            const SizedBox(height: Space.s16),
            RankBadge(achievement: a, large: true),
            const SizedBox(height: Space.s20),
            Text(a.event, style: t.headingL.copyWith(color: tones.fg)),
            const SizedBox(height: Space.s8),
            Text(a.organizer, style: t.body.copyWith(color: tones.fgMuted)),
          ],
        );
      },
    );

    if (!pinned) {
      return BentoCard(
        tone: CardTone.surface,
        width: double.infinity,
        child: content,
      );
    }
    return BentoCard(
      tone: CardTone.lilac,
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            right: 0,
            width: 140,
            height: 140,
            child: PolygonCluster(seed: 11),
          ),
          Positioned.fill(
            child: FitHeight(alignment: Alignment.bottomLeft, child: content),
          ),
        ],
      ),
    );
  }
}

/// Side card: RankBadge (with team count + scope), event, organiser, date.
class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    super.key,
    required this.achievement,
    required this.tone,
    this.pinned = false,
  });

  final Achievement achievement;
  final CardTone tone;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final a = achievement;
    final tones = tone.resolve(context.palette);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: RankBadge(achievement: a)),
            const SizedBox(width: Space.s12),
            Text(a.date.mono, style: t.label.copyWith(color: tones.fgMuted)),
          ],
        ),
        const SizedBox(height: Space.s16),
        Text(a.event, style: t.title.copyWith(color: tones.fg)),
        const SizedBox(height: Space.s4),
        Text(a.organizer, style: t.caption.copyWith(color: tones.fgMuted)),
      ],
    );
    return BentoCard(
      tone: tone,
      width: double.infinity,
      padding: const EdgeInsets.all(Space.s20),
      child: pinned ? FitHeight(child: content) : content,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Sub-page rails
// ─────────────────────────────────────────────────────────────────────────

/// Achievements › Podium: 5 result cards, newest first.
class PodiumRail extends StatelessWidget {
  const PodiumRail({super.key});

  @override
  Widget build(BuildContext context) {
    final items = Cv.podiumByRecency;
    return HorizontalRail(
      itemCount: items.length,
      semanticLabel: 'Podium results',
      itemBuilder: (context, i) => _ResultRailCard(
        key: ValueKey('card:podium:$i'),
        achievement: items[i],
        tone: i == 0 ? CardTone.lilac : _sideTones[(i - 1) % _sideTones.length],
      ),
    );
  }
}

/// Achievements › Qualifications: 3 cards.
class QualificationsRail extends StatelessWidget {
  const QualificationsRail({super.key});

  @override
  Widget build(BuildContext context) {
    final items = Cv.qualifications;
    const tones = [CardTone.surface, CardTone.lilac, CardTone.periwinkle];
    return HorizontalRail(
      itemCount: items.length,
      semanticLabel: 'Qualifications',
      itemBuilder: (context, i) => _ResultRailCard(
        key: ValueKey('card:qualifications:$i'),
        achievement: items[i],
        tone: tones[i % tones.length],
      ),
    );
  }
}

/// Rail card: scope chip + mono date, event, organiser, description and the
/// outcome sentence verbatim (which carries the rank and team count once).
class _ResultRailCard extends StatelessWidget {
  const _ResultRailCard({
    super.key,
    required this.achievement,
    required this.tone,
  });

  final Achievement achievement;
  final CardTone tone;

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final a = achievement;
    final tones = tone.resolve(context.palette);
    return BentoCard(
      tone: tone,
      padding: EdgeInsets.all(context.isMobile ? Space.s20 : Space.s24),
      child: FitHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Flexible(
                  child: ChipTag(
                    a.scope == Scope.international
                        ? 'International'
                        : 'National',
                    mono: true,
                  ),
                ),
                const SizedBox(width: Space.s12),
                Text(
                  a.date.mono,
                  style: t.label.copyWith(color: tones.fgMuted),
                ),
              ],
            ),
            const SizedBox(height: Space.s16),
            Text(a.event, style: t.headingM.copyWith(color: tones.fg)),
            const SizedBox(height: Space.s4),
            Text(a.organizer, style: t.caption.copyWith(color: tones.fgMuted)),
            const SizedBox(height: Space.s12),
            Text(a.description, style: t.body.copyWith(color: tones.fg)),
            const SizedBox(height: Space.s16),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: tones.accent, width: 3)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: Space.s12),
                child: Text(
                  a.outcome,
                  style: t.body.copyWith(
                    color: tones.fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────

/// Adapts a scrubbed progress listenable to an [Animation] over a
/// sub-interval (for FadeTransition etc. — paint-only updates).
class _Seg extends Animation<double> {
  _Seg(this.source, this.begin, this.end, [this.curve = Curves.linear]);

  final ValueListenable<double> source;
  final double begin;
  final double end;
  final Curve curve;

  @override
  double get value => seg(source.value, begin, end, curve);

  @override
  AnimationStatus get status => AnimationStatus.forward;

  @override
  void addListener(VoidCallback listener) => source.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => source.removeListener(listener);

  @override
  void addStatusListener(AnimationStatusListener listener) {}

  @override
  void removeStatusListener(AnimationStatusListener listener) {}
}
