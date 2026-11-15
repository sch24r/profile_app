import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../core/max_width.dart';
import '../core/router.dart';
import '../data/cv.dart';
import '../data/sections.dart';
import '../shell/site_shell.dart';
import '../theme/motion.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/art/logo_mark.dart';
import '../widgets/art/monogram.dart';
import '../widgets/motion/accordion_column.dart';
import '../widgets/motion/in_view.dart';
import '../widgets/motion/pinned_stage.dart';
import '../widgets/motion/reveal.dart';
import '../widgets/motion/story_progress.dart';
import '../widgets/motion/two_tone_text.dart';
import '../widgets/ui/bento_card.dart';
import '../widgets/ui/chip_tag.dart';
import '../widgets/ui/fit_height.dart';
import '../widgets/ui/pill_button.dart';
import '../widgets/ui/profile_photo.dart';
import '../widgets/ui/section_header.dart';
import '../widgets/ui/status_toast.dart';
import 'about_section.dart';
import 'see_all.dart';

/// About chapter title (spec §2.2).
const _chapterTitle = ['FINDING', "WHAT'S HIDDEN"];
const _heroEyebrow = '// PERSONAL PROFILE';
const _aboutEyebrow = 'ABOUT';

/// Home rows 1 + 2: the hero (P2–P5 via [IntroScope]) and the About chapter.
///
/// Desktop (`context.pinEnabled`): one [PinnedStage] of 2.6 viewport heights
/// running P7 card flip → P8 slanted wipe + two-tone title → P9a title
/// collapse into the card → P10 side cards rise (linear, from 0.75 vh) →
/// P11 hover accordion once p > 0.97. Reports chapter 0 progress to
/// [StoryProgressScope].
///
/// Mobile / tablet / reduced motion: static hero with the intro entrance,
/// then the About section — header, a one-shot rotateY card flip to the
/// profile card and the side cards (1 column on mobile, 2×2 on tablet) with
/// [Reveal].
class HeroStoryStage extends StatelessWidget {
  const HeroStoryStage({super.key});

  /// Stage length in viewport heights (plan: 2.6).
  static const scrollLength = 2.6;

  @override
  Widget build(BuildContext context) {
    if (context.pinEnabled) {
      final story = StoryProgressScope.maybeOf(context);
      return PinnedStage(
        scrollLength: scrollLength,
        onProgress: story == null ? null : (p) => story.report(0, p),
        builder: (context, progress) => _DesktopStage(progress: progress),
      );
    }
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [_HeroFallback(), _AboutFallback()],
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Animation helpers (paint-only, no CurvedAnimation leaks)
// ───────────────────────────────────────────────────────────────────────────

/// An [Animation] view of a [ValueListenable] mapped through [map].
class _MappedListenable extends Animation<double> {
  _MappedListenable(this.source, this.map);

  final ValueListenable<double> source;
  final double Function(double) map;

  @override
  double get value => map(source.value);

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

/// Intro value through [interval] then [Motion.expoOut].
double _introT(Animation<double> intro, Interval interval) =>
    Motion.expoOut.transform(interval.transform(intro.value));

// ───────────────────────────────────────────────────────────────────────────
// Hero pieces shared by desktop and fallback
// ───────────────────────────────────────────────────────────────────────────

/// Eyebrow, carved name (P2), one-line headline and the P3 CTA.
class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.lines, required this.maxNameHeight});

  final List<String> lines;
  final double maxNameHeight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final desktop = context.isDesktop;
    final headline = Text(
      Cv.headline,
      textAlign: TextAlign.center,
      maxLines: desktop ? 1 : 3,
      style: t.bodyL.copyWith(color: p.inkMuted),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _heroEyebrow,
          textAlign: TextAlign.center,
          style: t.label.copyWith(color: p.primary),
        ),
        const SizedBox(height: Space.s16),
        // P2: the name is the overlay colour, so it reads as carved out of it.
        Semantics(
          header: true,
          label: Cv.contact.name,
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxNameHeight),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final line in lines)
                      Text(
                        line,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        softWrap: false,
                        style: t.heroName.copyWith(color: p.display),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: desktop ? Space.s20 : Space.s16),
        if (desktop)
          FittedBox(fit: BoxFit.scaleDown, child: headline)
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: headline,
          ),
        SizedBox(height: desktop ? Space.s24 : Space.s20),
        const _HeroCta(),
      ],
    );
  }
}

/// P3: ink "Get in touch" pill morphing from a skewed brush quad.
class _HeroCta extends StatelessWidget {
  const _HeroCta();

  @override
  Widget build(BuildContext context) {
    final intro = IntroScope.of(context);
    final button = PillButton(
      label: 'Get in touch',
      icon: Icons.arrow_forward_rounded,
      onPressed: () => AppNav.go(context, SiteSection.contact),
    );
    return AnimatedBuilder(
      animation: intro,
      child: button,
      builder: (context, child) {
        final m = _introT(intro, IntroScope.ctaMorph);
        if (m >= 1) return child!;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.skewX(-0.35 * (1 - m))
            ..scaleByDouble(1.35 - 0.35 * m, 0.7 + 0.3 * m, 1, 1),
          child: child,
        );
      },
    );
  }
}

/// P5: photo rises +72 px → 0 over the intro's photo interval.
class _RisingPhoto extends StatelessWidget {
  const _RisingPhoto({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final intro = IntroScope.of(context);
    return AnimatedBuilder(
      animation: intro,
      child: ProfilePhoto(width: width, height: height),
      builder: (context, child) {
        final r = _introT(intro, IntroScope.photoRise);
        if (r >= 1) return child!;
        return Transform.translate(
          offset: Offset(0, Motion.avatarRiseFrom * (1 - r)),
          child: child,
        );
      },
    );
  }
}

/// StatusToast fading in with the intro toast interval.
class _HeroToast extends StatelessWidget {
  const _HeroToast();

  @override
  Widget build(BuildContext context) {
    final intro = IntroScope.of(context);
    return StatusToast(
      text: Cv.status,
      reveal: intro.isCompleted
          ? null
          : _IntervalAnimation(intro, IntroScope.toast),
    );
  }
}

/// [parent] through an [Interval] (no CurvedAnimation listener bookkeeping).
class _IntervalAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _IntervalAnimation(this.parent, this.interval);

  @override
  final Animation<double> parent;
  final Interval interval;

  @override
  double get value => interval.transform(parent.value);
}

// ───────────────────────────────────────────────────────────────────────────
// Mobile / tablet / reduced-motion fallback
// ───────────────────────────────────────────────────────────────────────────

class _HeroFallback extends StatelessWidget {
  const _HeroFallback();

  @override
  Widget build(BuildContext context) {
    final vw = context.screenWidth;
    final vh = context.screenHeight;
    final pad = Layout.pagePadding(context.bp);
    final clearance = SiteShell.headerClearance(context);
    final mobile = context.isMobile;

    // Photo: rises from the bottom centre, cropped at ~25 % of its height.
    final visible = (vh * (mobile ? 0.36 : 0.44)).clamp(180.0, 480.0);
    var photoH = visible / 0.75;
    var photoW = photoH * 0.8;
    final maxW = vw * (mobile ? 0.72 : 0.55);
    if (photoW > maxW) {
      photoW = maxW;
      photoH = photoW / 0.8;
    }

    return Stack(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: math.max(vh, 560)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(height: clearance),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: pad),
                child: _HeroCopy(
                  lines: Cv.nameLines,
                  maxNameHeight: math.max(120, vh * 0.34),
                ),
              ),
              SizedBox(
                height: math.min(visible, photoH),
                width: double.infinity,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    minHeight: photoH,
                    maxHeight: photoH,
                    maxWidth: photoW,
                    minWidth: photoW,
                    child: Padding(
                      padding: const EdgeInsets.only(top: Space.s24),
                      child: _RisingPhoto(width: photoW, height: photoH),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(left: pad, bottom: Space.s20, child: const _HeroToast()),
      ],
    );
  }
}

class _AboutFallback extends StatelessWidget {
  const _AboutFallback();

  @override
  Widget build(BuildContext context) {
    final bp = context.bp;
    final gap = Layout.gridGap(bp);
    final tablet = !context.isMobile;

    Widget side(int i) => i < Cv.interests.length
        ? InterestCard(key: ValueKey('card:interests:$i'), index: i)
        : const LanguagesCard(key: ValueKey('card:languages:0'));

    final cards = tablet
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var row = 0; row < 2; row++) ...[
                if (row > 0) SizedBox(height: gap),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var col = 0; col < 2; col++) ...[
                        if (col > 0) SizedBox(width: gap),
                        Expanded(
                          child: Reveal(
                            index: row * 2 + col,
                            child: side(row * 2 + col),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) SizedBox(height: gap),
                Reveal(index: i, child: side(i)),
              ],
            ],
          );

    return Padding(
      padding: EdgeInsets.symmetric(vertical: Layout.sectionPadding(bp)),
      child: MaxWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionHeader(
              eyebrow: _aboutEyebrow,
              titleLines: _chapterTitle,
              trailing: SeeAllButton(
                section: SiteSection.about,
                tab: 'profile',
              ),
            ),
            SizedBox(height: Layout.headerGap(bp)),
            const _FlipProfileCard(key: ValueKey('card:profile:0')),
            SizedBox(height: gap),
            cards,
          ],
        ),
      ),
    );
  }
}

/// Mobile chapter 1: one rotateY flip (Motion.cardFlip) from the deep art
/// face to the profile card when 35 % in view. Reduced motion → profile face.
class _FlipProfileCard extends StatelessWidget {
  const _FlipProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InView(builder: (context, inView, _) => _Flip(play: inView));
  }
}

class _Flip extends StatefulWidget {
  const _Flip({required this.play});

  final bool play;

  @override
  State<_Flip> createState() => _FlipState();
}

class _FlipState extends State<_Flip> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.cardFlip,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) _c.value = 1;
  }

  @override
  void initState() {
    super.initState();
    if (widget.play) _c.forward();
  }

  @override
  void didUpdateWidget(covariant _Flip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.play && !oldWidget.play) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const back = _ProfileFace();
    final front = ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: p.deep,
          borderRadius: BorderRadius.circular(Radii.card),
        ),
        child: Center(
          child: LogoMark(color: p.onDeep, height: 48),
        ),
      ),
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOutCubic.transform(_c.value);
        final angle = t * math.pi;
        final showBack = angle >= math.pi / 2;
        Matrix4 rot(double a) => Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(a);
        return Stack(
          children: [
            Visibility(
              visible: showBack,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              maintainSemantics: true,
              child: t >= 1
                  ? back
                  : Transform(
                      alignment: Alignment.center,
                      transform: rot(angle - math.pi),
                      child: back,
                    ),
            ),
            if (!showBack)
              Positioned.fill(
                child: Transform(
                  alignment: Alignment.center,
                  transform: rot(angle),
                  child: front,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Profile paragraph card (Home fallback).
class _ProfileFace extends StatelessWidget {
  const _ProfileFace();

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final p = context.palette;
    return BentoCard(
      outlined: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('// PROFILE', style: t.label.copyWith(color: p.primary)),
          const SizedBox(height: Space.s12),
          Text(Cv.profile, style: t.bodyL.copyWith(color: p.ink)),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Desktop pinned stage
// ───────────────────────────────────────────────────────────────────────────

/// Stage geometry (viewport-relative), recomputed on resize only.
class _Geo {
  _Geo(this.size, TextStyle titleStyle, TextScaler scaler) {
    final vw = size.width;
    final vh = size.height;
    final totalW = math.min(1040.0, vw - 2 * Layout.pagePadding(Bp.desktop));
    colW = (totalW - 2 * gap) / 3;
    cardH = math.min(vh * 0.69, vh - 2 * Space.s64);
    final left = (vw - totalW) / 2;
    final top = (vh - cardH) / 2;
    card = Rect.fromLTWH(left + colW + gap, top, colW, cardH);
    leftCol = Rect.fromLTWH(left, top, colW, cardH);
    rightCol = Rect.fromLTWH(card.right + gap, top, colW, cardH);

    // Title: measured once so the P9a transform has a known box.
    innerW = colW - 2 * pad;
    var widest = 0.0;
    var total = 0.0;
    for (final line in _chapterTitle) {
      final tp = TextPainter(
        text: TextSpan(text: line, style: titleStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      widest = math.max(widest, tp.width);
      total += tp.height;
      tp.dispose();
    }
    final fit = widest > innerW && widest > 0 ? innerW / widest : 1.0;
    titleH = total * fit + 2;
    title = Rect.fromLTWH(card.left + pad, card.top + pad, innerW, titleH);

    // Hero photo, bottom centre, cropped at ~25 % of its height (75 % visible).
    final photoH = (vh * 0.54).clamp(240.0, 520.0);
    final photoW = photoH * 0.8;
    photo = Rect.fromLTWH(
      (vw - photoW) / 2,
      vh - photoH * 0.75,
      photoW,
      photoH,
    );
    final dockW = math.min(96.0, colW * 0.3);
    dockScale = dockW / photoW;
    final dockH = photoH * dockScale;
    dockCenter = Offset(card.right - pad - dockW / 2, card.bottom);
    bottomReserve = math.max(dockH / 2 + Space.s8, 44 + Space.s8);
  }

  static const gap = 16.0;
  static const pad = 24.0;

  final Size size;
  late final double colW;
  late final double cardH;
  late final Rect card;
  late final Rect leftCol;
  late final Rect rightCol;
  late final double innerW;
  late final double titleH;
  late final Rect title;
  late final Rect photo;
  late final double dockScale;
  late final Offset dockCenter;
  late final double bottomReserve;

  /// Equal-share height of a side card (2 per column).
  double get sideH => (cardH - gap) / 2;
}

// Phase map (observed spec §3b, compressed to 2.6 vh; holds ≤ 0.10).
const _heroOut = (0.0, 0.22); // hero exit, P7 flip, photo docks (P14)
const _wipe = (0.32, 0.40); // P8
const _collapse = (0.50, 0.78); // P9a
const _profileIn = (0.78, 0.88);
const _rise = (0.58, 0.92); // P10
const _accordionFrom = 0.97; // P11

class _DesktopStage extends StatefulWidget {
  const _DesktopStage({required this.progress});

  final ValueListenable<double> progress;

  @override
  State<_DesktopStage> createState() => _DesktopStageState();
}

class _DesktopStageState extends State<_DesktopStage> {
  final ValueNotifier<Rect?> _inside = ValueNotifier<Rect?>(null);
  final ValueNotifier<bool> _heroLive = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _idLive = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _artLive = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _settled = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _accordion = ValueNotifier<bool>(false);
  _Geo? _geo;

  @override
  void initState() {
    super.initState();
    widget.progress.addListener(_sync);
  }

  @override
  void didUpdateWidget(covariant _DesktopStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      oldWidget.progress.removeListener(_sync);
      widget.progress.addListener(_sync);
    }
  }

  @override
  void dispose() {
    widget.progress.removeListener(_sync);
    for (final n in [_heroLive, _idLive, _artLive, _settled, _accordion]) {
      n.dispose();
    }
    _inside.dispose();
    super.dispose();
  }

  /// Phase flags + the two-tone inside rect (title-local coordinates).
  void _sync() {
    final p = widget.progress.value;
    final wipe = seg(p, _wipe.$1, _wipe.$2);
    final collapse = seg(p, _collapse.$1, _collapse.$2, Curves.easeInOut);
    _heroLive.value = p < _heroOut.$2;
    _idLive.value = p < _wipe.$2 + 0.01;
    _artLive.value = wipe > 0 && collapse < 1;
    _settled.value = p >= _profileIn.$2;
    _accordion.value = p > _accordionFrom;

    final g = _geo;
    if (g == null || wipe <= 0 || collapse >= 1) {
      _inside.value = null;
      return;
    }
    // Visible art region in stage coordinates: the wiped part of the card,
    // squeezed horizontally by the P9a rotateY.
    final halfW = g.card.width / 2 * math.cos(collapse * math.pi / 2);
    final art = Rect.fromLTRB(
      math.max(g.card.center.dx - halfW, g.card.right - wipe * g.card.width),
      g.card.top,
      g.card.center.dx + halfW,
      g.card.bottom,
    );
    if (art.width <= 0.5) {
      _inside.value = null;
      return;
    }
    final (s, ty) = _titleTransform(g, collapse);
    // stage = origin + (0, ty) + s * (local - originLocal), origin = top centre.
    final origin = Offset(g.title.center.dx, g.title.top + ty);
    Offset toLocal(Offset q) => Offset(g.innerW / 2, 0) + (q - origin) / s;
    _inside.value = Rect.fromPoints(
      toLocal(art.topLeft),
      toLocal(art.bottomRight),
    );
  }

  /// P9a: (scale, translateY) of the title box about its top centre.
  static (double, double) _titleTransform(_Geo g, double c) {
    final s = 4.0 + (1.0 - 4.0) * c;
    // At c = 0 the 4× title is centred on the card.
    final ty0 = g.card.center.dy - g.title.top - 4.0 * g.titleH / 2;
    return (s, ty0 * (1 - c));
  }

  Animation<double> _map(double Function(double) f) =>
      _MappedListenable(widget.progress, f);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final size = MediaQuery.sizeOf(context);
    final titleStyle = t.displayM;
    final g = _geo = (_geo != null && _geo!.size == size)
        ? _geo!
        : _Geo(size, titleStyle, MediaQuery.textScalerOf(context));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
    final progress = widget.progress;
    final vh = size.height;
    final clearance = SiteShell.headerClearance(context);
    final pad = Layout.pagePadding(Bp.desktop);

    // ── Hero copy: scrolls away + fades (0–0.22). ──
    final hero = Positioned(
      top: clearance,
      left: pad,
      right: pad,
      child: ValueListenableBuilder<bool>(
        valueListenable: _heroLive,
        builder: (context, live, child) => IgnorePointer(
          ignoring: !live,
          child: ExcludeSemantics(excluding: !live, child: child),
        ),
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, child) => Transform.translate(
            offset: Offset(
              0,
              -seg(progress.value, _heroOut.$1, _heroOut.$2) * vh * 0.6,
            ),
            child: child,
          ),
          child: FadeTransition(
            opacity: _map((v) => 1 - seg(v, 0.06, 0.2)),
            child: _HeroCopy(
              lines: ['${Cv.nameLines[0]} ${Cv.nameLines[1]}', Cv.nameLines[2]],
              maxNameHeight: math.max(140, vh * 0.34),
            ),
          ),
        ),
      ),
    );

    // ── Centre card: P7 flip-in, ID face, P8 art wipe, P9a edge-on, profile. ──
    final card = Positioned.fromRect(
      rect: g.card,
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, child) {
          final f = seg(progress.value, 0.02, _heroOut.$2, Motion.expoOut);
          if (f >= 1) return child!;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..translateByDouble(0, vh * 0.12 * (1 - f), 0, 1)
              ..rotateX(18 * math.pi / 180 * (1 - f)),
            child: child,
          );
        },
        child: FadeTransition(
          opacity: _map((v) {
            if (v <= 0.0) return 0.0;
            if (v < 0.04) return 0.3 * v / 0.04;
            return 0.3 + 0.7 * seg(v, 0.04, _heroOut.$2);
          }),
          child: _CentreCard(
            key: const ValueKey('card:profile:0'),
            geo: g,
            progress: progress,
            idLive: _idLive,
            artLive: _artLive,
            settled: _settled,
          ),
        ),
      ),
    );

    // ── Title: P8 fade-in two-tone, P9a scale 4 → 1 into the card top. ──
    final title = Positioned.fromRect(
      rect: g.title,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, child) {
            final c = seg(
              progress.value,
              _collapse.$1,
              _collapse.$2,
              Curves.easeInOut,
            );
            final (s, ty) = _titleTransform(g, c);
            return Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.translationValues(0, ty, 0)
                ..scaleByDouble(s, s, 1, 1),
              child: child,
            );
          },
          child: FadeTransition(
            opacity: _map((v) => seg(v, _wipe.$1, _wipe.$2)),
            child: TwoToneText(
              _chapterTitle,
              style: titleStyle,
              outsideColor: p.ink,
              insideColor: p.onDeep,
              insideRect: _inside,
            ),
          ),
        ),
      ),
    );

    // ── Side columns: P10 linear rise, P11 accordion when p > 0.97. ──
    Widget column(Rect r, List<Widget> cards) {
      final from = math.max(vh * Motion.riseFromVh, vh - r.top + Space.s8);
      return Positioned.fromRect(
        rect: r,
        child: AnimatedBuilder(
          animation: progress,
          builder: (context, child) {
            final rise = seg(progress.value, _rise.$1, _rise.$2);
            return Transform.translate(
              offset: Offset(0, from * (1 - rise)),
              child: child,
            );
          },
          child: ValueListenableBuilder<bool>(
            valueListenable: _accordion,
            builder: (context, live, child) =>
                IgnorePointer(ignoring: !live, child: child),
            child: AccordionColumn(
              extent: g.cardH,
              gap: _Geo.gap,
              items: [
                for (final c in cards)
                  (context, open) => _SideSlot(height: g.sideH, child: c),
              ],
            ),
          ),
        ),
      );
    }

    final left = column(g.leftCol, [
      const InterestCard(
        key: ValueKey('card:interests:0'),
        index: 0,
        fill: true,
      ),
      const InterestCard(
        key: ValueKey('card:interests:1'),
        index: 1,
        fill: true,
      ),
    ]);
    final right = column(g.rightCol, [
      const InterestCard(
        key: ValueKey('card:interests:2'),
        index: 2,
        fill: true,
      ),
      const LanguagesCard(key: ValueKey('card:languages:0'), fill: true),
    ]);

    // ── Photo: P5 rise, then P14 shrink + dock on the card's bottom edge. ──
    final intro = IntroScope.of(context);
    final photo = Positioned.fromRect(
      rect: g.photo,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: Listenable.merge([progress, intro]),
          builder: (context, child) {
            final rise = _introT(intro, IntroScope.photoRise);
            final d = seg(progress.value, 0.02, _heroOut.$2, Curves.easeInOut);
            final s = 1 + (g.dockScale - 1) * d;
            final move = (g.dockCenter - g.photo.center) * d;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.translationValues(
                move.dx,
                move.dy + Motion.avatarRiseFrom * (1 - rise),
                0,
              )..scaleByDouble(s, s, 1, 1),
              child: child,
            );
          },
          child: ProfilePhoto(width: g.photo.width, height: g.photo.height),
        ),
      ),
    );

    final toast = Positioned(
      left: Space.s32,
      bottom: Space.s32,
      child: ValueListenableBuilder<bool>(
        valueListenable: _heroLive,
        builder: (context, live, child) =>
            live ? child! : const SizedBox.shrink(),
        child: FadeTransition(
          opacity: _map((v) => 1 - seg(v, 0.0, 0.06)),
          child: const _HeroToast(),
        ),
      ),
    );

    return ColoredBox(
      color: p.canvas,
      child: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [hero, left, right, card, title, photo, toast],
        ),
      ),
    );
  }
}

/// A side card inside the accordion: content laid out at the equal-share
/// height (guarded by FitHeight inside the card), clipped when the slot
/// shrinks to a title strip, top-aligned when it grows.
class _SideSlot extends StatelessWidget {
  const _SideSlot({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.card),
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: height,
        maxHeight: height,
        child: child,
      ),
    );
  }
}

/// The pinned centre card. Rect never changes (P9a); its faces swap.
class _CentreCard extends StatelessWidget {
  const _CentreCard({
    super.key,
    required this.geo,
    required this.progress,
    required this.idLive,
    required this.artLive,
    required this.settled,
  });

  final _Geo geo;
  final ValueListenable<double> progress;
  final ValueListenable<bool> idLive;
  final ValueListenable<bool> artLive;
  final ValueListenable<bool> settled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    const pad = _Geo.pad;
    final shape = BorderRadius.circular(Radii.card);

    // Final face: 1 px outline + profile paragraph + See all.
    final profile = FadeTransition(
      opacity: _MappedListenable(
        progress,
        (v) => seg(v, _profileIn.$1, _profileIn.$2),
      ),
      child: Stack(
        children: [
          Positioned(
            left: pad,
            right: pad,
            top: pad + geo.titleH + Space.s16,
            bottom: geo.bottomReserve + Space.s8,
            child: FitHeight(
              child: Text(Cv.profile, style: t.body.copyWith(color: p.ink)),
            ),
          ),
          Positioned(
            left: pad,
            bottom: Space.s16,
            child: ValueListenableBuilder<bool>(
              valueListenable: settled,
              builder: (context, live, child) => IgnorePointer(
                ignoring: !live,
                child: ExcludeSemantics(excluding: !live, child: child),
              ),
              child: const SeeAllButton(
                section: SiteSection.about,
                tab: 'profile',
              ),
            ),
          ),
        ],
      ),
    );

    // ID face (0–0.40 only): name + focus chips, no location.
    final id = ValueListenableBuilder<bool>(
      valueListenable: idLive,
      builder: (context, live, _) {
        if (!live) return const SizedBox.shrink();
        return DecoratedBox(
          decoration: BoxDecoration(color: p.surface, borderRadius: shape),
          child: Padding(
            padding: const EdgeInsets.all(pad),
            child: FitHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('// ID', style: t.label.copyWith(color: p.primary)),
                  const SizedBox(height: Space.s16),
                  Text(
                    Cv.contact.name,
                    style: t.headingL.copyWith(color: p.ink),
                  ),
                  const SizedBox(height: Space.s16),
                  Wrap(
                    spacing: Space.s8,
                    runSpacing: Space.s8,
                    children: [
                      for (final f in Cv.focusAreas)
                        ChipTag(f, style: ChipStyle.filled),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    // Art face: P8 slanted wipe in, P9a rotateY to edge-on.
    final art = ValueListenableBuilder<bool>(
      valueListenable: artLive,
      builder: (context, live, child) =>
          live ? child! : const SizedBox.shrink(),
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, child) {
          final v = progress.value;
          final wipe = seg(v, _wipe.$1, _wipe.$2);
          final c = seg(v, _collapse.$1, _collapse.$2, Curves.easeInOut);
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0015)
              ..rotateY(c * math.pi / 2),
            child: ClipPath(clipper: SlantWipeClipper(wipe), child: child),
          );
        },
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: p.deep,
              borderRadius: shape,
            ),
            child: Center(
              child: LogoMark(color: p.onDeep, height: 56),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: 'Profile',
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shape,
          border: Border.all(color: p.ink.withValues(alpha: 0.2)),
        ),
        child: Stack(fit: StackFit.expand, children: [profile, id, art]),
      ),
    );
  }
}
