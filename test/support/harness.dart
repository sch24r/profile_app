// Shared helpers for the widget / content / motion tests.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_app/app.dart';
import 'package:profile_app/core/router.dart';
import 'package:profile_app/core/theme_controller.dart';
import 'package:profile_app/data/sections.dart';
import 'package:profile_app/shell/intro_overlay.dart';
import 'package:profile_app/widgets/motion/block_decode_text.dart';
import 'package:profile_app/widgets/motion/two_tone_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

const viewportSizes = <String, Size>{
  '360x740': Size(360, 740),
  '390x844': Size(390, 844),
  '820x1180': Size(820, 1180),
  '1440x900': Size(1440, 900),
  '1920x1080': Size(1920, 1080),
};

/// Card-key kinds each sub-page tab may render (and nothing else).
const tabKinds = <String, Set<String>>{
  'about:profile': {'profile', 'interests', 'languages'},
  'about:education': {'education'},
  'experience:work': {'work'},
  'experience:organizations': {'organizations'},
  'experience:volunteering': {'volunteering'},
  'achievements:podium': {'podium'},
  'achievements:qualifications': {'qualifications'},
  'projects:': {'projects'},
  'skills:': {'skills'},
  'contact:': {},
};

/// Number of rail cards per tab (last card index = count - 1).
const tabCardCounts = <String, int>{
  'about:profile': 5,
  'about:education': 2,
  'experience:work': 4,
  'experience:organizations': 4,
  'experience:volunteering': 12,
  'achievements:podium': 5,
  'achievements:qualifications': 3,
  'projects:': 4,
  'skills:': 5,
};

/// Every (section, tab) pair of the sub-pages; tab null = no tabs.
List<(SiteSection, String?)> get allSubPages => [
  for (final s in SiteSection.values)
    if (s != SiteSection.home)
      if (s.tabs.isEmpty) (s, null) else for (final t in s.tabs) (s, t.$1),
];

String tabId(SiteSection s, String? tab) => '${s.name}:${tab ?? ''}';

/// Configures the test view; resets on tear-down.
void setViewport(
  WidgetTester tester,
  Size size, {
  bool reduceMotion = false,
  String? initialRoute,
}) {
  SharedPreferences.setMockInitialValues({});
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1.0;
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      FakeAccessibilityFeatures(disableAnimations: reduceMotion);
  if (initialRoute != null) {
    tester.platformDispatcher.defaultRouteNameTestValue = initialRoute;
  }
  addTearDown(() {
    tester.view.reset();
    tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    tester.platformDispatcher.clearDefaultRouteNameTestValue();
  });
  IntroOverlay.debugReset();
}

Future<void> pumpApp(
  WidgetTester tester, {
  ThemeMode mode = ThemeMode.light,
  Duration settle = const Duration(milliseconds: 2400),
}) async {
  await tester.pumpWidget(PortfolioApp(theme: ThemeController(mode)));
  await frames(tester, settle);
}

/// Pumps [total] in fixed steps (never pumpAndSettle: loops may run).
Future<void> frames(
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

/// Unmounts the app so no ticker / timer outlives the test.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

NavigatorState nav(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).first);

/// The context of the top-most page (for AppNav calls).
BuildContext topContext(WidgetTester tester) => nav(tester).context;

Future<void> go(WidgetTester tester, SiteSection s, {String? tab}) async {
  AppNav.go(topContext(tester), s, tab: tab);
  await frames(tester, const Duration(milliseconds: 1800));
}

/// Collects `card:<kind>:<i>` keys currently in the tree under [scope].
Set<String> cardKeys(WidgetTester tester, {Finder? scope}) {
  final out = <String>{};
  final finder = find.byWidgetPredicate((w) {
    final k = w.key;
    return k is ValueKey<String> && k.value.startsWith('card:');
  });
  final f = scope == null
      ? finder
      : find.descendant(of: scope, matching: finder);
  for (final e in f.evaluate()) {
    out.add((e.widget.key! as ValueKey<String>).value);
  }
  return out;
}

String kindOf(String cardKey) => cardKey.split(':')[1];

/// Visible-text occurrences of [needle] under [scope]: Text, SelectableText,
/// BlockDecodeText, TwoToneText, and RichText that is not the internal
/// RichText of a Text. Each widget counts once.
int textOccurrences(WidgetTester tester, String needle, {Finder? scope}) {
  bool matches(Widget w) => switch (w) {
    Text(:final data, :final textSpan) =>
      (data ?? textSpan?.toPlainText() ?? '').contains(needle),
    SelectableText(:final data, :final textSpan) =>
      (data ?? textSpan?.toPlainText() ?? '').contains(needle),
    BlockDecodeText(:final lines) => lines.join(' ').contains(needle),
    TwoToneText(:final lines) => lines.join(' ').contains(needle),
    RichText(:final text) => text.toPlainText().contains(needle),
    _ => false,
  };
  final f = find.byWidgetPredicate(matches, skipOffstage: false);
  final scoped = scope == null
      ? f
      : find.descendant(of: scope, matching: f, skipOffstage: false);
  var count = 0;
  for (final e in scoped.evaluate()) {
    if (e.widget is RichText && _insideTextWidget(e)) continue;
    // Skip text excluded from semantics as a visual duplicate (e.g. marquee
    // copies) only when it is also marked as such by ExcludeSemantics.
    count++;
  }
  return count;
}

bool _insideTextWidget(Element e) {
  var depth = 0;
  var inside = false;
  e.visitAncestorElements((a) {
    final w = a.widget;
    if (w is Text ||
        w is SelectableText ||
        w is BlockDecodeText ||
        w is TwoToneText) {
      inside = true;
      return false;
    }
    return ++depth < 8;
  });
  return inside;
}

/// Records SystemNavigator.routeInformationUpdated calls.
List<MethodCall> recordNavigationChannel(WidgetTester tester) {
  final log = <MethodCall>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.navigation,
    (call) async {
      log.add(call);
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.navigation,
      null,
    ),
  );
  return log;
}
