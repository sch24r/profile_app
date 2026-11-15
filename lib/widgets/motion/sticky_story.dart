import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';
import '../../theme/spacing.dart';

/// P23 sticky story list.
///
/// Desktop (`context.pinEnabled`): two columns — on the left the
/// [visualBuilder] output is pinned (sticky within the list's extent, its top
/// at header clearance + 16), on the right the [items] list. The active item is
/// the last one whose top crossed 50 % of the viewport. Items go
/// 0.28 → 1 opacity over Motion.storyItem ([cumulative] = true keeps earlier
/// items lit; false → single-active). The visual swaps with a Motion.visualSwap
/// cross-fade + 0.96 → 1 scale. Reversible with scroll.
///
/// Mobile / tablet: no pin; every item shows `visualBuilder(context, i)`
/// inline above it and lights up (0.28 → 1, one-shot, cumulative) when its top
/// crosses 60 % of the viewport.
///
/// Reduced motion: everything lit, nothing pinned (desktop shows each visual
/// beside its item).
///
/// The pin is paint-only: a dedicated render box translates the visual inside
/// its own column on scroll (no relayout, no rebuild).
class StickyStory extends StatefulWidget {
  const StickyStory({
    super.key,
    required this.items,
    required this.visualBuilder,
    this.cumulative = true,
    this.visualWidthFraction = 0.42,
    this.spacing,
    this.columnGap,
    this.topInset,
  });

  final List<Widget> items;

  /// Builds the visual for item [active] (desktop: the pinned visual; mobile:
  /// called once per item, inline).
  final Widget Function(BuildContext context, int active) visualBuilder;

  final bool cumulative;

  /// Desktop width share of the pinned visual column.
  final double visualWidthFraction;

  /// Vertical space between items. Default: 96 desktop, 48 otherwise.
  final double? spacing;

  /// Horizontal gap between visual and list on desktop. Default 64.
  final double? columnGap;

  /// Viewport-top offset of the pinned visual. Default: desktop header
  /// clearance (112, = SiteShell.headerClearance) + 16.
  final double? topInset;

  /// Desktop header clearance (mirrors `SiteShell.headerClearance`).
  static const double _desktopHeaderClearance = 112;

  @override
  State<StickyStory> createState() => _StickyStoryState();
}

class _StickyStoryState extends State<StickyStory>
    with TickerProviderStateMixin {
  final List<GlobalKey> _keys = [];
  final List<AnimationController> _lit = [];
  final List<Animation<double>> _opacity = [];

  /// Index shown by the pinned visual (never below 0).
  final ValueNotifier<int> _active = ValueNotifier(0);

  ScrollableState? _scrollable;
  ScrollPosition? _position;
  bool _pin = false;
  bool _reduce = false;
  bool _updateScheduled = false;

  static final Animatable<double> _dimToLit = Tween<double>(
    begin: 0.28,
    end: 1,
  ).chain(CurveTween(curve: Motion.sineOut));

  @override
  void initState() {
    super.initState();
    _syncItems();
  }

  @override
  void didUpdateWidget(covariant StickyStory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _syncItems();
      _scheduleUpdate();
    } else if (oldWidget.cumulative != widget.cumulative) {
      _scheduleUpdate();
    }
  }

  void _syncItems() {
    while (_lit.length > widget.items.length) {
      _keys.removeLast();
      _opacity.removeLast();
      _lit.removeLast().dispose();
    }
    while (_lit.length < widget.items.length) {
      final c = AnimationController(vsync: this, duration: Motion.storyItem);
      _keys.add(GlobalKey());
      _lit.add(c);
      _opacity.add(c.drive(_dimToLit));
    }
    if (_active.value >= widget.items.length) {
      _active.value = math.max(0, widget.items.length - 1);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modeChanged =
        _pin != context.pinEnabled || _reduce != context.reduceMotion;
    _pin = context.pinEnabled;
    _reduce = context.reduceMotion;

    final scrollable = Scrollable.maybeOf(context);
    if (!identical(scrollable, _scrollable) ||
        !identical(scrollable?.position, _position)) {
      _position?.removeListener(_scheduleUpdate);
      _scrollable = scrollable;
      _position = scrollable?.position;
      _position?.addListener(_scheduleUpdate);
    }

    if (_reduce || _position == null) {
      for (final c in _lit) {
        c.value = 1;
      }
      _active.value = 0;
    } else if (modeChanged) {
      // Mode switch (breakpoint / motion setting): restart from dim and let
      // the next measurement light what has already been passed.
      for (final c in _lit) {
        c.value = 0;
      }
    }
    _scheduleUpdate();
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleUpdate);
    for (final c in _lit) {
      c.dispose();
    }
    _active.dispose();
    super.dispose();
  }

  /// Measures after the next layout: scroll notifications arrive before the
  /// viewport has re-laid out, so measuring synchronously would be stale.
  void _scheduleUpdate() {
    if (_updateScheduled) return;
    _updateScheduled = true;
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        _updateScheduled = false;
        if (mounted) _measure();
      })
      ..ensureVisualUpdate();
  }

  /// Measures item tops against the threshold and updates lit states.
  void _measure() {
    if (_reduce || _position == null || _lit.isEmpty) return;
    final viewport = _scrollable?.context.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return;

    final threshold = viewport.size.height * (_pin ? 0.5 : 0.6);
    var crossed = -1;
    for (var i = 0; i < _keys.length; i++) {
      final box = _keys[i].currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) break;
      final top = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
      if (top > threshold) break;
      crossed = i;
    }

    if (_pin) {
      for (var i = 0; i < _lit.length; i++) {
        final lit = widget.cumulative ? i <= crossed : i == crossed;
        _drive(_lit[i], lit);
      }
      _active.value = math.max(0, crossed);
    } else {
      // Mobile / tablet: one-shot, cumulative.
      for (var i = 0; i <= crossed && i < _lit.length; i++) {
        _drive(_lit[i], true);
      }
    }
  }

  static void _drive(AnimationController c, bool lit) {
    if (lit) {
      if (c.status != AnimationStatus.completed &&
          c.status != AnimationStatus.forward) {
        c.forward();
      }
    } else if (c.status != AnimationStatus.dismissed &&
        c.status != AnimationStatus.reverse) {
      c.reverse();
    }
  }

  Widget _item(int i) {
    final child = KeyedSubtree(key: _keys[i], child: widget.items[i]);
    if (_reduce) return child;
    return FadeTransition(opacity: _opacity[i], child: child);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final desktop = context.isDesktop;
    final spacing = widget.spacing ?? (desktop ? Space.s96 : Space.s48);
    final columnGap = widget.columnGap ?? Space.s64;

    if (_pin) return _buildPinned(spacing, columnGap);
    if (desktop) return _buildSideBySide(spacing, columnGap);
    return _buildStacked(spacing);
  }

  /// Desktop: pinned visual column + item list.
  Widget _buildPinned(double spacing, double columnGap) {
    final topInset =
        widget.topInset ?? StickyStory._desktopHeaderClearance + Space.s16;
    return LayoutBuilder(
      builder: (context, constraints) {
        final visualW = constraints.maxWidth * widget.visualWidthFraction;
        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(left: visualW + columnGap),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.items.length; i++) ...[
                    if (i > 0) SizedBox(height: spacing),
                    _item(i),
                  ],
                ],
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: visualW,
              child: _StickyPin(
                scroll: _position,
                topInset: topInset,
                child: RepaintBoundary(
                  child: ValueListenableBuilder<int>(
                    valueListenable: _active,
                    builder: (context, active, _) => AnimatedSwitcher(
                      duration: Motion.visualSwap,
                      switchInCurve: Motion.expoOut,
                      switchOutCurve: Motion.sineOut,
                      layoutBuilder: _switcherLayout,
                      transitionBuilder: _swapTransition,
                      child: KeyedSubtree(
                        key: ValueKey<int>(active),
                        child: widget.visualBuilder(context, active),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Desktop with reduced motion: each visual beside its item, all lit.
  Widget _buildSideBySide(double spacing, double columnGap) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final visualW = constraints.maxWidth * widget.visualWidthFraction;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < widget.items.length; i++) ...[
              if (i > 0) SizedBox(height: spacing),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: visualW,
                    child: widget.visualBuilder(context, i),
                  ),
                  SizedBox(width: columnGap),
                  Expanded(child: _item(i)),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  /// Mobile / tablet: visual inline above each item.
  Widget _buildStacked(double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < widget.items.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          widget.visualBuilder(context, i),
          const SizedBox(height: Space.s20),
          _item(i),
        ],
      ],
    );
  }

  static Widget _switcherLayout(Widget? current, List<Widget> previous) =>
      Stack(alignment: Alignment.topLeft, children: [...previous, ?current]);

  static final Animatable<double> _swapScale = Tween<double>(
    begin: 0.96,
    end: 1,
  );

  static Widget _swapTransition(Widget child, Animation<double> animation) =>
      FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation.drive(_swapScale),
          child: child,
        ),
      );
}

/// Paints its child translated down so that the child's top sits at
/// [topInset] from the enclosing viewport's top, clamped to this box (the
/// list's extent). Paint-only: scroll changes repaint this boundary, never
/// relayout.
class _StickyPin extends SingleChildRenderObjectWidget {
  const _StickyPin({
    required this.scroll,
    required this.topInset,
    required super.child,
  });

  final Listenable? scroll;
  final double topInset;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderStickyPin(scroll, topInset);

  @override
  void updateRenderObject(BuildContext context, _RenderStickyPin renderObject) {
    renderObject
      ..scroll = scroll
      ..topInset = topInset;
  }
}

class _RenderStickyPin extends RenderProxyBox {
  _RenderStickyPin(this._scroll, this._topInset);

  Listenable? _scroll;
  set scroll(Listenable? value) {
    if (identical(value, _scroll)) return;
    if (attached) _scroll?.removeListener(markNeedsPaint);
    _scroll = value;
    if (attached) _scroll?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  double _topInset;
  set topInset(double value) {
    if (value == _topInset) return;
    _topInset = value;
    markNeedsPaint();
  }

  /// Current pin translation (from the last paint).
  double _dy = 0;

  @override
  bool get isRepaintBoundary => true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scroll?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _scroll?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void performLayout() {
    final child = this.child;
    size = constraints.biggest.isFinite
        ? constraints.biggest
        : constraints.constrain(Size.zero);
    if (child != null) {
      child.layout(
        BoxConstraints(
          minWidth: size.width,
          maxWidth: size.width,
          maxHeight: math.max(size.height, 0),
        ),
        parentUsesSize: true,
      );
    }
  }

  double _computeDy() {
    final child = this.child;
    if (child == null) return 0;
    final viewport = RenderAbstractViewport.maybeOf(this);
    if (viewport == null) return 0;
    final top = getTransformTo(viewport).getTranslation().y;
    final maxDy = math.max(0.0, size.height - child.size.height);
    return (_topInset - top).clamp(0.0, maxDy);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    _dy = _computeDy();
    context.paintChild(child, offset + Offset(0, _dy));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: Offset(0, _dy),
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(0, _dy, 0, 1);
  }
}
