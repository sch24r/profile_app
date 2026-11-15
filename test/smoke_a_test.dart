// Layer-A smoke test: boots the app at phone and desktop sizes, with and
// without reduced motion, plays the home intro, and navigates to every page
// via AppNav. Asserts no framework exceptions along the way.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_app/app.dart';
import 'package:profile_app/core/router.dart';
import 'package:profile_app/core/theme_controller.dart';
import 'package:profile_app/data/sections.dart';
import 'package:profile_app/pages/about_page.dart';
import 'package:profile_app/pages/achievements_page.dart';
import 'package:profile_app/pages/contact_page.dart';
import 'package:profile_app/pages/experience_page.dart';
import 'package:profile_app/pages/home_page.dart';
import 'package:profile_app/pages/projects_page.dart';
import 'package:profile_app/pages/skills_page.dart';
import 'package:profile_app/shell/intro_overlay.dart';
import 'package:profile_app/shell/menu_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pageTypes = <SiteSection, Type>{
  SiteSection.home: HomePage,
  SiteSection.about: AboutPage,
  SiteSection.experience: ExperiencePage,
  SiteSection.achievements: AchievementsPage,
  SiteSection.projects: ProjectsPage,
  SiteSection.skills: SkillsPage,
  SiteSection.contact: ContactPage,
};

/// Pumps [total] in fixed frame steps (never pumpAndSettle: loops may run).
Future<void> _frames(
  WidgetTester tester,
  Duration total, {
  Duration step = const Duration(milliseconds: 50),
}) async {
  var elapsed = Duration.zero;
  while (elapsed < total) {
    await tester.pump(step);
    elapsed += step;
  }
}

NavigatorState _nav(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).first);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const sizes = <String, Size>{
    'phone 390x844': Size(390, 844),
    'desktop 1440x900': Size(1440, 900),
  };

  for (final MapEntry(key: label, value: size) in sizes.entries) {
    for (final reduce in [false, true]) {
      testWidgets('$label, disableAnimations=$reduce', (tester) async {
        tester.view
          ..physicalSize = size
          ..devicePixelRatio = 1.0;
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            FakeAccessibilityFeatures(disableAnimations: reduce);
        addTearDown(() {
          tester.view.reset();
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
        });
        IntroOverlay.debugReset();

        await tester.pumpWidget(
          PortfolioApp(theme: ThemeController(ThemeMode.light)),
        );
        // Let the once-per-session intro play out (1.8 s).
        await _frames(tester, const Duration(milliseconds: 2400));
        expect(tester.takeException(), isNull);
        expect(find.byType(HomePage), findsOneWidget);

        // Scroll the home page a little (header collapse etc.).
        await tester.drag(
          find.byType(CustomScrollView).first,
          const Offset(0, -400),
        );
        await _frames(tester, const Duration(milliseconds: 600));
        expect(tester.takeException(), isNull);

        // Open and close the menu panel.
        showMenuPanel(_nav(tester).context, current: SiteSection.home);
        await _frames(tester, const Duration(milliseconds: 1200));
        expect(tester.takeException(), isNull, reason: 'menu open');
        _nav(tester).pop();
        await _frames(tester, const Duration(milliseconds: 1200));
        expect(tester.takeException(), isNull, reason: 'menu close');

        const order = [
          SiteSection.about,
          SiteSection.experience,
          SiteSection.achievements,
          SiteSection.projects,
          SiteSection.skills,
          SiteSection.contact,
          SiteSection.home,
          SiteSection.projects,
          SiteSection.projects, // same page → scroll to top
          SiteSection.home,
        ];
        for (final s in order) {
          AppNav.go(_nav(tester).context, s);
          await _frames(tester, const Duration(milliseconds: 1600));
          expect(tester.takeException(), isNull, reason: 'navigating to $s');
          expect(
            find.byType(_pageTypes[s]!),
            findsWidgets,
            reason: 'page for $s is shown',
          );
        }

        // Unmount so no tickers/timers outlive the test.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('deep link starts on the requested page', (tester) async {
    tester.view
      ..physicalSize = const Size(1440, 900)
      ..devicePixelRatio = 1.0;
    tester.platformDispatcher.defaultRouteNameTestValue = '/skills';
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearDefaultRouteNameTestValue();
    });
    IntroOverlay.debugReset();

    await tester.pumpWidget(
      PortfolioApp(theme: ThemeController(ThemeMode.dark)),
    );
    await _frames(tester, const Duration(milliseconds: 600));
    expect(find.byType(SkillsPage), findsOneWidget);
    expect(find.byType(HomePage), findsNothing);

    AppNav.go(_nav(tester).context, SiteSection.home);
    await _frames(tester, const Duration(milliseconds: 1600));
    expect(find.byType(HomePage), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
