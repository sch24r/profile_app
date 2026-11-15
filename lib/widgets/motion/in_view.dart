import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';

/// Finds the nearest *vertical* [ScrollableState] above [context] without
/// registering an inherited dependency (safe to call from listeners and
/// post-frame callbacks). Horizontal scrollables (marquees, carousels) are
/// skipped so visibility is always measured against the page scroll.
ScrollableState? verticalScrollableOf(BuildContext context) {
  var state = context.findAncestorStateOfType<ScrollableState>();
  while (state != null &&
      state.axisDirection != AxisDirection.down &&
      state.axisDirection != AxisDirection.up) {
    state = state.context.findAncestorStateOfType<ScrollableState>();
  }
  return state;
}

/// The painted rect of [context]'s [RenderBox] and the rect of its vertical
/// scroll viewport, both in the viewport's coordinate space.
///
/// Returns null when the box is not laid out / attached, or when there is no
/// vertical Scrollable (callers treat that as "fully visible").
({Rect box, Rect viewport})? viewportGeometryOf(BuildContext context) {
  final ro = context.findRenderObject();
  if (ro is! RenderBox || !ro.attached || !ro.hasSize) return null;
  final scrollable = verticalScrollableOf(context);
  if (scrollable == null) return null;
  final vro = scrollable.context.findRenderObject();
  if (vro is! RenderBox || !vro.attached || !vro.hasSize) return null;
  final box = MatrixUtils.transformRect(
    ro.getTransformTo(vro),
    Offset.zero & ro.size,
  );
  return (box: box, viewport: Offset.zero & vro.size);
}

/// Fraction (0..1) of [context]'s RenderBox that is inside the nearest
/// vertical Scrollable's viewport. Returns 1.0 if there is no scrollable.
///
/// The fraction is measured against `min(boxHeight, viewportHeight)` so
/// elements taller than the viewport can still reach 1.0.
/// Returns 0.0 while the box has not been laid out yet.
double visibleFraction(BuildContext context) {
  final ro = context.findRenderObject();
  if (ro is! RenderBox || !ro.attached || !ro.hasSize) return 0.0;
  if (verticalScrollableOf(context) == null) return 1.0;
  final g = viewportGeometryOf(context);
  if (g == null) return 0.0;
  final visible =
      math.min(g.box.bottom, g.viewport.bottom) -
      math.max(g.box.top, g.viewport.top);
  final horizontallyOn =
      g.box.right > g.viewport.left && g.box.left < g.viewport.right;
  if (!horizontallyOn) return 0.0;
  final reference = math.min(g.box.height, g.viewport.height);
  if (reference <= 0) return visible >= 0 ? 1.0 : 0.0;
  return (visible / reference).clamp(0.0, 1.0);
}

/// Shared plumbing for widgets that react to their position in the page
/// scroll viewport: subscribes to the nearest vertical [ScrollPosition],
/// re-checks after the first layout, on every rebuild and on window resize,
/// and calls [onViewportChanged] (never during build/layout/paint).
mixin ViewportListenerMixin<T extends StatefulWidget> on State<T> {
  ScrollPosition? _vlPosition;

  /// Nearest enclosing horizontal scroll position (rails, carousels): moving
  /// it can bring the box into / out of the page viewport horizontally.
  ScrollPosition? _vlHPosition;
  bool _vlCheckScheduled = false;
  bool _vlListening = true;

  /// Called whenever the widget's position relative to the viewport may have
  /// changed. Implementations should be cheap and only `setState` on change.
  void onViewportChanged();

  /// Stop listening to scroll updates (e.g. after a one-shot trigger fired).
  void stopViewportListening() {
    _vlListening = false;
    _vlPosition?.removeListener(_vlOnScroll);
    _vlPosition = null;
    _vlHPosition?.removeListener(_vlOnScroll);
    _vlHPosition = null;
  }

  /// Schedule a check after the current frame's layout.
  void scheduleViewportCheck() {
    if (_vlCheckScheduled || !_vlListening) return;
    _vlCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vlCheckScheduled = false;
      if (mounted && _vlListening) onViewportChanged();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  // Scroll notifications arrive before the viewport re-lays out its slivers,
  // so measure after this frame's layout instead of synchronously.
  void _vlOnScroll() => scheduleViewportCheck();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Dependencies: window size (resize re-check) + the page scrollable.
    MediaQuery.sizeOf(context);
    if (_vlListening) {
      final position = verticalScrollableOf(context)?.position;
      // Register a dependency so we are notified if the position is replaced.
      Scrollable.maybeOf(context, axis: Axis.vertical);
      if (!identical(position, _vlPosition)) {
        _vlPosition?.removeListener(_vlOnScroll);
        _vlPosition = position;
        _vlPosition?.addListener(_vlOnScroll);
      }
      final nearest = context.findAncestorStateOfType<ScrollableState>();
      final hPosition =
          nearest != null &&
              (nearest.axisDirection == AxisDirection.left ||
                  nearest.axisDirection == AxisDirection.right)
          ? nearest.position
          : null;
      if (!identical(hPosition, _vlHPosition)) {
        _vlHPosition?.removeListener(_vlOnScroll);
        _vlHPosition = hPosition;
        _vlHPosition?.addListener(_vlOnScroll);
      }
    }
    scheduleViewportCheck();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    scheduleViewportCheck();
  }

  @override
  void dispose() {
    _vlPosition?.removeListener(_vlOnScroll);
    _vlPosition = null;
    _vlHPosition?.removeListener(_vlOnScroll);
    _vlHPosition = null;
    super.dispose();
  }
}

/// Fires once when [fraction] of the widget's height is inside the nearest
/// Scrollable's viewport (or immediately if there is no Scrollable /
/// reduceMotion). Also re-checks after layout & on metrics change.
///
/// With [once] = false it reports both entering and leaving.
///
/// ```dart
/// InView(
///   builder: (context, inView, child) => AnimatedOpacity(
///     opacity: inView ? 1 : 0, duration: Motion.fade, child: child),
///   child: const Text('Hello'),
/// )
/// ```
class InView extends StatefulWidget {
  const InView({
    super.key,
    required this.builder,
    this.fraction = Motion.mobileTriggerFraction,
    this.once = true,
    this.child,
  });

  final Widget Function(BuildContext context, bool inView, Widget? child)
  builder;
  final double fraction;
  final bool once;
  final Widget? child;

  @override
  State<InView> createState() => _InViewState();
}

class _InViewState extends State<InView> with ViewportListenerMixin<InView> {
  bool _inView = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    _reduceMotion = context.reduceMotion;
    if (_reduceMotion && !_inView) {
      _inView = true;
      if (widget.once) stopViewportListening();
    }
    super.didChangeDependencies();
  }

  @override
  void onViewportChanged() {
    if (_reduceMotion) return;
    final f = visibleFraction(context);
    final threshold = widget.fraction.clamp(0.0, 1.0);
    // A box that just touches the viewport counts as 0, so require f > 0
    // even for a 0 threshold.
    final now = f > 0 && f >= threshold - 1e-6;
    if (now == _inView) return;
    if (!now && widget.once) return;
    setState(() => _inView = now);
    if (now && widget.once) stopViewportListening();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _inView, widget.child);
}
