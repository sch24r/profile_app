import 'package:flutter/widgets.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';

/// P12 chip swap (deck).
///
/// Shows `chips[active]`. When [active] changes the new chip fades in and
/// rises from `+Motion.chipSwapOffset` px, while the old chip fades out and
/// drops *behind* it, drifting up-left by (-10, -10) px. Motion.chipSwap,
/// Motion.expoOut (the outgoing chip uses the flipped curve so it also moves
/// fastest at the start). Transforms + opacity only.
///
/// [clip] clips the deck to its own box (off by default so the drift can
/// overlap neighbours, e.g. a card edge that clips it). Reduced motion →
/// instant swap.
class ChipDeck extends StatelessWidget {
  const ChipDeck({
    super.key,
    required this.chips,
    required this.active,
    this.alignment = Alignment.centerLeft,
    this.clip = false,
    this.duration = Motion.chipSwap,
  });

  final List<Widget> chips;
  final int active;

  /// Alignment of chips of different sizes within the deck.
  final AlignmentGeometry alignment;
  final bool clip;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();
    final index = active.clamp(0, chips.length - 1);
    final current = KeyedSubtree(
      key: ValueKey<int>(index),
      child: chips[index],
    );
    if (context.reduceMotion) return current;

    Widget deck = AnimatedSwitcher(
      duration: duration,
      switchInCurve: Motion.expoOut,
      switchOutCurve: Motion.expoOut.flipped,
      transitionBuilder: (child, animation) =>
          _ChipTransition(animation: animation, child: child),
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: alignment,
        clipBehavior: Clip.none,
        // Previous chips first so they sit behind the incoming one.
        children: [...previousChildren, ?currentChild],
      ),
      child: current,
    );
    if (clip) deck = ClipRect(child: deck);
    return deck;
  }
}

/// Incoming (animation running forward / completed): rise from +offset.
/// Outgoing (reverse): drift towards (-10, -10). Both fade with [animation].
class _ChipTransition extends AnimatedWidget {
  const _ChipTransition({
    required Animation<double> animation,
    required this.child,
  }) : super(listenable: animation);

  final Widget child;

  static const Offset _outDrift = Offset(-10, -10);

  @override
  Widget build(BuildContext context) {
    final animation = listenable as Animation<double>;
    final v = animation.value;
    final outgoing =
        animation.status == AnimationStatus.reverse ||
        animation.status == AnimationStatus.dismissed;
    final offset = outgoing
        ? _outDrift * (1 - v)
        : Offset(0, Motion.chipSwapOffset * (1 - v));
    return ExcludeSemantics(
      excluding: outgoing,
      child: IgnorePointer(
        ignoring: outgoing,
        child: FadeTransition(
          opacity: animation,
          child: Transform.translate(offset: offset, child: child),
        ),
      ),
    );
  }
}
