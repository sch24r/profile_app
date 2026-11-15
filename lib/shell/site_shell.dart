import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../data/sections.dart';
import '../widgets/motion/pointer_tilt.dart';
import '../widgets/motion/story_progress.dart';
import '../widgets/ui/chapter_indicator.dart';
import 'footer.dart';
import 'intro_overlay.dart';
import 'site_header.dart';

export 'intro_overlay.dart' show IntroScope;

/// HOME ONLY. Vertical scroll view + floating [SiteHeader] + desktop
/// [ChapterIndicator] + first-visit [IntroOverlay]. Sub-pages use
/// `SubPageShell` (one screen, no scroll, no footer).
///
/// Owns the page [ScrollController] ([SiteShell.controllerOf]) and the global
/// pointer position ([PointerTracker]). [children] are plain box widgets laid
/// out in a single sliver list followed by the [Footer]; the first child must
/// leave [SiteShell.headerClearance] at its top.
class SiteShell extends StatefulWidget {
  const SiteShell({
    super.key,
    required this.section,
    required this.children,
    this.storyProgress,
    this.background,
  });

  final SiteSection section;
  final List<Widget> children;

  /// Home chapter progress; enables the desktop [ChapterIndicator].
  final StoryProgress? storyProgress;

  /// Page background (defaults to `palette.canvas`).
  final Color? background;

  /// Space the floating header needs at the top of the first child.
  static double headerClearance(BuildContext context) =>
      (context.isDesktop ? 112.0 : 84.0) + MediaQuery.paddingOf(context).top;

  /// The page scroll controller of the nearest shell (no rebuild dependency).
  static ScrollController? controllerOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ShellScope>()?.controller;

  @override
  State<SiteShell> createState() => _SiteShellState();
}

class _SiteShellState extends State<SiteShell>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  final ValueNotifier<Offset?> _pointer = ValueNotifier<Offset?>(null);

  AnimationController? _intro;
  bool _introDecided = false;
  bool _overlayVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_introDecided) return;
    _introDecided = true;
    final play =
        widget.section == SiteSection.home &&
        !IntroOverlay.hasPlayed &&
        !context.reduceMotion;
    // Whatever page is shown first consumes the once-per-session intro.
    IntroOverlay.markPlayed();
    if (!play) return;
    final intro = AnimationController(vsync: this, duration: IntroScope.total)
      ..addListener(_onIntroTick);
    _intro = intro;
    _overlayVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && intro.isDismissed) intro.forward();
    });
  }

  void _onIntroTick() {
    final intro = _intro;
    if (intro == null || !_overlayVisible) return;
    if (intro.value >= IntroOverlay.maskEnd(context)) {
      setState(() => _overlayVisible = false);
    }
  }

  void _skipIntro() {
    final intro = _intro;
    if (intro == null) return;
    intro.stop();
    intro.value = 1.0;
  }

  /// Whether the global pointer is tracked (desktop, motion allowed).
  bool _trackPointer = false;

  void _onPointer(PointerEvent e) {
    if (_trackPointer && e.kind == PointerDeviceKind.mouse) {
      _pointer.value = e.position;
    }
  }

  @override
  void dispose() {
    _intro?.dispose();
    _scroll.dispose();
    _pointer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final progress = widget.storyProgress;
    final intro = _intro;

    Widget body = CustomScrollView(
      controller: _scroll,
      slivers: [
        SliverList.list(children: [...widget.children, const Footer()]),
      ],
    );

    body = Stack(
      children: [
        Positioned.fill(child: body),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SiteHeader(section: widget.section, controller: _scroll),
        ),
        if (progress != null && context.isDesktop)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: ChapterIndicator(
                  progress: progress,
                  controller: _scroll,
                ),
              ),
            ),
          ),
        if (intro != null && _overlayVisible)
          Positioned.fill(
            child: IntroOverlay(intro: intro, onSkip: _skipIntro),
          ),
      ],
    );

    // Constant tree shape across breakpoints (never re-parent the page).
    _trackPointer = context.pointerEffects;
    if (!_trackPointer && _pointer.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pointer.value = null;
      });
    }
    body = PointerTracker(
      position: _pointer,
      child: MouseRegion(
        opaque: false,
        onExit: (_) => _pointer.value = null,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerHover: _onPointer,
          onPointerMove: _onPointer,
          child: body,
        ),
      ),
    );
    if (progress != null) {
      body = StoryProgressScope(progress: progress, child: body);
    }

    return _ShellScope(
      controller: _scroll,
      child: IntroScope(
        intro: intro ?? kAlwaysCompleteAnimation,
        child: Scaffold(
          backgroundColor: widget.background ?? palette.canvas,
          body: body,
        ),
      ),
    );
  }
}

/// Exposes the page scroll controller to descendants (read without dependency).
class _ShellScope extends InheritedWidget {
  const _ShellScope({required this.controller, required super.child});

  final ScrollController controller;

  @override
  bool updateShouldNotify(_ShellScope oldWidget) =>
      controller != oldWidget.controller;
}
