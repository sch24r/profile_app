// Responsive smoke + navigation tests (docs/plan.md › Verification).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_app/data/sections.dart';
import 'package:profile_app/pages/experience_page.dart';
import 'package:profile_app/pages/home_page.dart';
import 'package:profile_app/shell/sub_page_shell.dart';
import 'package:profile_app/widgets/motion/horizontal_rail.dart';
import 'package:profile_app/widgets/ui/segmented_pill.dart';

import 'support/harness.dart';

/// Key of the last rail card per tab.
const _lastCard = <String, String>{
  'about:profile': 'card:languages:0',
  'about:education': 'card:education:1',
  'experience:work': 'card:work:3',
  'experience:organizations': 'card:organizations:3',
  'experience:volunteering': 'card:volunteering:11',
  'achievements:podium': 'card:podium:4',
  'achievements:qualifications': 'card:qualifications:2',
  'projects:': 'card:projects:3',
  'skills:': 'card:skills:4',
};

Finder get _verticalScrollables => find.byWidgetPredicate(
  (w) =>
      w is Scrollable && axisDirectionToAxis(w.axisDirection) == Axis.vertical,
);

ScrollableState _homeScrollable(WidgetTester tester) => tester
    .stateList<ScrollableState>(
      find.descendant(
        of: find.byType(HomePage),
        matching: _verticalScrollables,
      ),
    )
    .first;

Future<void> _scrollHomeToBottom(WidgetTester tester, Size size) async {
  final position = _homeScrollable(tester).position;
  var guard = 0;
  while (position.pixels < position.maxScrollExtent - 0.5 && guard++ < 400) {
    position.jumpTo(
      (position.pixels + size.height * 0.6).clamp(
        0.0,
        position.maxScrollExtent,
      ),
    );
    await frames(tester, const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull, reason: 'home @ ${position.pixels}');
  }
  expect(position.pixels, closeTo(position.maxScrollExtent, 1));
}

Future<void> _checkSubPage(
  WidgetTester tester,
  SiteSection s,
  String? tab,
  Size size,
) async {
  final id = tabId(s, tab);
  final shell = find.byType(SubPageShell);
  expect(shell, findsOneWidget, reason: '$id uses SubPageShell');
  // One screen: no vertical scroll view anywhere on the page.
  expect(
    find.descendant(of: shell, matching: _verticalScrollables),
    findsNothing,
    reason: '$id must not scroll vertically',
  );
  // Only this tab's card kinds are built.
  final kinds = cardKeys(tester, scope: shell).map(kindOf).toSet();
  expect(
    kinds.difference(tabKinds[id]!),
    isEmpty,
    reason: '$id builds only its own cards (found $kinds)',
  );
  final last = _lastCard[id];
  if (last == null) return; // /contact: no rail
  expect(find.byType(HorizontalRail), findsOneWidget, reason: id);
  expect(kinds, isNotEmpty, reason: '$id renders cards');

  // The rail reaches the last card.
  final rail = tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byType(HorizontalRail),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  expect(axisDirectionToAxis(rail.widget.axisDirection), Axis.horizontal);
  rail.position.jumpTo(rail.position.maxScrollExtent);
  await frames(tester, const Duration(milliseconds: 700));
  expect(tester.takeException(), isNull, reason: '$id rail end');
  final lastCard = find.byKey(ValueKey(last));
  expect(lastCard, findsOneWidget, reason: '$id last card $last');
  final r = tester.getRect(lastCard);
  expect(
    r.right,
    lessThanOrEqualTo(size.width + 0.5),
    reason: '$id $last on screen',
  );
  expect(r.left, greaterThanOrEqualTo(-0.5), reason: '$id $last on screen');
  expect(r.bottom, lessThanOrEqualTo(size.height + 0.5), reason: '$id fits');
}

void main() {
  for (final MapEntry(key: label, value: size) in viewportSizes.entries) {
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('smoke $label ${mode.name}: home + every route and tab', (
        tester,
      ) async {
        setViewport(tester, size);
        await pumpApp(tester, mode: mode);
        expect(tester.takeException(), isNull);
        expect(find.byType(HomePage), findsOneWidget);

        await _scrollHomeToBottom(tester, size);

        for (final (s, tab) in allSubPages) {
          await go(tester, s, tab: tab);
          expect(tester.takeException(), isNull, reason: tabId(s, tab));
          await _checkSubPage(tester, s, tab, size);
        }

        await go(tester, SiteSection.home);
        expect(find.byType(HomePage), findsOneWidget);
        expect(tester.takeException(), isNull);
        await unmount(tester);
      });
    }
  }

  testWidgets('switching tabs replaces the URL query without pushing', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 844), initialRoute: '/experience');
    final log = recordNavigationChannel(tester);
    await pumpApp(tester, settle: const Duration(milliseconds: 1200));
    expect(find.byType(ExperiencePage), findsOneWidget);
    final routeBefore = ModalRoute.of(
      tester.element(find.byType(ExperiencePage)),
    );
    expect(cardKeys(tester).map(kindOf).toSet(), {'work'});

    for (final (id, label) in const [
      ('organizations', 'Organizations'),
      ('volunteering', 'Volunteering'),
      ('work', 'Work'),
    ]) {
      log.clear();
      await tester.tap(
        find.descendant(
          of: find.byType(SegmentedPill<String>),
          // Dense (mobile) pills render labels in caps.
          matching: find.byWidgetPredicate(
            (w) => w is Text && w.data?.toLowerCase() == label.toLowerCase(),
          ),
        ),
      );
      await frames(tester, const Duration(milliseconds: 900));
      expect(tester.takeException(), isNull);

      final updates = log.where((c) => c.method == 'routeInformationUpdated');
      expect(updates, isNotEmpty, reason: 'URL updated for $id');
      final args = (updates.last.arguments as Map).cast<String, Object?>();
      expect(args['uri'] ?? args['location'], '/experience?tab=$id');
      expect(args['replace'], isTrue);

      expect(find.byType(ExperiencePage), findsOneWidget, reason: 'no push');
      expect(
        ModalRoute.of(tester.element(find.byType(ExperiencePage))),
        same(routeBefore),
      );
      expect(cardKeys(tester).map(kindOf).toSet(), {
        id,
      }, reason: 'only the $id tab is built');
    }
    await unmount(tester);
  });

  testWidgets('deep link with ?tab= opens that tab; unknown tab → first', (
    tester,
  ) async {
    setViewport(
      tester,
      const Size(1440, 900),
      initialRoute: '/achievements?tab=qualifications',
    );
    await pumpApp(tester, settle: const Duration(milliseconds: 1200));
    expect(cardKeys(tester).map(kindOf).toSet(), {'qualifications'});
    expect(find.byType(HomePage), findsNothing);

    await go(tester, SiteSection.about, tab: 'nope');
    final kinds = cardKeys(tester).map(kindOf).toSet();
    expect(kinds, contains('profile'), reason: 'unknown tab → first tab');
    expect(kinds.difference({'profile', 'interests', 'languages'}), isEmpty);
    await unmount(tester);
  });

  testWidgets('See all on Home opens the matching tab', (tester) async {
    setViewport(tester, const Size(1440, 900), reduceMotion: true);
    await pumpApp(tester, settle: const Duration(milliseconds: 600));
    final seeAll = find.byKey(
      const ValueKey('see-all:experience:organizations'),
      skipOffstage: false,
    );
    await tester.scrollUntilVisible(
      seeAll,
      400,
      scrollable: find
          .descendant(of: find.byType(HomePage), matching: _verticalScrollables)
          .first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(seeAll);
    await frames(tester, const Duration(milliseconds: 900));
    expect(find.byType(ExperiencePage), findsOneWidget);
    expect(cardKeys(tester).map(kindOf).toSet(), {'organizations'});
    await unmount(tester);
  });

  testWidgets('keyboard arrows move the rail', (tester) async {
    setViewport(
      tester,
      const Size(1440, 900),
      initialRoute: '/experience?tab=volunteering',
    );
    await pumpApp(tester, settle: const Duration(milliseconds: 1200));
    final rail = tester.state<ScrollableState>(
      find
          .descendant(
            of: find.byType(HorizontalRail),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(rail.position.pixels, 0);
    await tester.tap(find.byKey(const ValueKey('card:volunteering:0')));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await frames(tester, const Duration(milliseconds: 700));
    expect(rail.position.pixels, greaterThan(0));
    await unmount(tester);
  });
}
