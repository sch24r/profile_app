import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../core/router.dart';
import '../data/cv.dart';
import '../data/sections.dart';
import '../theme/motion.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/art/logo_mark.dart';
import '../widgets/ui/pill_button.dart';
import '../widgets/ui/theme_switch.dart';
import 'intro_overlay.dart';
import 'menu_panel.dart';

/// P6 site header (floating overlay at the top of [SiteShell]).
///
/// * Desktop: floating surface bar (inset 20, radius 20, hairline) with the
///   logo, nav links (P19 hover pill trail; the active route keeps its pill),
///   compact theme switch, ink "Contact" pill and a menu circle.
///   On home it collapses (opacity only, [Motion.navFade], sineOut) after
///   scrolling past [Motion.navCollapseVh] of the viewport, leaving the
///   Contact pill + ink menu circle; it re-expands on a scroll-up of more
///   than [Motion.navExpandScrollUp] px or at the top.
/// * Mobile / tablet: always compact — logo chip left, ink menu circle right.
/// * Intro (P4): drops in from [Motion.navDropFrom] on the IntroScope clock.
class SiteHeader extends StatefulWidget {
  const SiteHeader({
    super.key,
    required this.section,
    required this.controller,
  });

  final SiteSection section;
  final ScrollController controller;

  @override
  State<SiteHeader> createState() => _SiteHeaderState();
}

class _SiteHeaderState extends State<SiteHeader>
    with SingleTickerProviderStateMixin {
  static const double _barInset = 20;
  static const double _barHeight = 64;
  static const double _barPadding = 10;

  late final AnimationController _collapse = AnimationController(
    vsync: this,
    duration: Motion.navFade,
  );

  /// Bar fades over the whole collapse; on expand it waits for the compact
  /// cluster to hide first (second half of the reverse run).
  late final Animation<double> _barOpacity = ReverseAnimation(
    CurvedAnimation(
      parent: _collapse,
      curve: Motion.sineOut,
      reverseCurve: const Interval(0, 0.5, curve: Motion.sineOut),
    ),
  );

  late final Animation<double> _compactOpacity = CurvedAnimation(
    parent: _collapse,
    curve: const Interval(0.5, 1, curve: Motion.sineOut),
  );

  final GlobalKey _barKey = GlobalKey();
  final GlobalKey _compactMenuKey = GlobalKey();

  bool _collapsed = false;
  bool _collapsible = false;
  double _lastOffset = 0;
  double _turnOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(SiteHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onScroll);
      widget.controller.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    _collapse.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_collapsible || !widget.controller.hasClients) return;
    final offset = widget.controller.offset;
    final threshold = Motion.navCollapseVh * context.screenHeight;
    final goingDown = offset > _lastOffset;
    final wasGoingDown = _lastOffset > _turnOffset;
    // Remember where the scroll direction last reversed.
    if (offset != _lastOffset && goingDown != wasGoingDown) {
      _turnOffset = _lastOffset;
    }
    _lastOffset = offset;

    var collapsed = _collapsed;
    if (offset <= threshold) {
      collapsed = false;
    } else if (goingDown && offset - _turnOffset > 4) {
      collapsed = true;
    } else if (!goingDown && _turnOffset - offset > Motion.navExpandScrollUp) {
      collapsed = false;
    }
    _setCollapsed(collapsed);
  }

  void _setCollapsed(bool collapsed, {bool animate = true}) {
    if (collapsed == _collapsed) return;
    setState(() => _collapsed = collapsed);
    if (!animate || context.reduceMotion) {
      _collapse.value = collapsed ? 1 : 0;
    } else if (collapsed) {
      _collapse.forward();
    } else {
      _collapse.reverse();
    }
  }

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _openMenu(GlobalKey origin) {
    showMenuPanel(context, current: widget.section, from: _rectOf(origin));
  }

  void _go(SiteSection s) => AppNav.go(context, s);

  @override
  Widget build(BuildContext context) {
    final desktop = context.isDesktop;
    final collapsible = desktop && widget.section == SiteSection.home;
    if (collapsible != _collapsible) {
      _collapsible = collapsible;
      if (!collapsible && _collapsed) {
        // Leaving the collapsible layout: reset without animation.
        _collapsed = false;
        _collapse.value = 0;
      }
    }

    final topInset = MediaQuery.paddingOf(context).top;
    final Widget content = desktop
        ? _buildDesktop(context, topInset)
        : _buildCompact(context, topInset);

    return _IntroDrop(
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: 'Site navigation',
        child: content,
      ),
    );
  }

  Widget _buildDesktop(BuildContext context, double topInset) {
    final p = context.palette;
    final showName = context.screenWidth >= 1200;
    final bar = Container(
      key: _barKey,
      height: _barHeight,
      padding: const EdgeInsets.symmetric(horizontal: _barPadding),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(Radii.panel),
        border: Border.all(color: p.hairline),
      ),
      child: Row(
        children: [
          _HomeLink(showName: showName, onTap: () => _go(SiteSection.home)),
          const SizedBox(width: Space.s24),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final s in SiteSection.navLinks)
                      _NavLink(
                        label: s.label,
                        active: s == widget.section,
                        onTap: () => _go(s),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: Space.s12),
          const ThemeSwitch(compact: true),
          const SizedBox(width: Space.s8),
          PillButton(
            label: 'Contact',
            caps: true,
            dense: true,
            onPressed: () => _go(SiteSection.contact),
          ),
          const SizedBox(width: Space.s8),
          _MenuButton(ink: false, size: 44, onTap: () => _openMenu(_barKey)),
        ],
      ),
    );

    final compact = Padding(
      padding: const EdgeInsets.only(right: _barPadding),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PillButton(
            label: 'Contact',
            caps: true,
            dense: true,
            onPressed: () => _go(SiteSection.contact),
          ),
          const SizedBox(width: Space.s12),
          _MenuButton(
            key: _compactMenuKey,
            ink: true,
            size: 44,
            onTap: () => _openMenu(_barKey),
          ),
        ],
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        _barInset,
        _barInset + topInset,
        _barInset,
        0,
      ),
      child: SizedBox(
        height: _barHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _collapsed,
                child: ExcludeSemantics(
                  excluding: _collapsed,
                  child: FadeTransition(opacity: _barOpacity, child: bar),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              child: IgnorePointer(
                ignoring: !_collapsed,
                child: ExcludeSemantics(
                  excluding: !_collapsed,
                  child: FadeTransition(
                    opacity: _compactOpacity,
                    child: compact,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context, double topInset) {
    final pad = Layout.pagePadding(context.bp);
    final menuKey = _compactMenuKey;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, Space.s16 + topInset, pad, 0),
      child: SizedBox(
        height: Layout.minTouch,
        child: Row(
          children: [
            _LogoChip(onTap: () => _go(SiteSection.home)),
            const Spacer(),
            _MenuButton(
              key: menuKey,
              ink: true,
              size: Layout.minTouch,
              onTap: () => _openMenu(menuKey),
            ),
          ],
        ),
      ),
    );
  }
}

/// P4 nav drop-in on the intro clock (no-op when no intro is running).
class _IntroDrop extends StatelessWidget {
  const _IntroDrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final intro = IntroScope.of(context);
    if (identical(intro, kAlwaysCompleteAnimation)) return child;
    // `drive` adds no listeners until used (nothing to dispose).
    final drop = intro.drive(
      CurveTween(
        curve: Interval(
          IntroScope.navDrop.begin,
          IntroScope.navDrop.end,
          curve: Motion.expoOut,
        ),
      ),
    );
    return AnimatedBuilder(
      animation: drop,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, Motion.navDropFrom * (1 - drop.value)),
        child: child,
      ),
      child: FadeTransition(opacity: drop, child: child),
    );
  }
}

/// Logo (+ full name on wide screens) that routes home.
class _HomeLink extends StatelessWidget {
  const _HomeLink({required this.showName, required this.onTap});

  final bool showName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _Tappable(
      onTap: onTap,
      semanticLabel: '${Cv.contact.name}, home',
      radius: Radii.md,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoMark(color: p.ink, height: 28),
            if (showName) ...[
              const SizedBox(width: Space.s12),
              Text(
                Cv.contact.name,
                style: AppType.of(context).button.copyWith(color: p.ink),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Mobile logo on a small surface chip (stays legible over any band).
class _LogoChip extends StatelessWidget {
  const _LogoChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return _Tappable(
      onTap: onTap,
      semanticLabel: '${Cv.contact.name}, home',
      radius: Radii.pill,
      child: Container(
        height: Layout.minTouch,
        padding: const EdgeInsets.symmetric(horizontal: Space.s16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(Radii.pill),
          border: Border.all(color: p.hairline),
        ),
        child: LogoMark(color: p.ink, height: 22),
      ),
    );
  }
}

/// P19 nav link: hover pill fades in over [Motion.hoverIn] and out over
/// [Motion.hoverOut], so a trail of two pills shows while moving across links.
class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hover = AnimationController(
    vsync: this,
    duration: Motion.hoverIn,
    reverseDuration: Motion.hoverOut,
  );
  late final Animation<double> _pill = CurvedAnimation(
    parent: _hover,
    curve: Motion.sineOut,
  );
  bool _focused = false;

  @override
  void dispose() {
    _hover.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    if (context.reduceMotion) {
      _hover.value = hovering ? 1 : 0;
    } else if (hovering) {
      _hover.forward();
    } else {
      _hover.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = AppType.of(context).button
        .copyWith(color: widget.active ? p.primary : p.ink);
    final radius = BorderRadius.circular(Radii.pill);
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: _onHover,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: Semantics(
        link: true,
        selected: widget.active,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: FadeTransition(
                  opacity: widget.active ? kAlwaysCompleteAnimation : _pill,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: p.hoverPill,
                      borderRadius: radius,
                    ),
                  ),
                ),
              ),
              DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: _focused
                      ? Border.all(color: p.primary, width: 2)
                      : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Space.s16,
                    vertical: 12,
                  ),
                  child: Text(widget.label, style: style),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Circular menu button with a two-line hamburger.
/// [ink] → ink circle (compact nav); otherwise a quiet hover-pill circle.
class _MenuButton extends StatelessWidget {
  const _MenuButton({
    super.key,
    required this.ink,
    required this.size,
    required this.onTap,
  });

  final bool ink;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fill = ink ? p.ink : p.hoverPill;
    final fg = ink ? p.canvas : p.ink;
    return Tooltip(
      message: 'Menu',
      child: _Tappable(
        onTap: onTap,
        semanticLabel: 'Open menu',
        radius: Radii.pill,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
          child: CustomPaint(painter: _HamburgerPainter(fg)),
        ),
      ),
    );
  }
}

class _HamburgerPainter extends CustomPainter {
  const _HamburgerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final w = size.width * 0.36;
    final cx = size.width / 2;
    final cy = size.height / 2;
    canvas.drawLine(
      Offset(cx - w / 2, cy - 3.5),
      Offset(cx + w / 2, cy - 3.5),
      paint,
    );
    canvas.drawLine(
      Offset(cx - w / 2, cy + 3.5),
      Offset(cx + w / 2, cy + 3.5),
      paint,
    );
  }

  @override
  bool shouldRepaint(_HamburgerPainter old) => old.color != color;
}

/// Minimal accessible tap target: click cursor, Enter/Space activation,
/// 2 px primary focus ring, button semantics.
class _Tappable extends StatefulWidget {
  const _Tappable({
    required this.onTap,
    required this.child,
    required this.semanticLabel,
    this.radius = Radii.md,
  });

  final VoidCallback onTap;
  final Widget child;
  final String semanticLabel;
  final double radius;

  @override
  State<_Tappable> createState() => _TappableState();
}

class _TappableState extends State<_Tappable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        label: widget.semanticLabel,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.radius),
              border: _focused
                  ? Border.all(color: context.palette.primary, width: 2)
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
