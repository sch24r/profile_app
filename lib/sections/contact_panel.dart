import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../core/links.dart';
import '../core/max_width.dart';
import '../data/cv.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/motion/block_decode_text.dart';
import '../widgets/motion/pointer_tilt.dart';
import '../widgets/ui/chamfer_box.dart';
import '../widgets/ui/fit_height.dart';
import '../widgets/ui/pill_button.dart';
import '../widgets/ui/round_icon_button.dart';

/// Home row 10 and the whole /contact body.
///
/// A `deep` panel with a chamfered top edge: P13 block-decoded
/// "LET'S WORK / TOGETHER" inside a P18 [PointerTilt] (desktop pointer
/// only), then P17 pills — email (+ copy), LinkedIn and phone (when
/// [Cv.showPhone]). No location (that lives in the hero toast).
///
/// [fill] = false (Home): section padding, intrinsic height.
/// [fill] = true (/contact): fills the parent's height (no rail, no scroll);
/// the content is centred and guarded by [FitHeight].
class ContactPanel extends StatelessWidget {
  const ContactPanel({super.key, this.fill = false});

  final bool fill;

  static const _titleLines = ["LET'S WORK", 'TOGETHER'];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bp = context.bp;
    final mobile = context.isMobile;
    final pad = mobile ? Space.s24 : (context.isTablet ? Space.s40 : Space.s64);

    final content = _ContactContent(
      titleLines: _titleLines,
      showEyebrow: !fill,
      compact: fill,
    );

    final Widget panelChild;
    if (fill) {
      panelChild = LayoutBuilder(
        builder: (context, box) => FitHeight(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: box.hasBoundedHeight ? box.maxHeight : 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [content],
            ),
          ),
        ),
      );
    } else {
      panelChild = content;
    }

    final panel = ChamferBox(
      color: p.deep,
      corners: const {Corner.topLeft, Corner.topRight},
      padding: EdgeInsets.all(pad),
      child: panelChild,
    );

    if (fill) {
      return SizedBox.expand(
        key: const ValueKey('contact-panel'),
        child: MaxWidth(child: SizedBox.expand(child: panel)),
      );
    }
    return Padding(
      key: const ValueKey('contact-panel'),
      padding: EdgeInsets.symmetric(vertical: Layout.sectionPadding(bp)),
      child: MaxWidth(child: panel),
    );
  }
}

class _ContactContent extends StatelessWidget {
  const _ContactContent({
    required this.titleLines,
    required this.showEyebrow,
    required this.compact,
  });

  final List<String> titleLines;
  final bool showEyebrow;

  /// /contact: the page header already carries the eyebrow + title, so the
  /// panel headline is one step smaller.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final mobile = context.isMobile;

    Widget headline = Semantics(
      header: true,
      child: BlockDecodeText(
        titleLines,
        style: (compact ? t.displayM : t.displayL).copyWith(color: p.onDeep),
      ),
    );
    if (context.pointerEffects) {
      headline = PointerTilt(child: headline);
    }

    final email = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: PillButton(
            key: const ValueKey('contact:email'),
            variant: PillVariant.white,
            label: Cv.contact.email,
            icon: Icons.mail_outline_rounded,
            semanticLabel: 'Email ${Cv.contact.email}',
            onPressed: Links.email,
          ),
        ),
        const SizedBox(width: Space.s8),
        RoundIconButton(
          key: const ValueKey('contact:copy'),
          icon: Icons.copy_rounded,
          tooltip: 'Copy email address',
          variant: RoundVariant.onDark,
          size: context.isDesktop ? 44 : Layout.minTouch,
          onPressed: () =>
              Links.copy(context, Cv.contact.email, 'Email address copied'),
        ),
      ],
    );

    const linkedin = PillButton(
      key: ValueKey('contact:linkedin'),
      variant: PillVariant.outlineOnDark,
      label: 'LinkedIn',
      icon: Icons.open_in_new_rounded,
      semanticLabel: 'LinkedIn profile',
      onPressed: Links.linkedin,
    );

    final phone = Cv.showPhone
        ? PillButton(
            key: const ValueKey('contact:phone'),
            variant: PillVariant.outlineOnDark,
            label: Cv.contact.phoneDisplay,
            icon: Icons.call_outlined,
            semanticLabel: 'Call ${Cv.contact.phoneDisplay}',
            onPressed: Links.phone,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showEyebrow) ...[
          Text('// CONTACT', style: t.label.copyWith(color: p.violet300)),
          const SizedBox(height: Space.s16),
        ],
        headline,
        SizedBox(height: mobile ? Space.s24 : Space.s40),
        Wrap(
          spacing: Space.s12,
          runSpacing: Space.s12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [email, linkedin, ?phone],
        ),
      ],
    );
  }
}
