import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';

/// Maps progress [p] into the 0..1 sub-interval [begin]..[end], optionally
/// curved. Values outside the interval clamp to 0 / 1.
///
/// ```dart
/// final wipe = seg(p, 0.32, 0.38);                  // linear
/// final rise = seg(p, 0.60, 0.92, Motion.expoOut);  // curved
/// ```
double seg(double p, double begin, double end, [Curve curve = Curves.linear]) {
  if (end <= begin) return p >= end ? 1.0 : 0.0;
  final t = ((p - begin) / (end - begin)).clamp(0.0, 1.0);
  if (t == 0.0 || t == 1.0) return t;
  return curve.transform(t);
}

/// Desktop scrubbed chapter stage.
///
/// Occupies height = viewportHeight * [scrollLength] in the scroll view. Its
/// child (exactly one viewport tall, full width) is painted pinned to the top
/// of the viewport while the stage scrolls through, using a paint-time
/// translation in a custom RenderBox (no relayout per frame; hit-testing and
/// semantics follow the painted offset). The pin itself tracks the scroll
/// position exactly; only the reported progress is smoothed.
///
/// progress = 0 when the stage top hits the viewport top, 1 when its bottom
/// hits the viewport bottom; clamped. Progress is smoothed toward the raw
/// target with a Ticker ([Motion.scrubSmoothing] per 60 Hz frame,
/// frame-rate independent; the ticker stops when |target - value| < 0.0005).
/// Reversible. Works as a box child of `CustomScrollView > SliverList` (or any
/// vertical scroll view) and re-measures on window resize.
///
/// Callers must not use PinnedStage when `!context.pinEnabled` (mobile,
/// tablet, reduced motion) — asserted in debug. In release it degrades to a
/// single, unpinned viewport-tall box with progress fixed at 1.0.
///
/// Example:
/// ```dart
/// PinnedStage(
///   scrollLength: 3.4,
///   onProgress: (p) => StoryProgressScope.maybeOf(context)?.report(0, p),
///   builder: (context, progress) => Stack(children: [
///     const Positioned.fill(child: _StaticBackdrop()), // built once
///     AnimatedBuilder(
///       animation: progress,
///       child: const _Card(),                          // cached child
///       builder: (context, child) => Transform.translate(
///         offset: Offset(0, 200 * (1 - seg(progress.value, 0.0, 0.2))),
///         child: child,
///       ),
///     ),
///   ]),
/// )
/// ```
class PinnedStage extends StatefulWidget {
  const PinnedStage({
    super.key,
    required this.scrollLength,
    required this.builder,
    this.onProgress,
  }) : assert(scrollLength >= 1.0, 'scrollLength is in viewport heights, >= 1');

  /// Total stage height in viewport heights (>= 1.0).
  final double scrollLength;

  /// Builds the pinned, one-viewport-tall child. Called on (re)build only, not
  /// per frame — listen to [progress] inside (AnimatedBuilder etc.).
  final Widget Function(BuildContext context, ValueListenable<double> progress)
  builder;

  /// Smoothed progress, called whenever it changes.
  final ValueChanged<double>? onProgress;

  @override
  State<PinnedStage> createState() => _PinnedStageState();
}

class _PinnedStageState extends State<PinnedStage>
    with SingleTickerProviderStateMixin {
  /// Settled threshold for the smoothing ticker.
  static const _epsilon = 0.0005;

  final ValueNotifier<double> _progress = ValueNotifier<double>(0.0);
  final GlobalKey _stageKey = GlobalKey(debugLabel: 'PinnedStage');
  late final Ticker _ticker = createTicker(_onTick);

  ScrollPosition? _position;
  Duration _lastElapsed = Duration.zero;
  bool _hasValue = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (!identical(position, _position)) {
      _position?.removeListener(_onScroll);
      _position = position;
      _position?.addListener(_onScroll);
    }
  }

  @override
  void didUpdateWidget(covariant PinnedStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollLength != widget.scrollLength) _kick();
  }

  @override
  void dispose() {
    _position?.removeListener(_onScroll);
    _ticker.dispose();
    _progress.dispose();
    super.dispose();
  }

  _RenderPinnedStage? get _render {
    final ro = _stageKey.currentContext?.findRenderObject();
    return ro is _RenderPinnedStage ? ro : null;
  }

  void _onScroll() => _kick();

  /// Called by the render object after every layout (post-frame) and on
  /// scroll: (re)starts smoothing if the target moved.
  void _kick() {
    if (!mounted) return;
    final render = _render;
    if (render == null || !render.hasSize) return;
    final target = render.rawProgress;
    if (!_hasValue) {
      // First measurement (e.g. page restored mid-scroll): jump, no easing.
      _hasValue = true;
      _set(target);
      return;
    }
    if ((target - _progress.value).abs() < _epsilon) {
      if (target != _progress.value && !_ticker.isActive) _set(target);
      return;
    }
    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final render = _render;
    if (render == null || !render.hasSize) {
      _ticker.stop();
      return;
    }
    final target = render.rawProgress;
    final dtMs = (elapsed - _lastElapsed).inMicroseconds / 1000.0;
    _lastElapsed = elapsed;
    // Frame-rate independent version of "lerp by scrubSmoothing per 60 Hz
    // frame". First tick (dt == 0) uses one nominal frame.
    final frames = dtMs <= 0 ? 1.0 : (dtMs / (1000.0 / 60.0)).clamp(0.25, 4.0);
    final alpha =
        1.0 - math.pow(1.0 - Motion.scrubSmoothing, frames).toDouble();
    final current = _progress.value;
    var next = current + (target - current) * alpha;
    if ((target - next).abs() < _epsilon) {
      next = target;
      _ticker.stop();
    }
    _set(next);
  }

  void _set(double value) {
    if (value == _progress.value) return;
    _progress.value = value;
    widget.onProgress?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      context.pinEnabled,
      'PinnedStage used while !context.pinEnabled (mobile/tablet/reduced '
      'motion). Callers must render their non-pinned fallback instead.',
    );
    final screenHeight = MediaQuery.sizeOf(context).height;
    if (!context.pinEnabled) {
      // Release-mode degradation: one unpinned viewport, end state.
      return SizedBox(
        height: screenHeight,
        child: RepaintBoundary(
          child: widget.builder(context, const _FixedListenable(1.0)),
        ),
      );
    }
    return _PinnedStageLayout(
      key: _stageKey,
      position: _position,
      viewportHint: screenHeight,
      scrollLength: widget.scrollLength,
      onLayout: _kick,
      child: RepaintBoundary(
        child: Builder(
          builder: (context) => widget.builder(context, _progress),
        ),
      ),
    );
  }
}

/// Constant [ValueListenable] used by the release-mode fallback.
class _FixedListenable implements ValueListenable<double> {
  const _FixedListenable(this.value);
  @override
  final double value;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class _PinnedStageLayout extends SingleChildRenderObjectWidget {
  const _PinnedStageLayout({
    super.key,
    required this.position,
    required this.viewportHint,
    required this.scrollLength,
    required this.onLayout,
    required Widget super.child,
  });

  final ScrollPosition? position;
  final double viewportHint;
  final double scrollLength;
  final VoidCallback onLayout;

  @override
  _RenderPinnedStage createRenderObject(BuildContext context) =>
      _RenderPinnedStage(
        position: position,
        viewportHint: viewportHint,
        scrollLength: scrollLength,
        onLayout: onLayout,
      );

  @override
  void updateRenderObject(BuildContext context, _RenderPinnedStage ro) {
    ro
      ..position = position
      ..viewportHint = viewportHint
      ..scrollLength = scrollLength
      ..onLayout = onLayout;
  }
}

/// Sizes itself to `viewport * scrollLength`, lays the child out at exactly
/// one viewport, and paints / hit-tests it at
/// `dy = clamp(-localTop, 0, height - viewport)`, where localTop is this box's
/// top edge relative to the viewport's top edge. Listens to the scroll
/// position and only repaints (never relayouts) on scroll.
class _RenderPinnedStage extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderPinnedStage({
    required this._position,
    required this._viewportHint,
    required this._scrollLength,
    required this.onLayout,
  });

  VoidCallback onLayout;
  bool _layoutCallbackScheduled = false;
  bool _relayoutScheduled = false;

  /// Viewport extent used by the last layout.
  double _vh = 0;

  ScrollPosition? _position;
  set position(ScrollPosition? value) {
    if (identical(value, _position)) return;
    if (attached) _position?.removeListener(markNeedsPaint);
    _position = value;
    if (attached) _position?.addListener(markNeedsPaint);
    markNeedsLayout();
  }

  /// MediaQuery height: fallback viewport extent and a resize trigger (a
  /// height-only window resize does not change our box constraints).
  double _viewportHint;
  set viewportHint(double value) {
    if (value == _viewportHint) return;
    _viewportHint = value;
    markNeedsLayout();
  }

  double _scrollLength;
  set scrollLength(double value) {
    if (value == _scrollLength) return;
    _scrollLength = value;
    markNeedsLayout();
  }

  /// The actual scroll viewport extent (falls back to the MediaQuery height).
  double get _currentViewportExtent {
    final p = _position;
    if (p != null && p.hasViewportDimension && p.viewportDimension > 0) {
      return p.viewportDimension;
    }
    return _viewportHint;
  }

  /// This box's top edge relative to the viewport's top edge (negative once
  /// scrolled past). Valid outside of this box's own layout.
  double get _localTop {
    final p = _position;
    if (p == null || !attached || !p.hasPixels) return 0.0;
    final viewport = RenderAbstractViewport.maybeOf(this);
    if (viewport == null) return 0.0;
    final reveal = viewport.getOffsetToReveal(
      this,
      0.0,
      rect: Rect.fromLTWH(0, 0, size.width, 0),
    );
    return reveal.offset - p.pixels;
  }

  double get _travel => math.max(0.0, size.height - _vh);

  /// Paint/hit-test translation of the child.
  double get _pinOffset {
    if (!hasSize) return 0.0;
    return (-_localTop).clamp(0.0, _travel);
  }

  /// Unsmoothed progress in 0..1.
  double get rawProgress {
    if (!hasSize) return 0.0;
    final scrolled = -_localTop;
    final travel = _travel;
    if (travel <= 0) return scrolled >= 0 ? 1.0 : 0.0;
    return (scrolled / travel).clamp(0.0, 1.0);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _position?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _position?.removeListener(markNeedsPaint);
    super.detach();
  }

  // ── Layout ─────────────────────────────────────────────────────────────

  Size _sizeFor(BoxConstraints constraints, double vh) {
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : constraints.minWidth;
    return constraints.constrain(Size(width, vh * _scrollLength));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _sizeFor(constraints, _viewportHint);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _currentViewportExtent * _scrollLength;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _currentViewportExtent * _scrollLength;

  @override
  double computeMinIntrinsicWidth(double height) =>
      child?.getMinIntrinsicWidth(_currentViewportExtent) ?? 0.0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      child?.getMaxIntrinsicWidth(_currentViewportExtent) ?? 0.0;

  @override
  void performLayout() {
    _vh = _currentViewportExtent;
    size = _sizeFor(constraints, _vh);
    final child = this.child;
    if (child != null) {
      child.layout(
        BoxConstraints.tightFor(
          width: size.width,
          height: math.min(_vh, size.height),
        ),
      );
    }
    _scheduleLayoutCallback();
  }

  void _scheduleLayoutCallback() {
    if (_layoutCallbackScheduled) return;
    _layoutCallbackScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _layoutCallbackScheduled = false;
      if (attached) onLayout();
    });
  }

  // ── Paint / hit test ───────────────────────────────────────────────────

  @override
  bool get alwaysNeedsCompositing => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    // Viewport extent changed without a MediaQuery change (e.g. the scroll
    // view itself was resized): relayout next frame.
    final vh = _currentViewportExtent;
    if ((vh - _vh).abs() > 0.5 && !_relayoutScheduled) {
      _relayoutScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _relayoutScheduled = false;
        if (attached) markNeedsLayout();
      });
    }
    final child = this.child;
    if (child == null) return;
    context.paintChild(child, offset + Offset(0, _pinOffset));
  }

  @override
  void applyPaintTransform(covariant RenderObject child, Matrix4 transform) {
    transform.translateByDouble(0.0, _pinOffset, 0.0, 1.0);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: Offset(0, _pinOffset),
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  Rect? describeApproximatePaintClip(covariant RenderObject child) =>
      Offset.zero & size;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('scrollLength', _scrollLength))
      ..add(DoubleProperty('viewport', _vh));
  }
}
