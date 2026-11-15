import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../core/max_width.dart';
import '../core/router.dart';
import '../data/cv.dart';
import '../data/models.dart';
import '../data/sections.dart';
import '../shell/site_shell.dart';
import '../theme/colors.dart';
import '../theme/motion.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/art/polygon_cluster.dart';
import '../widgets/art/project_art.dart';
import '../widgets/motion/block_decode_text.dart';
import '../widgets/motion/horizontal_rail.dart';
import '../widgets/motion/pinned_stage.dart';
import '../widgets/motion/reveal.dart';
import '../widgets/motion/story_progress.dart';
import '../widgets/ui/bento_card.dart';
import '../widgets/ui/chip_tag.dart';
import '../widgets/ui/fit_height.dart';
import '../widgets/ui/pill_button.dart';
import '../widgets/ui/section_header.dart';
import 'see_all.dart';

const _eyebrow = 'PROJECTS';
const _titleLines = ['THINGS', "I'VE BUILT"];

/// Home row 6 — "THINGS / I'VE BUILT" (chapter 3).
///
/// Desktop ([BuildContext.pinEnabled]): P9c handoff inside a 2.0 vh
/// [PinnedStage]. The `periwinkle` band rises with a straight top edge behind
/// the lilac centre card (the card the Achievements chapter ended on); the
/// card tilts isometric with two ghost outlines, holds, then untilts with
/// the P13 title printed on it; the side cards rise (P10). Reports
/// `StoryProgress` chapter 2 and hides the indicator once the chapter ends.
///
/// Mobile / tablet / reduced motion: a hard periwinkle band with the P13
/// headline and the cards stacked (tablet: 2-up rows) with [Reveal].
///
/// Content: `Cv.recentProjects(3)` + a 4th "See all projects" card.
class ProjectsChapter extends StatelessWidget {
  const ProjectsChapter({super.key});

  @override
  Widget build(BuildContext context) {
    if (context.pinEnabled) {
      return PinnedStage(
        scrollLength: 2.0,
        onProgress: (p) {
          final story = StoryProgressScope.maybeOf(context);
          if (story == null) return;
          story.report(2, p);
          story.visible = p < 0.999;
        },
        builder: (context, progress) => _PinnedProjects(progress: progress),
      );
    }
    return const _StackedProjects();
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Desktop: P9c pinned stage
// ─────────────────────────────────────────────────────────────────────────

/// Progress phases (no hold longer than 0.15).
abstract final class _P {
  static const bandBegin = 0.0;
  static const bandEnd = 0.30;
  static const tiltBegin = 0.04;
  static const tiltEnd = 0.30;
  // 0.30–0.42: isometric hold (title starts decoding on the card at 0.30).
  static const titleAt = 0.30;
  static const untiltBegin = 0.42;
  static const untiltEnd = 0.66;
  static const riseBegin = 0.50;
  static const riseEnd = 0.90;
  // 0.90–1.00: bento hold.
}

const _deg = math.pi / 180;

class _PinnedProjects extends StatefulWidget {
  const _PinnedProjects({required this.progress});

  final ValueListenable<double> progress;

  @override
  State<_PinnedProjects> createState() => _PinnedProjectsState();
}

class _PinnedProjectsState extends State<_PinnedProjects> {
  /// Fires the P13 title decode once the card is isometric.
  final ValueNotifier<bool> _titleStart = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_onProgress);
    _onProgress();
  }

  @override
  void didUpdateWidget(covariant _PinnedProjects oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      oldWidget.progress.removeListener(_onProgress);
      widget.progress.addListener(_onProgress);
    }
  }

  void _onProgress() {
    if (!_titleStart.value && widget.progress.value >= _P.titleAt) {
      _titleStart.value = true;
    }
  }

  @override
  void dispose() {
    widget.progress.removeListener(_onProgress);
    _titleStart.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = widget.progress;
    final projects = Cv.recentProjects(3);
    final top = SiteShell.headerClearance(context);

    return ColoredBox(
      color: p.canvas,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            const gap = Space.s16;
            final bentoW = math.min(1040.0, w - 96);
            // Wider side columns (project cards carry the text), narrower
            // centre column (title + art): flex 1.2 / 0.8 / 1.2.
            final unit = (bentoW - gap * 2) / 3.2;
            final side = unit * 1.2;
            final mid = unit * 0.8;
            final left = (w - bentoW) / 2;
            final bentoTop = top;
            final bentoH = math.max(240.0, h - bentoTop - Space.s40);
            final half = (bentoH - gap) / 2;
            final centre = Rect.fromLTWH(
              left + side + gap,
              bentoTop,
              mid,
              bentoH,
            );
            final rightX = left + side + mid + gap * 2;
            final sides = [
              Rect.fromLTWH(left, bentoTop, side, half),
              Rect.fromLTWH(left, bentoTop + half + gap, side, half),
              Rect.fromLTWH(rightX, bentoTop, side, half),
              Rect.fromLTWH(rightX, bentoTop + half + gap, side, half),
            ];

            return Stack(
              children: [
                // Periwinkle band rising with a straight top edge.
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _BandPainter(
                        progress: progress,
                        color: p.periwinkle,
                      ),
                    ),
                  ),
                ),
                // P10 side cards.
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: progress,
                      builder: (context, child) {
                        final r = seg(progress.value, _P.riseBegin, _P.riseEnd);
                        return Transform.translate(
                          offset: Offset(0, h * Motion.riseFromVh * (1 - r)),
                          child: child,
                        );
                      },
                      child: Stack(
                        children: [
                          for (var i = 0; i < projects.length && i < 3; i++)
                            Positioned.fromRect(
                              rect: sides[i],
                              child: _ProjectCard(
                                key: ValueKey('card:projects:$i'),
                                project: projects[i],
                                tone: CardTone.surface,
                                fixedHeight: true,
                              ),
                            ),
                          Positioned.fromRect(
                            rect: sides[3],
                            child: const _SeeAllCard(
                              key: ValueKey('card:projects:see-all'),
                              fixedHeight: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // P9c centre card: isometric tilt + ghosts, title on card.
                Positioned.fromRect(
                  rect: centre,
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: progress,
                      builder: (context, child) {
                        final k = _tiltAmount(progress.value);
                        return Transform(
                          alignment: Alignment.center,
                          transform: _isoMatrix(k),
                          child: child,
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _GhostPainter(
                                progress: progress,
                                color: p.onDeep,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: _TitleCard(start: _titleStart),
                          ),
                        ],
                      ),
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

/// 0 → 1 (tilt in), hold, 1 → 0 (untilt).
double _tiltAmount(double v) {
  final tin = seg(v, _P.tiltBegin, _P.tiltEnd, Curves.easeInOutCubic);
  final tout = seg(v, _P.untiltBegin, _P.untiltEnd, Curves.easeInOutCubic);
  return tin * (1 - tout);
}

/// `rotateX(50°)·rotateZ(−30°)`, scale 1.1 at k = 1.
Matrix4 _isoMatrix(double k) {
  if (k == 0) return Matrix4.identity();
  final s = 1 + 0.1 * k;
  return Matrix4.identity()
    ..setEntry(3, 2, 0.0008)
    ..rotateX(50 * _deg * k)
    ..rotateZ(-30 * _deg * k)
    ..scaleByDouble(s, s, 1, 1);
}

class _BandPainter extends CustomPainter {
  _BandPainter({required this.progress, required this.color})
    : super(repaint: progress);

  final ValueListenable<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = seg(progress.value, _P.bandBegin, _P.bandEnd, Motion.expoOut);
    if (r <= 0) return;
    final top = size.height * (1 - r);
    canvas.drawRect(
      Rect.fromLTRB(0, top, size.width, size.height),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.progress != progress || old.color != color;
}

/// Two 1.5 px outlines behind the card, offset 10 / 20 px, opacity 0.7 / 0.4,
/// collapsing with the tilt.
class _GhostPainter extends CustomPainter {
  _GhostPainter({required this.progress, required this.color})
    : super(repaint: progress);

  final ValueListenable<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = _tiltAmount(progress.value);
    if (k <= 0.001) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final (offset, alpha) in const [(20.0, 0.4), (10.0, 0.7)]) {
      paint.color = color.withValues(alpha: alpha * k);
      final d = offset * k;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset(d, d) & size,
          const Radius.circular(Radii.card),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GhostPainter old) =>
      old.progress != progress || old.color != color;
}

/// The centre card with the chapter title printed on it.
class _TitleCard extends StatelessWidget {
  const _TitleCard({required this.start});

  final ValueListenable<bool> start;

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    return BentoCard(
      tone: CardTone.lilac,
      child: Builder(
        builder: (context) {
          final tones = BentoCard.tonesOf(context);
          return Stack(
            children: [
              // Art fills the card below the printed title.
              const Positioned(
                left: 0,
                right: 0,
                top: 144,
                bottom: 0,
                child: PolygonCluster(seed: 23),
              ),
              Positioned.fill(
                child: FitHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '// $_eyebrow',
                        style: t.label.copyWith(color: tones.accent),
                      ),
                      const SizedBox(height: Space.s16),
                      Semantics(
                        header: true,
                        child: BlockDecodeText(
                          _titleLines,
                          style: t.displayL,
                          color: tones.fg,
                          start: start,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Mobile / tablet / reduced motion
// ─────────────────────────────────────────────────────────────────────────

class _StackedProjects extends StatelessWidget {
  const _StackedProjects();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bp = context.bp;
    final gap = Layout.gridGap(bp);
    final projects = Cv.recentProjects(3);

    final cards = <Widget>[
      for (var i = 0; i < projects.length; i++)
        _ProjectCard(
          key: ValueKey('card:projects:$i'),
          project: projects[i],
          tone: CardTone.surface,
        ),
      const _SeeAllCard(key: ValueKey('card:projects:see-all')),
    ];

    final Widget body;
    if (context.isMobile) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            Reveal(index: i, child: cards[i]),
          ],
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < cards.length; i += 2) ...[
            if (i > 0) SizedBox(height: gap),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = i; j < i + 2 && j < cards.length; j++) ...[
                    if (j > i) SizedBox(width: gap),
                    Expanded(
                      child: Reveal(index: j, child: cards[j]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    }

    return ColoredBox(
      color: p.periwinkle,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Layout.sectionPadding(bp)),
        child: MaxWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionHeader(
                eyebrow: _eyebrow,
                titleLines: _titleLines,
                onAccent: true,
              ),
              SizedBox(height: Layout.headerGap(bp)),
              body,
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Cards
// ─────────────────────────────────────────────────────────────────────────

/// Project card: mono period, title, ProjectArtView (reacts on hover / tap),
/// summary verbatim, tags. [fixedHeight] → content guarded by [FitHeight].
class _ProjectCard extends StatefulWidget {
  const _ProjectCard({
    super.key,
    required this.project,
    required this.tone,
    this.fixedHeight = false,
  });

  final Project project;
  final CardTone tone;
  final bool fixedHeight;

  @override
  State<_ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<_ProjectCard> {
  bool _active = false;

  void _set(bool v) {
    if (v != _active) setState(() => _active = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final pr = widget.project;
    final tones = widget.tone.resolve(context.palette);
    final pointer = context.pointerEffects;
    final artW = context.isMobile ? 72.0 : 104.0;
    final vGap = context.isMobile ? Space.s12 : Space.s16;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pr.period.monoLabel,
                    style: t.label.copyWith(color: tones.fgMuted),
                  ),
                  const SizedBox(height: Space.s8),
                  Text(pr.title, style: t.headingM.copyWith(color: tones.fg)),
                ],
              ),
            ),
            const SizedBox(width: Space.s12),
            SizedBox(
              width: artW,
              height: artW * 0.75,
              child: ProjectArtView(pr.art, active: _active),
            ),
          ],
        ),
        SizedBox(height: vGap),
        Text(pr.summary, style: t.body.copyWith(color: tones.fg)),
        SizedBox(height: vGap),
        Wrap(
          spacing: Space.s8,
          runSpacing: Space.s8,
          children: [for (final tag in pr.tags) ChipTag(tag, mono: true)],
        ),
      ],
    );

    Widget card = BentoCard(
      tone: widget.tone,
      onTap: pointer ? null : () => _set(!_active),
      child: widget.fixedHeight ? FitHeight(child: content) : content,
    );
    if (pointer) {
      card = MouseRegion(
        onEnter: (_) => _set(true),
        onExit: (_) => _set(false),
        child: card,
      );
    }
    return card;
  }
}

/// The 4th side slot on Home: routes to /projects.
class _SeeAllCard extends StatelessWidget {
  const _SeeAllCard({super.key, this.fixedHeight = false});

  final bool fixedHeight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('// ALL PROJECTS', style: t.label.copyWith(color: p.violet300)),
        const SizedBox(height: Space.s16),
        const SizedBox(width: 96, height: 96, child: PolygonCluster(seed: 5)),
        const SizedBox(height: Space.s20),
        const SeeAllButton(
          section: SiteSection.projects,
          label: 'See all projects',
          variant: PillVariant.white,
        ),
      ],
    );
    return BentoCard(
      tone: CardTone.deep,
      onTap: () => AppNav.go(context, SiteSection.projects),
      child: fixedHeight
          ? FitHeight(alignment: Alignment.bottomLeft, child: content)
          : content,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Sub-page rail
// ─────────────────────────────────────────────────────────────────────────

/// /projects: 4 project cards, newest first.
class ProjectsRail extends StatelessWidget {
  const ProjectsRail({super.key});

  @override
  Widget build(BuildContext context) {
    final items = Cv.recentProjects(Cv.projects.length);
    const tones = [
      CardTone.lilac,
      CardTone.periwinkle,
      CardTone.mint,
      CardTone.peach,
    ];
    return HorizontalRail(
      itemCount: items.length,
      semanticLabel: 'Projects',
      itemBuilder: (context, i) => _ProjectCard(
        key: ValueKey('card:projects:$i'),
        project: items[i],
        tone: tones[i % tones.length],
        fixedHeight: true,
      ),
    );
  }
}
