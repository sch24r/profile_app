import 'dart:ui' show PlatformDispatcher, lerpDouble;

import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../core/router.dart';
import '../data/cv.dart';
import '../data/sections.dart';
import '../theme/colors.dart';
import '../theme/motion.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/art/logo_mark.dart';
import '../widgets/motion/chip_deck.dart';
import '../widgets/ui/bento_card.dart';
import '../widgets/ui/chip_tag.dart';
import '../widgets/ui/round_icon_button.dart';
import '../widgets/ui/theme_switch.dart';

/// Opens the mega-menu panel (P19/P20).
///
/// The page washes toward `palette.scrim` while a surface panel grows from
/// [from] (the nav bar / menu button rect in global coordinates; defaults to
/// the header strip) to the viewport minus a 12 px frame ([Motion.menuOpen],
/// expoOut; closes in [Motion.menuClose]). The content fades in together on
/// `Interval(0.4, 1)`. It holds the theme switch (P20), a close ✕ and the 6
/// coloured route cards ([SiteSection.menuCards]) whose chips swap on hover
/// (P12; long-press on touch). No contact details or location (those live in
/// ContactPanel and the hero toast). Tapping a card closes the menu, then calls
/// [AppNav.go] with [context].
Future<void> showMenuPanel(
  BuildContext context, {
  required SiteSection current,
  Rect? from,
}) {
  return Navigator.of(
    context,
  ).push<void>(_MenuRoute(pageContext: context, current: current, from: from));
}

class _MenuRoute extends PopupRoute<void> {
  _MenuRoute({
    required this.pageContext,
    required this.current,
    required this.from,
  });

  final BuildContext pageContext;
  final SiteSection current;
  final Rect? from;

  static bool get _reduced =>
      PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;

  @override
  Color? get barrierColor => null; // the scrim is painted by the page (theme-aware)

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Close menu';

  @override
  Duration get transitionDuration =>
      _reduced ? Motion.reducedFade : Motion.menuOpen;

  @override
  Duration get reverseTransitionDuration =>
      _reduced ? Motion.reducedFade : Motion.menuClose;

  void _select(BuildContext menuContext, SiteSection s) {
    Navigator.of(menuContext).pop();
    if (pageContext.mounted) AppNav.go(pageContext, s);
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: 'Site menu',
      child: _MenuPanel(
        animation: animation,
        from: from,
        current: current,
        onSelect: (s) => _select(context, s),
        onClose: () => Navigator.of(context).maybePop(),
      ),
    );
  }
}

class _MenuPanel extends StatefulWidget {
  const _MenuPanel({
    required this.animation,
    required this.from,
    required this.current,
    required this.onSelect,
    required this.onClose,
  });

  final Animation<double> animation;
  final Rect? from;
  final SiteSection current;
  final ValueChanged<SiteSection> onSelect;
  final VoidCallback onClose;

  @override
  State<_MenuPanel> createState() => _MenuPanelState();
}

class _MenuPanelState extends State<_MenuPanel> {
  static const double _frame = 12;

  late final CurvedAnimation _grow = CurvedAnimation(
    parent: widget.animation,
    curve: Motion.expoOut,
    reverseCurve: Motion.expoOut.flipped,
  );
  late final CurvedAnimation _scrim = CurvedAnimation(
    parent: widget.animation,
    curve: const Interval(0, 0.6, curve: Motion.sineOut),
  );
  late final CurvedAnimation _content = CurvedAnimation(
    parent: widget.animation,
    curve: const Interval(0.4, 1, curve: Motion.sineOut),
  );

  @override
  void dispose() {
    _grow.dispose();
    _scrim.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduce = context.reduceMotion;
    final padding = MediaQuery.paddingOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final target = Rect.fromLTRB(
          _frame + padding.left,
          _frame + padding.top,
          size.width - _frame - padding.right,
          size.height - _frame - padding.bottom,
        );
        final origin = (widget.from ?? _defaultOrigin(context, size)).shift(
          -target.topLeft,
        );
        final panel = ColoredBox(
          color: p.surface,
          child: FadeTransition(
            opacity: reduce ? widget.animation : _content,
            child: _PanelContent(
              current: widget.current,
              onSelect: widget.onSelect,
              onClose: widget.onClose,
            ),
          ),
        );
        return Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: _scrim,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onClose,
                  child: ColoredBox(color: p.scrim),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: target,
              child: reduce
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.panel),
                      child: panel,
                    )
                  : ClipRRect(
                      clipper: _GrowClipper(
                        animation: _grow,
                        from: origin,
                        fromRadius: _radiusFor(origin),
                      ),
                      child: panel,
                    ),
            ),
          ],
        );
      },
    );
  }

  double _radiusFor(Rect r) =>
      r.shortestSide <= 56 ? r.shortestSide / 2 : Radii.panel;

  Rect _defaultOrigin(BuildContext context, Size size) {
    final top = MediaQuery.paddingOf(context).top;
    return context.isDesktop
        ? Rect.fromLTWH(20, 20 + top, size.width - 40, 64)
        : Rect.fromLTWH(size.width - 20 - 48, 16 + top, 48, 48);
  }
}

/// Lerps the panel clip from the nav rect to the full panel bounds.
class _GrowClipper extends CustomClipper<RRect> {
  _GrowClipper({
    required this.animation,
    required this.from,
    required this.fromRadius,
  }) : super(reclip: animation);

  final Animation<double> animation;
  final Rect from;
  final double fromRadius;

  @override
  RRect getClip(Size size) {
    final t = animation.value;
    final to = Offset.zero & size;
    final rect = Rect.lerp(from, to, t)!.intersect(to);
    final r = lerpDouble(fromRadius, Radii.panel, t)!;
    return RRect.fromRectAndRadius(rect, Radius.circular(r));
  }

  @override
  bool shouldReclip(_GrowClipper old) =>
      old.from != from ||
      old.fromRadius != fromRadius ||
      old.animation != animation;
}

/// Header (logo, theme switch, ✕) + the 6 route cards.
class _PanelContent extends StatelessWidget {
  const _PanelContent({
    required this.current,
    required this.onSelect,
    required this.onClose,
  });

  final SiteSection current;
  final ValueChanged<SiteSection> onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final bp = context.bp;
    final compact = bp != Bp.desktop || context.screenHeight < 560;
    final pad = bp == Bp.mobile ? Space.s16 : Space.s24;
    final cards = [
      for (final (i, s) in SiteSection.menuCards.indexed)
        _MenuCard(
          index: i,
          section: s,
          current: s == current,
          onTap: () => onSelect(s),
        ),
    ];

    final header = Row(
      children: [
        LogoMark(color: context.palette.ink, height: 28),
        const Spacer(),
        if (bp != Bp.mobile) ...[
          const ThemeSwitch(),
          const SizedBox(width: Space.s12),
        ],
        RoundIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Close menu',
          variant: RoundVariant.neutral,
          size: bp == Bp.mobile ? Layout.minTouch : 44,
          onPressed: onClose,
        ),
      ],
    );

    if (compact) {
      // Scrollable list (phones, tablets, short desktop windows).
      final columns = bp == Bp.mobile ? 1 : 2;
      return Padding(
        padding: EdgeInsets.fromLTRB(pad, pad, pad, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: Space.s16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: pad),
                children: [
                  if (bp == Bp.mobile) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: ThemeSwitch(),
                    ),
                    const SizedBox(height: Space.s16),
                  ],
                  _CardGrid(
                    cards: cards,
                    columns: columns,
                    cardHeight: bp == Bp.mobile ? 128 : 168,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: Space.s24),
          Expanded(child: _CardGrid(cards: cards, columns: 3)),
        ],
      ),
    );
  }
}

/// Lays [cards] out in rows of [columns]. With [cardHeight] null the rows
/// share the available height equally (desktop panel).
class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.cards,
    required this.columns,
    this.cardHeight,
  });

  final List<Widget> cards;
  final int columns;
  final double? cardHeight;

  @override
  Widget build(BuildContext context) {
    const gap = Space.s12;
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += columns) {
      final row = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var j = 0; j < columns; j++) ...[
            if (j > 0) const SizedBox(width: gap),
            Expanded(
              child: i + j < cards.length ? cards[i + j] : const SizedBox(),
            ),
          ],
        ],
      );
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      rows.add(
        cardHeight == null
            ? Expanded(child: row)
            : SizedBox(height: cardHeight, child: row),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: cardHeight == null ? MainAxisSize.max : MainAxisSize.min,
      children: rows,
    );
  }
}

/// A coloured route card. Hover (or long-press on touch) swaps its chip (P12).
class _MenuCard extends StatefulWidget {
  const _MenuCard({
    required this.index,
    required this.section,
    required this.current,
    required this.onTap,
  });

  final int index;
  final SiteSection section;
  final bool current;
  final VoidCallback onTap;

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool _alt = false;

  static CardTone _toneOf(SiteSection s) => switch (s) {
    // spec §2.1: About lilac, Experience periwinkle, Achievements deep,
    // Projects mint, Skills peach, Contact violet.
    SiteSection.about => CardTone.lilac,
    SiteSection.experience => CardTone.periwinkle,
    SiteSection.achievements => CardTone.deep,
    SiteSection.projects => CardTone.mint,
    SiteSection.skills => CardTone.peach,
    SiteSection.contact || SiteSection.home => CardTone.violet,
  };

  static ChipStyle _chipStyleOf(CardTone tone) => switch (tone) {
    CardTone.deep => ChipStyle.onDark,
    CardTone.periwinkle ||
    CardTone.mint ||
    CardTone.peach ||
    CardTone.violet => ChipStyle.onAccent,
    _ => ChipStyle.outline,
  };

  /// Two chip labels per card, all derived from [Cv].
  static (String, String) _chipsOf(SiteSection s) => switch (s) {
    SiteSection.about => (Cv.focusAreas.first, Cv.focusAreas.last),
    SiteSection.experience => (
      '${Cv.occupations.length} roles',
      Cv.recentOccupations(1).first.role,
    ),
    SiteSection.achievements => (
      '${Cv.achievements.length} results',
      Cv.podiumByRecency.first.event,
    ),
    SiteSection.projects => (
      '${Cv.projects.length} projects',
      Cv.recentProjects(1).first.title,
    ),
    SiteSection.skills => (
      '${Cv.skills.length} skill groups',
      Cv.skills.first.title,
    ),
    SiteSection.contact || SiteSection.home => ('Email', 'LinkedIn'),
  };

  void _setAlt(bool v) {
    if (v != _alt) setState(() => _alt = v);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final tone = _toneOf(widget.section);
    final colors = tone.resolve(context.palette);
    final chipStyle = _chipStyleOf(tone);
    final (a, b) = _chipsOf(widget.section);
    final hoverCapable = context.pointerEffects;

    final card = BentoCard(
      tone: tone,
      onTap: widget.onTap,
      padding: EdgeInsets.all(context.isMobile ? Space.s16 : Space.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.current
                    ? 'YOU ARE HERE'
                    : (widget.index + 1).toString().padLeft(2, '0'),
                style: t.label.copyWith(color: colors.fgMuted),
              ),
              const SizedBox(width: Space.s12),
              Expanded(
                child: ExcludeSemantics(
                  child: ChipDeck(
                    alignment: Alignment.centerRight,
                    active: _alt ? 1 : 0,
                    chips: [
                      ChipTag(a, style: chipStyle),
                      ChipTag(b, style: chipStyle),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              widget.section.label,
              style: t.displayS.copyWith(color: colors.fg),
              maxLines: 1,
            ),
          ),
          const SizedBox(height: Space.s4),
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.section.subtitle,
                  style: t.caption.copyWith(color: colors.fgMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 20, color: colors.fg),
            ],
          ),
        ],
      ),
    );

    return MouseRegion(
      onEnter: hoverCapable ? (_) => _setAlt(true) : null,
      onExit: hoverCapable ? (_) => _setAlt(false) : null,
      child: GestureDetector(
        onLongPress: hoverCapable ? null : () => _setAlt(!_alt),
        child: card,
      ),
    );
  }
}
