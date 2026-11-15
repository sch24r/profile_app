import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;

import '../data/sections.dart';
import '../pages/about_page.dart';
import '../pages/achievements_page.dart';
import '../pages/contact_page.dart';
import '../pages/experience_page.dart';
import '../pages/home_page.dart';
import '../pages/projects_page.dart';
import '../pages/skills_page.dart';
import '../shell/site_shell.dart';
import '../theme/colors.dart';
import '../theme/motion.dart';
import '../widgets/motion/polygon_mask.dart';
import 'context_x.dart';

/// Site navigation. Named routes are [SiteSection.path]s; web URLs come from
/// `usePathUrlStrategy()` in `main.dart`.
///
/// The page stack is kept shallow (root page + at most one page on top) so the
/// browser/back button always returns to the page the visitor came from.
abstract final class AppNav {
  /// Must be registered in `MaterialApp.navigatorObservers` (done in app.dart).
  static final NavigatorObserver observer = _PageStackObserver();

  static _PageStackObserver get _stack => observer as _PageStackObserver;

  /// Navigates to [s], optionally opening [tab] (sub-pages with tabs).
  ///
  /// * Already on [s] → switches to [tab] when given ([setTab]), otherwise
  ///   scrolls Home back to the top.
  /// * [s] is the root page (e.g. home when the visit started on `/`) →
  ///   pops back to it (and switches to [tab] when given).
  /// * Home when the root is a sub-page → pushes home, then drops every page
  ///   below it once it is in place (home becomes the root).
  /// * Otherwise → pushes [s] with the P1 transition; once it is in place,
  ///   any page between the root and [s] is dropped.
  static void go(BuildContext context, SiteSection s, {String? tab}) {
    final nav = Navigator.of(context);
    final pages = _stack.pagesOf(nav);
    final top = pages.isEmpty ? null : pages.last;
    final root = pages.isEmpty ? null : pages.first;

    if (top != null && SiteSection.fromPath(top.settings.name) == s) {
      if (tab != null && s.tabs.isNotEmpty) {
        _setTabOn(top, s, tab);
      } else {
        _scrollToTop(context);
      }
      return;
    }
    if (root != null && SiteSection.fromPath(root.settings.name) == s) {
      nav.popUntil((r) => r == root);
      if (tab != null && s.tabs.isNotEmpty) _setTabOn(root, s, tab);
      return;
    }
    // Home when the visit started elsewhere: home becomes the new root.
    final replaceAll = s == SiteSection.home;
    final route = _routeFor(s, tab);
    nav.push(route);
    // Trim the stack only after the new page fully covers it, so the outgoing
    // page stays visible under the 200 ms overlay hold.
    void trim(AnimationStatus status) {
      if (status != AnimationStatus.completed) return;
      route.animation?.removeStatusListener(trim);
      if (!route.isActive || !nav.mounted) return;
      final current = _stack.pagesOf(nav);
      final index = current.indexOf(route);
      final from = replaceAll ? 0 : 1;
      if (index <= from) return;
      for (final r in current.sublist(from, index)) {
        if (r.isActive) nav.removeRoute(r);
      }
    }

    route.animation?.addStatusListener(trim);
  }

  /// Switches the tab of the current sub-page [s] WITHOUT pushing a route:
  /// updates the page's tab state and replaces the browser URL query.
  static void setTab(BuildContext context, SiteSection s, String tab) {
    final route = ModalRoute.of(context);
    if (route != null && SiteSection.fromPath(route.settings.name) == s) {
      _setTabOn(route, s, tab);
    } else {
      go(context, s, tab: tab);
    }
  }

  /// Tab id of the current route (null if its section has no tabs).
  /// Reflects [setTab] changes; falls back to the section's first tab.
  static String? tabOf(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route == null) return null;
    final s = SiteSection.fromPath(route.settings.name);
    return s.resolveTab(
      _tabs[route] ?? SiteSection.tabFromLocation(route.settings.name),
    );
  }

  /// Per-route tab notifier (created lazily); SubPageShell listens to it.
  static ValueNotifier<String?> tabListenable(BuildContext context) {
    final route = ModalRoute.of(context)!;
    return _tabNotifier(route);
  }

  static final Expando<String> _tabs = Expando('tab');
  static final Expando<ValueNotifier<String?>> _notifiers = Expando('tabN');

  static ValueNotifier<String?> _tabNotifier(Route<dynamic> route) =>
      _notifiers[route] ??= ValueNotifier<String?>(
        SiteSection.fromPath(route.settings.name).resolveTab(
          _tabs[route] ?? SiteSection.tabFromLocation(route.settings.name),
        ),
      );

  static void _setTabOn(Route<dynamic> route, SiteSection s, String tab) {
    final resolved = s.resolveTab(tab);
    if (resolved == null) return;
    _tabs[route] = resolved;
    _tabNotifier(route).value = resolved;
    // Replace (not push) the browser URL; no-op off the web.
    SystemNavigator.routeInformationUpdated(
      uri: Uri.parse(s.location(resolved)),
      replace: true,
    );
  }

  static void _scrollToTop(BuildContext context) {
    final controller = SiteShell.controllerOf(context);
    if (controller == null || !controller.hasClients) return;
    if (context.reduceMotion) {
      controller.jumpTo(0);
    } else {
      controller.animateTo(
        0,
        duration: Motion.scrollToDuration,
        curve: Motion.scrollTo,
      );
    }
  }

  /// `MaterialApp.onGenerateRoute`. Unknown paths resolve to home.
  /// `?tab=` is parsed; an unknown tab resolves to the section's first tab.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) => _routeFor(
    SiteSection.fromPath(settings.name),
    SiteSection.tabFromLocation(settings.name),
    settings.arguments,
  );

  static PolygonRoute<void> _routeFor(
    SiteSection section, [
    String? tab,
    Object? arguments,
  ]) => PolygonRoute<void>(
    settings: RouteSettings(
      name: tab == null ? section.path : section.location(tab),
      arguments: arguments,
    ),
    overlayColor: (context) => overlayColorFor(section, context.palette),
    builder: (_) => pageFor(section),
  );

  /// `MaterialApp.onGenerateInitialRoutes`: a single page (the deep-linked
  /// one) instead of Flutter's default `/` + `/about` stack, so a deep link
  /// never builds the heavy home page off-screen.
  static List<Route<dynamic>> onGenerateInitialRoutes(String initialRoute) => [
    onGenerateRoute(RouteSettings(name: initialRoute)),
  ];

  /// The page widget for [section].
  static Widget pageFor(SiteSection section) => switch (section) {
    SiteSection.home => const HomePage(),
    SiteSection.about => const AboutPage(),
    SiteSection.experience => const ExperiencePage(),
    SiteSection.achievements => const AchievementsPage(),
    SiteSection.projects => const ProjectsPage(),
    SiteSection.skills => const SkillsPage(),
    SiteSection.contact => const ContactPage(),
  };

  /// Destination accent used for the P1 overlay. Home uses `display` so the
  /// hero name reads as carved out of the overlay (P2).
  static Color overlayColorFor(SiteSection section, AppPalette p) =>
      switch (section) {
        SiteSection.home => p.display,
        SiteSection.about => p.deep,
        SiteSection.experience => p.primaryPressed,
        SiteSection.achievements => p.deep,
        SiteSection.projects => p.primaryPressed,
        SiteSection.skills => p.deep,
        SiteSection.contact => p.deep,
      };
}

/// Tracks the navigator's page routes (dialogs / menu routes are ignored).
class _PageStackObserver extends NavigatorObserver {
  final List<Route<dynamic>> _pages = [];

  /// Active page routes of [nav], bottom → top. Stale entries (disposed
  /// navigators, e.g. after a hot restart or in tests) are dropped.
  List<Route<dynamic>> pagesOf(NavigatorState nav) {
    _pages.removeWhere((r) => r.navigator == null);
    return [
      for (final r in _pages)
        if (r.navigator == nav && r.isActive) r,
    ];
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) _pages.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pages.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _pages.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final i = oldRoute == null ? -1 : _pages.indexOf(oldRoute);
    if (newRoute is PageRoute) {
      if (i >= 0) {
        _pages[i] = newRoute;
        return;
      }
      _pages.add(newRoute);
    }
    if (i >= 0) _pages.removeAt(i);
  }
}

/// P1 route transition.
///
/// 0 → [Motion.routeHold]: a solid [overlayColor] fades in over the outgoing
/// page. Then the new (already laid-out, static) page is revealed through the
/// zooming polygon window ([Motion.routeMask]; [Motion.routeMaskMobile] on
/// phones). Reduced motion: a [Motion.reducedFade] cross-fade. Pops play the
/// same transition in reverse.
class PolygonRoute<T> extends PageRouteBuilder<T> {
  PolygonRoute({
    required WidgetBuilder builder,
    required this.overlayColor,
    super.settings,
  }) : super(
         pageBuilder: (context, _, _) => builder(context),
         opaque: true,
         maintainState: true,
       );

  final Color Function(BuildContext context) overlayColor;

  static bool get _reduced =>
      PlatformDispatcher.instance.accessibilityFeatures.disableAnimations;

  static bool get _mobile {
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) return false;
    return view.physicalSize.width / view.devicePixelRatio < Breakpoints.tablet;
  }

  static Duration get _maskDuration =>
      _mobile ? Motion.routeMaskMobile : Motion.routeMask;

  /// Fraction of the transition spent on the solid hold.
  static double get _holdFraction =>
      Motion.routeHold.inMicroseconds /
      (Motion.routeHold + _maskDuration).inMicroseconds;

  @override
  Duration get transitionDuration =>
      _reduced ? Motion.reducedFade : Motion.routeHold + _maskDuration;

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (context.reduceMotion) {
      return FadeTransition(opacity: animation, child: child);
    }
    final hold = _holdFraction;
    return _PolygonTransition(
      animation: animation,
      hold: hold,
      color: overlayColor(context),
      child: child,
    );
  }
}

/// Keeps a constant tree shape (page + curtain) for the whole route lifetime
/// so the page state is never re-mounted; when idle the curtain paints nothing.
class _PolygonTransition extends StatelessWidget {
  const _PolygonTransition({
    required this.animation,
    required this.hold,
    required this.color,
    required this.child,
  });

  final Animation<double> animation;
  final double hold;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // The page is not painted during the hold (alpha 0 skips painting).
        FadeTransition(opacity: _StepAnimation(animation, hold), child: child),
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _RouteCurtainPainter(
                animation: animation,
                hold: hold,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 0 while `parent.value < threshold`, otherwise 1.
class _StepAnimation extends Animation<double>
    with AnimationWithParentMixin<double> {
  _StepAnimation(this.parent, this.threshold);

  @override
  final Animation<double> parent;
  final double threshold;

  @override
  double get value => parent.value < threshold ? 0.0 : 1.0;
}

class _RouteCurtainPainter extends CustomPainter {
  _RouteCurtainPainter({
    required this.animation,
    required this.hold,
    required this.color,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final double hold;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final v = animation.value;
    if (v >= 1.0) return;
    if (v < hold) {
      final a = hold <= 0 ? 1.0 : (v / hold).clamp(0.0, 1.0);
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = color.withValues(alpha: color.a * a),
      );
      return;
    }
    final t = hold >= 1 ? 1.0 : ((v - hold) / (1 - hold)).clamp(0.0, 1.0);
    PolygonCurtainPainter(t: t, color: color).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_RouteCurtainPainter old) =>
      old.color != color || old.hold != hold || old.animation != animation;
}
