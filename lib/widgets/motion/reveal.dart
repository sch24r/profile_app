import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';
import 'in_view.dart';

/// Mobile/tablet fallback & generic one-shot entrance.
///
/// Rise [distance] px + fade, [Motion.mobileReveal], [Motion.expoOut]
/// (opacity: [Motion.sineOut]),
/// delay = delay + Motion.stagger * min(index, Motion.maxStaggerIndex).
/// Triggered when [fraction] of the child is in view (same measure as
/// [InView]). After completion returns the bare child (its state is preserved
/// via a GlobalKey reparent). reduceMotion / !enabled → child.
///
/// ```dart
/// for (final (i, card) in cards.indexed) Reveal(index: i, child: card)
/// ```
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.distance = Motion.mobileRevealDistance,
    this.fraction = Motion.mobileTriggerFraction,
    this.duration = Motion.mobileReveal,
    this.enabled = true,
  });

  final Widget child;

  /// Position in a list; adds `Motion.stagger * min(index, maxStaggerIndex)`.
  final int index;
  final Duration delay;

  /// Rise distance in logical px (from below).
  final double distance;

  /// Visible fraction that triggers the entrance.
  final double fraction;
  final Duration duration;

  /// When false the child is shown statically.
  final bool enabled;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal>
    with SingleTickerProviderStateMixin, ViewportListenerMixin<Reveal> {
  final GlobalKey _childKey = GlobalKey(debugLabel: 'Reveal.child');
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..addStatusListener(_onStatus);
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Motion.sineOut,
  );
  late final Animation<double> _rise = CurvedAnimation(
    parent: _controller,
    curve: Motion.expoOut,
  );

  Timer? _delayTimer;
  bool _triggered = false;
  bool _done = false;

  bool get _static => _done || !widget.enabled;

  @override
  void didChangeDependencies() {
    if (context.reduceMotion || !widget.enabled) _finish();
    if (_static || _triggered) stopViewportListening();
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant Reveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Disabling (even temporarily) settles the entrance for good.
    if (!widget.enabled) _finish();
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void onViewportChanged() {
    if (_static || _triggered) return;
    if (visibleFraction(context) < widget.fraction.clamp(0.0, 1.0)) return;
    _triggered = true;
    stopViewportListening();
    final delay =
        widget.delay +
        Motion.stagger *
            math.min(math.max(widget.index, 0), Motion.maxStaggerIndex);
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(_finish);
    }
  }

  void _finish() {
    _done = true;
    _delayTimer?.cancel();
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = KeyedSubtree(key: _childKey, child: widget.child);
    if (_static || context.reduceMotion) return child;
    return FadeTransition(
      opacity: _opacity,
      child: _RiseTransition(
        animation: _rise,
        distance: widget.distance,
        child: child,
      ),
    );
  }
}

/// Paint-only vertical translation from +[distance] to 0.
class _RiseTransition extends AnimatedWidget {
  const _RiseTransition({
    required Animation<double> animation,
    required this.distance,
    required this.child,
  }) : super(listenable: animation);

  final double distance;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = (listenable as Animation<double>).value;
    return Transform.translate(
      offset: Offset(0, distance * (1 - t)),
      child: child,
    );
  }
}
