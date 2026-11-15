import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../data/models.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'bento_card.dart';

/// Stat bento card: P13 block-decode value ([AppType.stat]) over a caption.
///
/// Hover (pointer devices), keyboard focus or tap swaps the caption for
/// [Stat.detail] (P11/P12 caption swap: fade + 10 px rise, [Motion.chipSwap],
/// expoOut). Both texts are laid out in one stack, so the card never resizes.
/// Reduced motion → instant swap.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.stat, this.tone = CardTone.deep});

  final Stat stat;
  final CardTone tone;

  @override
  Widget build(BuildContext context) => _StatTileBody(stat: stat, tone: tone);
}

class _StatTileBody extends StatefulWidget {
  const _StatTileBody({required this.stat, required this.tone});
  final Stat stat;
  final CardTone tone;

  @override
  State<_StatTileBody> createState() => _StatTileBodyState();
}

class _StatTileBodyState extends State<_StatTileBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swap = AnimationController(
    vsync: this,
    duration: Motion.chipSwap,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _swap,
    curve: Motion.expoOut,
    reverseCurve: Motion.expoOut.flipped,
  );
  late final Animation<double> _captionOpacity = ReverseAnimation(_curve);
  late final Animation<Offset> _captionSlide = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, -0.25),
  ).animate(_curve);
  late final Animation<Offset> _detailSlide = Tween<Offset>(
    begin: const Offset(0, 0.25),
    end: Offset.zero,
  ).animate(_curve);

  bool _hover = false;
  bool _toggled = false;

  @override
  void dispose() {
    _swap.dispose();
    super.dispose();
  }

  void _set({bool? hover, bool? toggled}) {
    _hover = hover ?? _hover;
    _toggled = toggled ?? _toggled;
    final show = _hover || _toggled;
    if (context.reduceMotion) {
      _swap.value = show ? 1 : 0;
    } else {
      show ? _swap.forward() : _swap.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final tones = widget.tone.resolve(context.palette);
    final stat = widget.stat;

    final captionStyle = t.body.copyWith(color: tones.fgMuted);
    final detailStyle = t.body.copyWith(color: tones.fg);

    final swap = ExcludeSemantics(
      child: Stack(
        children: [
          FadeTransition(
            opacity: _captionOpacity,
            child: SlideTransition(
              position: _captionSlide,
              child: Text(stat.caption, style: captionStyle),
            ),
          ),
          // Invisible sizer so the stack is as tall as the longer text.
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Text(stat.detail, style: detailStyle),
          ),
          Positioned.fill(
            child: FadeTransition(
              opacity: _curve,
              child: SlideTransition(
                position: _detailSlide,
                child: Text(stat.detail, style: detailStyle),
              ),
            ),
          ),
        ],
      ),
    );

    final marker = RotationTransition(
      turns: Tween<double>(begin: 0, end: 0.125).animate(_curve),
      child: Icon(Icons.add, size: 20, color: tones.accent),
    );

    final value = Text(stat.value, style: t.stat.copyWith(color: tones.fg));

    final content = LayoutBuilder(
      builder: (context, c) {
        final top = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Align(alignment: Alignment.centerLeft, child: value),
            ),
            const SizedBox(width: Space.s8),
            ExcludeSemantics(child: marker),
          ],
        );
        final caption = Semantics(
          label: '${stat.caption}. ${stat.detail}',
          child: swap,
        );
        if (c.hasBoundedHeight) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              top,
              const SizedBox(height: Space.s16),
              // Takes the remaining height; overlong text is clipped by the
              // card instead of overflowing the column.
              Expanded(
                child: Align(alignment: Alignment.bottomLeft, child: caption),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            top,
            const SizedBox(height: Space.s32),
            caption,
          ],
        );
      },
    );

    return MouseRegion(
      onEnter: (e) {
        if (context.pointerEffects) _set(hover: true);
      },
      onExit: (e) => _set(hover: false),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (f) => _set(hover: f),
        child: BentoCard(
          tone: widget.tone,
          onTap: () => _set(toggled: !_toggled),
          child: content,
        ),
      ),
    );
  }
}
