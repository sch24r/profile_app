import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import 'pressable.dart';

/// Fill / foreground recipes for [PillButton].
enum PillVariant { ink, white, outline, outlineOnDark, lilac, primary }

/// P17 label-roll pill button.
///
/// The label (plus optional trailing [icon]) sits in a clipped box. On hover
/// or keyboard focus it translates up by 100 % of its height while an
/// identical copy enters from below ([Motion.labelRoll], [Motion.expoOut]);
/// leaving reverses it. No fill change, no lift. Press scales to 0.97
/// ([Motion.press]). Keyboard focus draws a 2 px ring. Reduced motion → no
/// roll and no press scale.
///
/// Height: 48 on mobile/tablet (touch target), 44 on desktop.
class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillVariant.ink,
    this.icon,
    this.caps = false,
    this.dense = false,
    this.semanticLabel,
  });

  final String label;

  /// Null disables the button (rendered at 45 % opacity).
  final VoidCallback? onPressed;
  final PillVariant variant;

  /// Optional trailing icon (e.g. `Icons.arrow_forward`); rolls with the label.
  final IconData? icon;

  /// Uppercase + tracked label ([AppType.buttonCaps]).
  final bool caps;

  /// Tighter horizontal padding / smaller type (nav, compact rows).
  final bool dense;
  final String? semanticLabel;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _roll = AnimationController(
    vsync: this,
    duration: Motion.labelRoll,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _roll,
    curve: Motion.expoOut,
    reverseCurve: Motion.expoOut.flipped,
  );
  late final Animation<Offset> _out = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, -1),
  ).animate(_curve);
  late final Animation<Offset> _in = Tween<Offset>(
    begin: const Offset(0, 1),
    end: Offset.zero,
  ).animate(_curve);

  bool _hover = false;
  bool _focus = false;

  @override
  void dispose() {
    _roll.dispose();
    super.dispose();
  }

  void _sync() {
    final on = (_hover || _focus) && widget.onPressed != null;
    if (context.reduceMotion) {
      _roll.value = 0;
      return;
    }
    on ? _roll.forward() : _roll.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final colors = _colorsFor(widget.variant, p);
    final enabled = widget.onPressed != null;
    final desktop = context.isDesktop;

    final height = desktop ? 44.0 : Layout.minTouch;
    final hPad = widget.dense ? Space.s16 : Space.s24;
    final base = widget.caps ? t.buttonCaps : t.button;
    final style = base.copyWith(
      color: colors.fg,
      fontSize: widget.dense ? (base.fontSize ?? 15) - 1 : null,
    );
    final text = widget.caps ? widget.label.toUpperCase() : widget.label;

    // Vertical breathing room inside the clip so descenders (g, p, y) at
    // line-height 1.0 aren't cut by the ClipRect.
    final label = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              style: style,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.icon != null) ...[
            const SizedBox(width: Space.s8),
            Icon(widget.icon, size: 18, color: colors.fg),
          ],
        ],
      ),
    );

    // Two copies inside a ClipRect: the first sizes the box, the second is
    // stacked on top and starts one label-height below (clipped away).
    final rolled = ClipRect(
      child: Stack(
        children: [
          SlideTransition(position: _out, child: label),
          Positioned.fill(
            child: SlideTransition(position: _in, child: label),
          ),
        ],
      ),
    );

    final radius = BorderRadius.circular(height / 2);
    Widget pill = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.fill,
        borderRadius: radius,
        border: colors.border == null
            ? null
            : Border.all(color: colors.border!, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: height, minWidth: height),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Center(widthFactor: 1, heightFactor: 1, child: rolled),
        ),
      ),
    );
    if (!enabled) pill = Opacity(opacity: 0.45, child: pill);

    return Pressable(
      onTap: widget.onPressed,
      borderRadius: radius,
      pressScale: 0.97,
      ringColor: colors.ring,
      semanticLabel: widget.semanticLabel ?? widget.label,
      excludeChildSemantics: true,
      onHoverChanged: (v) {
        _hover = v;
        _sync();
      },
      onFocusHighlightChanged: (v) {
        _focus = v;
        _sync();
      },
      child: pill,
    );
  }
}

class _PillColors {
  const _PillColors(this.fill, this.fg, this.ring, [this.border]);
  final Color fill;
  final Color fg;
  final Color ring;
  final Color? border;
}

_PillColors _colorsFor(PillVariant v, AppPalette p) => switch (v) {
  // Ink pill: inverts with the theme (dark ink on light, light on dark).
  PillVariant.ink => _PillColors(p.ink, p.surface, p.primary),
  // Always-white pill with fixed dark ink (sits on dark / accent bands).
  PillVariant.white => _PillColors(
    const Color(0xFFFFFFFF),
    p.onAccent,
    p.violet300,
  ),
  PillVariant.outline => _PillColors(
    const Color(0x00000000),
    p.ink,
    p.primary,
    p.ink,
  ),
  PillVariant.outlineOnDark => _PillColors(
    const Color(0x00000000),
    p.onDeep,
    p.violet300,
    p.onDeep.withValues(alpha: 0.55),
  ),
  // Observed CTA on dark bands: light-lilac pill with dark text.
  PillVariant.lilac => _PillColors(p.violet300, p.onAccent, p.onDeep),
  PillVariant.primary => _PillColors(p.primary, p.onPrimary, p.ink),
};
