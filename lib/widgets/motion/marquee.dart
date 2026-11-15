import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';
import 'viewport_gate.dart';

/// P21: infinite linear horizontal scroll of [children] repeated, [speed]
/// px/s, under its own [ViewportGate] (pauses off-screen).
///
/// A single repeating AnimationController drives a paint-time translation of
/// N copies of the run (N = just enough to cover the width; recomputed on
/// resize) inside a RepaintBoundary — no rebuild or relayout per frame.
/// Copies after the first are excluded from semantics.
/// reduceMotion → static, user-scrollable horizontal row.
///
/// ```dart
/// Marquee(
///   speed: context.isDesktop ? Motion.marqueeStrip : Motion.marqueeStripMobile,
///   reverse: true,
///   children: [for (final t in Cv.tickerItems) _Tile(t)],
/// )
/// ```
class Marquee extends StatefulWidget {
  const Marquee({
    super.key,
    required this.children,
    this.speed = Motion.marqueeStrip,
    this.reverse = false,
    this.gap = 12,
    this.height,
  });

  final List<Widget> children;

  /// Logical px per second.
  final double speed;

  /// false: content moves right→left; true: left→right.
  final bool reverse;

  /// Gap between items (and between repeated runs).
  final double gap;

  /// Fixed height; null sizes to the tallest child.
  final double? height;

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> {
  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) {
      return SizedBox(height: widget.height ?? 0);
    }
    final Widget content;
    if (context.reduceMotion) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _Run(gap: widget.gap, children: widget.children),
      );
    } else {
      content = ViewportGate(
        child: _MarqueeTrack(
          speed: widget.speed,
          reverse: widget.reverse,
          gap: widget.gap,
          children: widget.children,
        ),
      );
    }
    final height = widget.height;
    return height == null ? content : SizedBox(height: height, child: content);
  }
}

/// One run of the children separated by [gap].
class _Run extends StatelessWidget {
  const _Run({required this.gap, required this.children});

  final double gap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          children[i],
        ],
      ],
    );
  }
}

/// Owns the controller *below* the ViewportGate so TickerMode mutes it.
class _MarqueeTrack extends StatefulWidget {
  const _MarqueeTrack({
    required this.speed,
    required this.reverse,
    required this.gap,
    required this.children,
  });

  final double speed;
  final bool reverse;
  final double gap;
  final List<Widget> children;

  @override
  State<_MarqueeTrack> createState() => _MarqueeTrackState();
}

class _MarqueeTrackState extends State<_MarqueeTrack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  int _copies = 2;
  double _period = 0;

  @override
  void didUpdateWidget(covariant _MarqueeTrack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.speed != widget.speed) _syncController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Reported by the render object after layout (post-frame).
  void _onMetrics(double period, int copies) {
    if (!mounted) return;
    final periodChanged = (period - _period).abs() > 0.5;
    _period = period;
    if (copies != _copies) setState(() => _copies = copies);
    if (periodChanged || !_controller.isAnimating) _syncController();
  }

  void _syncController() {
    if (_period <= 0 || widget.speed <= 0) {
      _controller.stop();
      return;
    }
    final micros = (_period / widget.speed * Duration.microsecondsPerSecond)
        .round();
    _controller.duration = Duration(microseconds: math.max(1, micros));
    // repeat() continues from the current phase, so a resize does not jump.
    _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final run = _Run(gap: widget.gap, children: widget.children);
    return RepaintBoundary(
      child: _MarqueeLayout(
        phase: _controller,
        gap: widget.gap,
        reverse: widget.reverse,
        onMetrics: _onMetrics,
        children: [
          for (var i = 0; i < _copies; i++)
            i == 0 ? run : ExcludeSemantics(child: run),
        ],
      ),
    );
  }
}

class _MarqueeParentData extends ContainerBoxParentData<RenderBox> {}

class _MarqueeLayout extends MultiChildRenderObjectWidget {
  const _MarqueeLayout({
    required this.phase,
    required this.gap,
    required this.reverse,
    required this.onMetrics,
    required super.children,
  });

  final Animation<double> phase;
  final double gap;
  final bool reverse;
  final void Function(double period, int copies) onMetrics;

  @override
  _RenderMarquee createRenderObject(BuildContext context) => _RenderMarquee(
    phase: phase,
    gap: gap,
    reverse: reverse,
    onMetrics: onMetrics,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderMarquee ro) {
    ro
      ..phase = phase
      ..gap = gap
      ..reverse = reverse
      ..onMetrics = onMetrics;
  }
}

/// Lays out identical run copies with unbounded width; paints copy i at
/// `i * period - shift` (or mirrored for reverse), clipped to its bounds.
class _RenderMarquee extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _MarqueeParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _MarqueeParentData> {
  _RenderMarquee({
    required this._phase,
    required this._gap,
    required this._reverse,
    required this.onMetrics,
  });

  void Function(double period, int copies) onMetrics;
  bool _metricsScheduled = false;
  double _period = 0;
  int _neededCopies = 2;
  final LayerHandle<ClipRectLayer> _clipLayer = LayerHandle<ClipRectLayer>();

  Animation<double> _phase;
  set phase(Animation<double> value) {
    if (identical(value, _phase)) return;
    if (attached) _phase.removeListener(markNeedsPaint);
    _phase = value;
    if (attached) _phase.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  bool _reverse;
  set reverse(bool value) {
    if (value == _reverse) return;
    _reverse = value;
    markNeedsPaint();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _MarqueeParentData) {
      child.parentData = _MarqueeParentData();
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _phase.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _phase.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    _clipLayer.layer = null;
    super.dispose();
  }

  // ── Layout ─────────────────────────────────────────────────────────────

  BoxConstraints _childConstraints(BoxConstraints c) =>
      BoxConstraints(maxHeight: c.maxHeight);

  @override
  double computeMinIntrinsicHeight(double width) =>
      firstChild?.getMinIntrinsicHeight(double.infinity) ?? 0.0;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      firstChild?.getMaxIntrinsicHeight(double.infinity) ?? 0.0;

  @override
  double computeMinIntrinsicWidth(double height) => 0.0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      firstChild?.getMaxIntrinsicWidth(height) ?? 0.0;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final first = firstChild;
    final runSize =
        first?.getDryLayout(_childConstraints(constraints)) ?? Size.zero;
    final width = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : runSize.width;
    return constraints.constrain(Size(width, runSize.height));
  }

  @override
  void performLayout() {
    final childConstraints = _childConstraints(constraints);
    var height = 0.0;
    var runWidth = 0.0;
    var child = firstChild;
    while (child != null) {
      child.layout(childConstraints, parentUsesSize: true);
      runWidth = math.max(runWidth, child.size.width);
      height = math.max(height, child.size.height);
      child = childAfter(child);
    }
    _period = runWidth + _gap;
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : runWidth;
    size = constraints.constrain(Size(width, height));

    // Vertically centre runs in case the box is taller than the content.
    child = firstChild;
    while (child != null) {
      final pd = child.parentData! as _MarqueeParentData;
      pd.offset = Offset(0, (size.height - child.size.height) / 2);
      child = childAfter(child);
    }

    final needed = runWidth <= 0 ? 1 : (size.width / _period).ceil() + 1;
    _neededCopies = math.max(2, needed);
    _scheduleMetrics();
  }

  /// Reports the latest period / copy count once per frame, after layout.
  void _scheduleMetrics() {
    if (_metricsScheduled) return;
    _metricsScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _metricsScheduled = false;
      if (attached) onMetrics(_period, _neededCopies);
    });
  }

  // ── Paint / hit test ───────────────────────────────────────────────────

  /// Horizontal paint offset of copy [index].
  double _dxFor(int index) {
    final shift = _phase.value * _period;
    return _reverse ? (index - 1) * _period + shift : index * _period - shift;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (firstChild == null) return;
    _clipLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      _paintRuns,
      oldLayer: _clipLayer.layer,
    );
  }

  void _paintRuns(PaintingContext context, Offset offset) {
    var index = 0;
    var child = firstChild;
    while (child != null) {
      final dx = _dxFor(index);
      if (dx < size.width && dx + child.size.width > 0) {
        final pd = child.parentData! as _MarqueeParentData;
        context.paintChild(child, offset + pd.offset + Offset(dx, 0));
      }
      index++;
      child = childAfter(child);
    }
  }

  int _indexOf(RenderBox target) {
    var index = 0;
    var child = firstChild;
    while (child != null && !identical(child, target)) {
      index++;
      child = childAfter(child);
    }
    return index;
  }

  @override
  void applyPaintTransform(covariant RenderBox child, Matrix4 transform) {
    final pd = child.parentData! as _MarqueeParentData;
    transform.translateByDouble(
      _dxFor(_indexOf(child)) + pd.offset.dx,
      pd.offset.dy,
      0.0,
      1.0,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var index = childCount - 1;
    var child = lastChild;
    while (child != null) {
      final pd = child.parentData! as _MarqueeParentData;
      final hit = result.addWithPaintOffset(
        offset: pd.offset + Offset(_dxFor(index), 0),
        position: position,
        hitTest: (result, transformed) =>
            child!.hitTest(result, position: transformed),
      );
      if (hit) return true;
      index--;
      child = childBefore(child);
    }
    return false;
  }

  @override
  Rect? describeApproximatePaintClip(covariant RenderObject child) =>
      Offset.zero & size;
}
