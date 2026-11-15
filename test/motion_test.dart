// Motion rules (docs/plan.md › Verification › Motion, Guidelines).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_app/data/sections.dart';
import 'package:profile_app/pages/home_page.dart';
import 'package:profile_app/shell/intro_overlay.dart';
import 'package:profile_app/theme/app_theme.dart';
import 'package:profile_app/widgets/motion/block_decode_text.dart';
import 'package:profile_app/widgets/motion/marquee.dart';
import 'package:profile_app/widgets/motion/pinned_stage.dart';

import 'support/harness.dart';

Finder get _vertical => find.byWidgetPredicate(
  (w) =>
      w is Scrollable && axisDirectionToAxis(w.axisDirection) == Axis.vertical,
);

ScrollPosition _homePosition(WidgetTester tester) => tester
    .stateList<ScrollableState>(
      find.descendant(of: find.byType(HomePage), matching: _vertical),
    )
    .first
    .position;

void main() {
  testWidgets('PinnedStage progress follows scroll and reverses', (
    tester,
  ) async {
    setViewport(tester, const Size(1440, 900));
    final values = <double>[];
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CustomScrollView(
            controller: controller,
            slivers: [
              SliverList.list(
                children: [
                  const SizedBox(height: 300),
                  PinnedStage(
                    scrollLength: 2.0,
                    onProgress: values.add,
                    builder: (context, progress) =>
                        ValueListenableBuilder<double>(
                          valueListenable: progress,
                          builder: (context, p, _) => Transform.translate(
                            offset: Offset(0, (1 - p) * 600),
                            child: const SizedBox(
                              key: ValueKey('side'),
                              width: 100,
                              height: 100,
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 2000),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final y0 = tester.getTopLeft(find.byKey(const ValueKey('side'))).dy;

    controller.jumpTo(300 + 900 * 0.5); // halfway through the stage
    await frames(tester, const Duration(milliseconds: 800));
    final mid = values.last;
    expect(mid, inInclusiveRange(0.4, 0.6));
    final yMid = tester.getTopLeft(find.byKey(const ValueKey('side'))).dy;
    expect(yMid, lessThan(y0), reason: 'side card rises with progress');

    controller.jumpTo(300 + 900); // end of stage
    await frames(tester, const Duration(milliseconds: 800));
    expect(values.last, closeTo(1.0, 0.01));

    controller.jumpTo(300 + 900 * 0.25); // scroll back → reverses
    await frames(tester, const Duration(milliseconds: 800));
    expect(values.last, inInclusiveRange(0.15, 0.35));
  });

  testWidgets('Home desktop: About chapter side cards move with progress', (
    tester,
  ) async {
    setViewport(tester, const Size(1440, 900));
    await pumpApp(tester);
    expect(find.byType(PinnedStage), findsWidgets, reason: 'desktop pins');
    final pos = _homePosition(tester);
    final card = find.byKey(const ValueKey('card:interests:0'));

    pos.jumpTo(900 * 0.6);
    await frames(tester, const Duration(milliseconds: 800));
    final early = tester.getTopLeft(card).dy;
    pos.jumpTo(900 * 1.5);
    await frames(tester, const Duration(milliseconds: 800));
    final late = tester.getTopLeft(card).dy;
    expect(late, lessThan(early), reason: 'side cards rise (P10)');
    await unmount(tester);
  });

  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    testWidgets('reduced motion ${size.width.toInt()}: no intro, no pinning, '
        'no running loops', (tester) async {
      setViewport(tester, size, reduceMotion: true);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApp(tester, settle: const Duration(milliseconds: 100));
      expect(find.byType(IntroOverlay), findsNothing);
      expect(find.byType(PinnedStage, skipOffstage: false), findsNothing);
      // Everything is at its end state: nothing schedules frames.
      await tester.pump(const Duration(seconds: 1));
      final pos = _homePosition(tester);
      var guard = 0;
      while (pos.pixels < pos.maxScrollExtent && guard++ < 200) {
        pos.jumpTo((pos.pixels + 600).clamp(0, pos.maxScrollExtent));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  }

  testWidgets('intro plays once per session (no reduced motion)', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpApp(tester, settle: const Duration(milliseconds: 100));
    expect(find.byType(IntroOverlay), findsOneWidget);
    await frames(tester, const Duration(milliseconds: 2400));
    expect(find.byType(IntroOverlay), findsNothing);
    expect(IntroOverlay.hasPlayed, isTrue);
    await unmount(tester);
  });

  testWidgets('marquee ticks only on screen', (tester) async {
    setViewport(tester, const Size(1440, 900));
    await pumpApp(tester);
    final ticker = find.byKey(
      const ValueKey('skills-ticker'),
      skipOffstage: false,
    );
    await tester.scrollUntilVisible(
      ticker,
      500,
      scrollable: find
          .descendant(of: find.byType(HomePage), matching: _vertical)
          .first,
    );
    await frames(tester, const Duration(milliseconds: 600));
    final marquee = find.byType(Marquee).first;
    expect(
      TickerMode.valuesOf(tester.element(marquee)).enabled,
      isTrue,
      reason: 'visible',
    );

    _homePosition(tester).jumpTo(0);
    await frames(tester, const Duration(milliseconds: 600));
    final offscreen = find.byType(Marquee, skipOffstage: false);
    for (final e in offscreen.evaluate()) {
      expect(
        TickerMode.valuesOf(e).enabled,
        isFalse,
        reason: 'off-screen marquee paused',
      );
    }
    await unmount(tester);
  });

  testWidgets('block-decode ends in real text that semantics can read', (
    tester,
  ) async {
    setViewport(tester, const Size(390, 844));
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: BlockDecodeText(const [
              "LET'S WORK",
              'TOGETHER',
            ], style: AppTheme.light.textTheme.displayMedium!),
          ),
        ),
      ),
    );
    await frames(tester, const Duration(milliseconds: 1600));
    expect(find.bySemanticsLabel("LET'S WORK TOGETHER"), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'finished');
    handle.dispose();
  });

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    for (final route in [
      '/contact',
      '/about',
      '/experience?tab=volunteering',
    ]) {
      testWidgets('guidelines $route ${mode.name}: contrast + tap targets', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        setViewport(
          tester,
          const Size(390, 844),
          reduceMotion: true,
          initialRoute: route,
        );
        await pumpApp(
          tester,
          mode: mode,
          settle: const Duration(milliseconds: 800),
        );
        expect(SiteSection.fromPath(route), isNot(SiteSection.home));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await unmount(tester);
        handle.dispose();
      });
    }
  }
}
