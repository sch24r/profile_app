import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';

/// Provided by SiteShell: a [ValueListenable] of the global pointer position
/// (window coordinates; `null` when the pointer is outside the window).
class PointerTracker extends InheritedWidget {
  const PointerTracker({
    super.key,
    required this.position,
    required super.child,
  });

  final ValueListenable<Offset?> position;

  /// The nearest tracker's position listenable, or null when absent.
  static ValueListenable<Offset?>? maybeOf(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<PointerTracker>()?.position;

  @override
  bool updateShouldNotify(PointerTracker oldWidget) =>
      !identical(oldWidget.position, position);
}

/// P18 / P14-look: 3D tilt toward the pointer.
///
/// `Matrix4..setEntry(3, 2, 0.0012)..rotateY(θ)..rotateX(φ)` about the centre;
/// θ up to [maxYDeg], φ up to [maxXDeg]; the side nearest the pointer recedes
/// ([invert] flips that so it approaches instead).
///
/// Region mode (default): tracks the pointer while it is over this widget.
/// [global] = true: tracks the pointer anywhere in the window via the
/// [PointerTracker] provided by SiteShell (normalised by half the window size
/// around this widget's centre).
///
/// One [Ticker] lerps the current angles toward the target ([lerp] per 60 Hz
/// frame, frame-rate independent) and stops once settled. Only active when
/// `context.pointerEffects`; otherwise the child is painted flat. The child is
/// cached and isolated in a [RepaintBoundary], so a tilt frame only updates
/// the transform layer.
class PointerTilt extends StatefulWidget {
  const PointerTilt({
    super.key,
    required this.child,
    this.maxYDeg = Motion.tiltMaxY,
    this.maxXDeg = Motion.tiltMaxX,
    this.lerp = Motion.tiltLerp,
    this.global = false,
    this.invert = false,
  });

  final Widget child;
  final double maxYDeg;
  final double maxXDeg;
  final double lerp;
  final bool global;
  final bool invert;

  @override
  State<PointerTilt> createState() => _PointerTiltState();
}

class _PointerTiltState extends State<PointerTilt>
    with SingleTickerProviderStateMixin {
  static const double _perspective = 0.0012;
  static const double _settle = 0.0005;

  /// Current normalised pointer offset (-1..1 on each axis).
  final ValueNotifier<Offset> _current = ValueNotifier(Offset.zero);
  Offset _target = Offset.zero;

  late final Ticker _ticker = createTicker(_tick);
  Duration _lastTick = Duration.zero;

  ValueListenable<Offset?>? _tracker;
  bool _enabled = false;

  /// Window size, cached from dependencies so the global-pointer listener
  /// never performs an inherited lookup outside of build.
  Size _window = Size.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _enabled = context.pointerEffects;
    _window = MediaQuery.sizeOf(context);
    _bindTracker(
      widget.global && _enabled ? PointerTracker.maybeOf(context) : null,
    );
    if (!_enabled) _reset();
  }

  @override
  void didUpdateWidget(covariant PointerTilt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.global != widget.global) {
      _bindTracker(
        widget.global && _enabled ? PointerTracker.maybeOf(context) : null,
      );
      _setTarget(Offset.zero);
    }
  }

  void _bindTracker(ValueListenable<Offset?>? tracker) {
    if (identical(tracker, _tracker)) return;
    _tracker?.removeListener(_onGlobalPointer);
    _tracker = tracker;
    _tracker?.addListener(_onGlobalPointer);
  }

  @override
  void dispose() {
    _tracker?.removeListener(_onGlobalPointer);
    _ticker.dispose();
    _current.dispose();
    super.dispose();
  }

  /// Jump to flat with no animation (reduced motion / effects disabled).
  void _reset() {
    _target = Offset.zero;
    if (_ticker.isActive) _ticker.stop();
    _current.value = Offset.zero;
  }

  void _setTarget(Offset t) {
    if (!_enabled) return;
    final clamped = Offset(t.dx.clamp(-1.0, 1.0), t.dy.clamp(-1.0, 1.0));
    if (clamped == _target) return;
    _target = clamped;
    if (!_ticker.isActive) {
      _lastTick = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration elapsed) {
    final dtFrames = _lastTick == Duration.zero
        ? 1.0
        : (elapsed - _lastTick).inMicroseconds / (1e6 / 60);
    _lastTick = elapsed;
    final k = 1 - math.pow(1 - widget.lerp, dtFrames.clamp(0.0, 4.0));
    final cur = _current.value;
    final delta = _target - cur;
    if (delta.dx.abs() < _settle && delta.dy.abs() < _settle) {
      _current.value = _target;
      _ticker.stop();
      return;
    }
    _current.value = cur + delta * k.toDouble();
  }

  // ── Region mode ────────────────────────────────────────────────────────

  void _onHover(PointerHoverEvent e) {
    final size = context.size;
    if (size == null || size.isEmpty) return;
    _setTarget(
      Offset(
        (e.localPosition.dx / size.width) * 2 - 1,
        (e.localPosition.dy / size.height) * 2 - 1,
      ),
    );
  }

  void _onExit(PointerExitEvent e) => _setTarget(Offset.zero);

  // ── Global mode ────────────────────────────────────────────────────────

  void _onGlobalPointer() {
    final pos = _tracker?.value;
    final box = context.findRenderObject();
    if (pos == null || box is! RenderBox || !box.hasSize || !box.attached) {
      _setTarget(Offset.zero);
      return;
    }
    final window = _window;
    if (window.isEmpty) return;
    final origin = box.localToGlobal(Offset.zero);
    final rect = origin & box.size;
    // Off-screen: relax to flat rather than tracking invisibly.
    if (!rect.overlaps(Offset.zero & window)) {
      _setTarget(Offset.zero);
      return;
    }
    final c = rect.center;
    _setTarget(
      Offset(
        (pos.dx - c.dx) / math.max(1.0, window.width / 2),
        (pos.dy - c.dy) / math.max(1.0, window.height / 2),
      ),
    );
  }

  Matrix4 _matrix(Offset n) {
    final sign = widget.invert ? -1.0 : 1.0;
    // With this perspective a positive rotateY brings the right edge closer,
    // so the pointer side recedes with a negative angle (and vice versa for X).
    final ry = -n.dx * widget.maxYDeg * sign * math.pi / 180;
    final rx = n.dy * widget.maxXDeg * sign * math.pi / 180;
    return Matrix4.identity()
      ..setEntry(3, 2, _perspective)
      ..rotateY(ry)
      ..rotateX(rx);
  }

  @override
  Widget build(BuildContext context) {
    final regionActive = _enabled && !widget.global;
    // The tree shape is identical whether or not effects are enabled, so the
    // child keeps its state across breakpoint changes.
    return MouseRegion(
      opaque: false,
      onHover: regionActive ? _onHover : null,
      onExit: regionActive ? _onExit : null,
      child: ValueListenableBuilder<Offset>(
        valueListenable: _current,
        builder: (context, n, child) => Transform(
          alignment: Alignment.center,
          transform: n == Offset.zero ? Matrix4.identity() : _matrix(n),
          child: child,
        ),
        child: RepaintBoundary(child: widget.child),
      ),
    );
  }
}
