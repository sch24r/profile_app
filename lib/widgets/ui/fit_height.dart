import 'package:flutter/material.dart';

/// Overflow guard for fixed-height cards (rail cards, pinned bento cards):
/// lays [child] out at the available WIDTH with unbounded height, and if the
/// result is taller than the available height scales it down uniformly
/// (never up). The child must not contain Expanded/Spacer in its main axis.
class FitHeight extends StatelessWidget {
  const FitHeight({
    super.key,
    required this.child,
    this.alignment = Alignment.topLeft,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (!c.hasBoundedWidth || !c.hasBoundedHeight) return child;
        return SizedBox(
          width: c.maxWidth,
          height: c.maxHeight,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alignment,
            child: SizedBox(width: c.maxWidth, child: child),
          ),
        );
      },
    );
  }
}
