import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'pressable.dart';

/// P25 segmented toggle: pill track with a sliding thumb
/// ([Motion.segmentThumb], expoOut; reduced motion → jumps).
///
/// Segments share one width (the widest label), so the thumb only translates
/// (paint-only) and the control has a stable intrinsic size. Each segment is
/// a focusable, mutually-exclusive selectable button.
class SegmentedPill<T> extends StatelessWidget {
  const SegmentedPill({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.dense = false,
    this.onDark = false,
  });

  final List<(T value, String label)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool dense;

  /// Colour set for deep / dark bands.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final style = dense ? t.buttonCaps : t.button;

    final track = onDark ? p.onDeep.withValues(alpha: 0.12) : p.tint100;
    final thumb = onDark ? p.onDeep : p.ink;
    final selectedFg = onDark ? p.deep : p.surface;
    final idleFg = onDark ? p.onDeep : p.ink;

    const inset = 4.0;
    final height = context.isDesktop
        ? (dense ? 36.0 : 44.0)
        : (dense ? 44.0 : Layout.minTouch);
    final hPad = dense ? Space.s12 : Space.s20;

    // Equal segment width = widest label + padding.
    var widest = 0.0;
    for (final o in options) {
      final tp = TextPainter(
        text: TextSpan(text: _text(o.$2), style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (tp.width > widest) widest = tp.width;
      tp.dispose();
    }
    final naturalW = (widest + hPad * 2).ceilToDouble();
    final segH = height - inset * 2;

    var index = options.indexWhere((o) => o.$1 == value);
    if (index < 0) index = 0;
    final duration = context.reduceMotion ? Duration.zero : Motion.segmentThumb;

    return LayoutBuilder(
      builder: (context, c) {
        // Shrink segments (labels scale down) if the track would overflow.
        final maxSeg = c.hasBoundedWidth
            ? (c.maxWidth - inset * 2) / options.length
            : double.infinity;
        final segW = naturalW < maxSeg ? naturalW : maxSeg.floorToDouble();
        return Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: _track(
            segW: segW,
            segH: segH,
            height: height,
            index: index,
            duration: duration,
            style: style,
            track: track,
            thumb: thumb,
            selectedFg: selectedFg,
            idleFg: idleFg,
            ring: onDark ? p.violet300 : p.primary,
          ),
        );
      },
    );
  }

  Widget _track({
    required double segW,
    required double segH,
    required double height,
    required int index,
    required Duration duration,
    required TextStyle style,
    required Color track,
    required Color thumb,
    required Color selectedFg,
    required Color idleFg,
    required Color ring,
  }) {
    const inset = 4.0;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(inset),
          child: SizedBox(
            width: segW * options.length,
            height: segH,
            child: Stack(
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: index * segW),
                  duration: duration,
                  curve: Motion.expoOut,
                  builder: (context, x, child) =>
                      Transform.translate(offset: Offset(x, 0), child: child),
                  child: SizedBox(
                    width: segW,
                    height: segH,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: thumb,
                        borderRadius: BorderRadius.circular(segH / 2),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < options.length; i++)
                      Pressable(
                        onTap: () {
                          if (options[i].$1 != value) onChanged(options[i].$1);
                        },
                        borderRadius: BorderRadius.circular(segH / 2),
                        selected: i == index,
                        inMutuallyExclusiveGroup: true,
                        semanticLabel: options[i].$2,
                        excludeChildSemantics: true,
                        ringColor: ring,
                        child: SizedBox(
                          width: segW,
                          height: segH,
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: duration,
                              curve: Motion.expoOut,
                              style: style.copyWith(
                                color: i == index ? selectedFg : idleFg,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _text(options[i].$2),
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _text(String label) => dense ? label.toUpperCase() : label;
}
