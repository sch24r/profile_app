import 'package:flutter/widgets.dart';

import '../../core/context_x.dart';
import '../../theme/typography.dart';
import '../ui/chamfer_box.dart';

/// Nav wordmark: "MAR" / "CHELLO" stacked in two tight lines of Unbounded
/// Black, with a chamfered solid block closing the short first line so both
/// lines share one right edge (blocky, like a stamped label).
///
/// Sized by [height]; the width follows the glyphs. Ignores the user's text
/// scale (it's a logo). Semantics: "Marchello".
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.color, this.height = 28});

  /// Defaults to `palette.ink`.
  final Color? color;
  final double height;

  // Design size; the FittedBox scales the whole mark to [height].
  static const _font = 20.0;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.ink;
    final style = TextStyle(
      fontFamily: AppFonts.display,
      fontSize: _font,
      fontWeight: FontWeight.w900,
      fontVariations: const [FontVariation.weight(900)],
      height: 0.92,
      letterSpacing: -0.4,
      color: c,
      decoration: TextDecoration.none,
      leadingDistribution: TextLeadingDistribution.even,
    );

    final mark = IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('MAR', style: style, textScaler: TextScaler.noScaling),
              const SizedBox(width: 3),
              Expanded(
                child: SizedBox(
                  height: _font * 0.7,
                  child: ChamferBox(
                    color: c,
                    chamfer: _font * 0.3,
                    corners: const {Corner.topRight},
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text('CHELLO', style: style, textScaler: TextScaler.noScaling),
        ],
      ),
    );

    return Semantics(
      label: 'Marchello',
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: FittedBox(
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            child: mark,
          ),
        ),
      ),
    );
  }
}
