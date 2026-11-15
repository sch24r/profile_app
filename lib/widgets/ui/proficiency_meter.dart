import 'package:flutter/material.dart';

import '../../core/context_x.dart';

/// Static segmented meter (languages): [max] small chamfer-free blocks,
/// the first [level] filled. No animation (observed: meters are static).
class ProficiencyMeter extends StatelessWidget {
  const ProficiencyMeter({
    super.key,
    required this.level,
    this.max = 5,
    this.color,
    this.trackColor,
  });

  final int level;
  final int max;

  /// Filled colour (default `palette.primary`).
  final Color? color;

  /// Empty colour (default `palette.tint200`).
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = color ?? p.primary;
    final off = trackColor ?? p.tint200;
    final filled = level.clamp(0, max);

    return Semantics(
      label: 'Proficiency $filled of $max',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 8,
          child: Row(
            children: [
              for (var i = 0; i < max; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: i < filled ? on : off,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
