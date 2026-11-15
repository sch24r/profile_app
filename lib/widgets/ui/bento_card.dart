import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import 'pressable.dart';

/// Flat bento card (observed: radius 12, no shadow, no lift, no scale).
///
/// Fill comes from [tone]; descendants get `DefaultTextStyle(color: fg)` and
/// `IconTheme(color: fg)`, and can read the full colour set with
/// [BentoCard.tonesOf]. [outlined] → transparent fill with a 1 px hairline
/// border (still uses the tone's foreground for text).
///
/// [onTap] makes the card a focusable button (Enter/Space, focus ring).
class BentoCard extends StatelessWidget {
  const BentoCard({
    super.key,
    required this.child,
    this.tone = CardTone.surface,
    this.padding,
    this.radius = Radii.card,
    this.outlined = false,
    this.onTap,
    this.height,
    this.width,
  });

  final Widget child;
  final CardTone tone;

  /// Defaults to 24 (20 on mobile).
  final EdgeInsetsGeometry? padding;
  final double radius;
  final bool outlined;
  final VoidCallback? onTap;
  final double? height;
  final double? width;

  /// Colours of the nearest enclosing [BentoCard] (surface tone if none).
  static ToneColors tonesOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BentoTones>()?.tones ??
      CardTone.surface.resolve(context.palette);

  @override
  Widget build(BuildContext context) {
    final tones = tone.resolve(context.palette);
    final pad =
        padding ?? EdgeInsets.all(context.isMobile ? Space.s20 : Space.s24);
    final shape = BorderRadius.circular(radius);

    Widget card = Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: outlined ? null : tones.fill,
        borderRadius: shape,
        border: outlined
            ? Border.all(color: tones.fg.withValues(alpha: 0.2))
            : null,
      ),
      padding: pad,
      child: _BentoTones(
        tones: tones,
        child: IconTheme.merge(
          data: IconThemeData(color: tones.fg),
          child: DefaultTextStyle.merge(
            style: TextStyle(color: tones.fg),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      card = Pressable(
        onTap: onTap,
        borderRadius: shape,
        ringColor: tone == CardTone.deep
            ? context.palette.violet300
            : context.palette.primary,
        child: card,
      );
    }
    return card;
  }
}

class _BentoTones extends InheritedWidget {
  const _BentoTones({required this.tones, required super.child});
  final ToneColors tones;

  @override
  bool updateShouldNotify(_BentoTones old) =>
      old.tones.fill != tones.fill ||
      old.tones.fg != tones.fg ||
      old.tones.fgMuted != tones.fgMuted ||
      old.tones.accent != tones.accent;
}
