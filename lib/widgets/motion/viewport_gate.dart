import 'package:flutter/widgets.dart';

import '../../core/context_x.dart';
import 'in_view.dart';

/// Continuous (not one-shot) in-viewport check (with [margin] px slack).
/// Wraps child in `TickerMode(enabled: inView && !reduceMotion)`, so every
/// ticker / AnimationController created *below* this widget pauses while it is
/// off-screen and under reduced motion. Only calls setState when the bool
/// flips.
///
/// Starts disabled and enables after the first layout if visible, so loops
/// never tick for content that is built off-screen. Without a vertical
/// Scrollable the child is considered visible.
///
/// ```dart
/// ViewportGate(child: Marquee(children: tiles)) // Marquee already gates itself
/// ```
class ViewportGate extends StatefulWidget {
  const ViewportGate({super.key, required this.child, this.margin = 100});

  final Widget child;

  /// Extra slack (px) around the viewport that still counts as visible.
  final double margin;

  @override
  State<ViewportGate> createState() => _ViewportGateState();
}

class _ViewportGateState extends State<ViewportGate>
    with ViewportListenerMixin<ViewportGate> {
  bool _inView = false;

  @override
  void onViewportChanged() {
    final bool now;
    if (verticalScrollableOf(context) == null) {
      now = context.findRenderObject()?.attached ?? false;
    } else {
      final g = viewportGeometryOf(context);
      now = g != null && g.viewport.inflate(widget.margin).overlaps(g.box);
    }
    if (now != _inView) setState(() => _inView = now);
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(
      enabled: _inView && !context.reduceMotion,
      child: widget.child,
    );
  }
}
