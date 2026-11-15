import 'package:flutter/widgets.dart';

import '../theme/spacing.dart';
import 'breakpoints.dart';

/// Centers [child] with a max width and responsive horizontal page padding.
class MaxWidth extends StatelessWidget {
  const MaxWidth({
    super.key,
    required this.child,
    this.maxWidth = Layout.maxContent,
    this.padded = true,
  });

  final Widget child;
  final double maxWidth;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final pad = padded ? Layout.pagePadding(context.bp) : 0.0;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth + pad * 2),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: child,
        ),
      ),
    );
  }
}
