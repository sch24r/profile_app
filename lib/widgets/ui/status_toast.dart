import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../motion/viewport_gate.dart';

/// Bottom-left status pill (P5): a pulsing "live" dot + [text].
///
/// Positioning is the caller's job (e.g. `Positioned(left: 20, bottom: 20)`).
/// [reveal] (0→1) fades it in (used with the intro clock / nav collapse).
/// The pulse loop runs under a [ViewportGate] and stops under reduced motion.
/// Hidden on phones narrower than 380 px (observed spec §5).
class StatusToast extends StatelessWidget {
  const StatusToast({super.key, required this.text, this.reveal});

  final String text;
  final Animation<double>? reveal;

  @override
  Widget build(BuildContext context) {
    if (context.screenWidth < 380) return const SizedBox.shrink();
    final p = context.palette;
    final t = AppType.of(context);

    Widget pill = DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: p.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.s12, 10, Space.s16, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: ViewportGate(child: _PulseDot(color: p.flare)),
            ),
            const SizedBox(width: Space.s8),
            Flexible(
              child: Text(
                text,
                style: t.caption.copyWith(color: p.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );

    pill = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Semantics(
        label: text,
        child: ExcludeSemantics(child: pill),
      ),
    );
    final r = reveal;
    return r == null ? pill : FadeTransition(opacity: r, child: pill);
  }
}

/// 8 px dot with an expanding, fading ring (1.6 s loop).
class _PulseDot extends StatefulWidget {
  const _PulseDot({required this.color});
  final Color color;

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  static const _period = Duration(milliseconds: 1600);
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: const Size.square(16),
        painter: _PulsePainter(_c, widget.color),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  _PulsePainter(this.t, this.color) : super(repaint: t);
  final Animation<double> t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final v = t.value;
    if (v > 0) {
      canvas.drawCircle(
        c,
        4 + 4 * v,
        Paint()..color = color.withValues(alpha: 0.45 * (1 - v)),
      );
    }
    canvas.drawCircle(c, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.color != color || old.t != t;
}
