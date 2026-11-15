import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';
import '../../theme/spacing.dart';
import '../../theme/typography.dart';
import '../ui/round_icon_button.dart';
import 'reveal.dart';

/// Horizontal, snapping rail of cards that fills its parent's height (the
/// body of every sub-page / tab). Scrolls left → right only; never vertically.
///
/// * Card width — mobile: one card per view with the next card peeking
///   [mobilePeek] px; tablet: [tabletPerView] per view; desktop:
///   [desktopPerView] per view. Gap = `Layout.gridGap(bp)`. When there are
///   fewer cards than a view holds, the cards widen to fill the row (no empty
///   space).
/// * Input — drag / swipe (touch, mouse, trackpad, stylus), arrow buttons
///   (tablet / desktop), Shift+wheel and horizontal trackpad scroll, plain
///   wheel when nothing scrolls vertically above the rail, ←/→ keys when
///   focused (a pointer-down inside the rail focuses it).
/// * Indicator — "n / N" (n = last visible card) + one dot per snap position
///   (active dot 6 → 22 px over [Motion.indicatorStep]).
/// * Snap per card (PageView-like physics); programmatic moves use
///   [Motion.expoOut] over [snapDuration] (jumps under reduced motion).
///   Cards enter once with [Reveal] (kept alive, so scrolling back never
///   replays the entrance).
///
/// ```dart
/// HorizontalRail(
///   itemCount: Cv.projects.length,
///   semanticLabel: 'Projects',
///   itemBuilder: (context, i) => ProjectCard(Cv.projects[i]),
/// )
/// ```
class HorizontalRail extends StatefulWidget {
  const HorizontalRail({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.desktopPerView = 3,
    this.tabletPerView = 2,
    this.initialIndex = 0,
    this.semanticLabel,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int desktopPerView;
  final int tabletPerView;
  final int initialIndex;
  final String? semanticLabel;

  /// Height of the indicator row under the cards.
  static const double indicatorHeight = 48;

  /// Gap between the cards and the indicator row.
  static const double indicatorGap = 12;

  /// Programmatic snap animation (contract: 450 ms, [Motion.expoOut]).
  static const Duration snapDuration = Duration(milliseconds: 450);

  /// Mobile peek of the next card.
  static const double mobilePeek = 24;

  /// Quiet time after the last wheel / trackpad event before snapping.
  static const Duration wheelSettle = Duration(milliseconds: 160);

  @override
  State<HorizontalRail> createState() => _HorizontalRailState();
}

class _HorizontalRailState extends State<HorizontalRail> {
  late final ScrollController _controller = ScrollController();
  final ValueNotifier<int> _position = ValueNotifier<int>(0);
  final FocusNode _focus = FocusNode(debugLabel: 'HorizontalRail');

  double _extent = 1; // card width + gap
  int _positions = 1; // number of snap positions
  bool _initialJumpDone = false;
  Timer? _wheelSettle;

  /// True while wheel / trackpad pointer-scroll events are arriving. Snap
  /// physics is suspended meanwhile (Flutter's `pointerScroll` ends every
  /// event with a zero-velocity ballistic, which would otherwise pull small
  /// deltas back to the current card); [_settle] snaps once input is quiet.
  bool _wheeling = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _wheelSettle?.cancel();
    _controller.dispose();
    _position.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_controller.hasClients) return;
    final pos = _controller.position;
    final i = pos.pixels >= pos.maxScrollExtent - 1
        ? _positions - 1
        : (pos.pixels / _extent).round();
    _position.value = i.clamp(0, _positions - 1);
  }

  double _offsetFor(int i) {
    final target = i * _extent;
    if (!_controller.hasClients) return target;
    return target.clamp(0.0, _controller.position.maxScrollExtent);
  }

  void _goTo(int i) {
    if (!_controller.hasClients) return;
    final target = _offsetFor(i.clamp(0, _positions - 1));
    if (context.reduceMotion) {
      _controller.jumpTo(target);
    } else {
      _controller.animateTo(
        target,
        duration: HorizontalRail.snapDuration,
        curve: Motion.expoOut,
      );
    }
  }

  void _step(int delta) => _goTo(_position.value + delta);

  void _settle() {
    _wheeling = false;
    if (!mounted || !_controller.hasClients) return;
    final pos = _controller.position;
    // Ends at the last snap position (which may be clamped) like _onScroll.
    final i = pos.pixels >= pos.maxScrollExtent - 1
        ? _positions - 1
        : (pos.pixels / _extent).round();
    _goTo(i);
  }

  /// Shift+wheel / horizontal trackpad scroll / plain wheel.
  ///
  /// Horizontal deltas (and Shift+mouse-wheel, which the Scrollable flips onto
  /// its axis) are applied by the ListView's own Scrollable. A plain vertical
  /// wheel is mapped onto the rail here, but only when no vertical scrollable
  /// sits above the rail, so a page scroll is never hijacked. Either way the
  /// snap is suspended while events arrive and the rail settles on the
  /// nearest card once input has been quiet for [HorizontalRail.wheelSettle].
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !_controller.hasClients) return;
    final d = event.scrollDelta;
    final flip =
        event.kind == PointerDeviceKind.mouse &&
        HardwareKeyboard.instance.logicalKeysPressed.any(
          ScrollConfiguration.of(context).pointerAxisModifiers.contains,
        );
    final handledByList = (flip ? d.dy : d.dx) != 0;
    final mapVertical =
        !handledByList &&
        d.dy != 0 &&
        Scrollable.maybeOf(context, axis: Axis.vertical) == null;
    if (!handledByList && !mapVertical) return;

    _wheeling = true;
    _wheelSettle?.cancel();
    _wheelSettle = Timer(HorizontalRail.wheelSettle, _settle);

    if (mapVertical) {
      GestureBinding.instance.pointerSignalResolver.register(event, (e) {
        if (!mounted || !_controller.hasClients) return;
        final pos = _controller.position;
        final next = (pos.pixels + d.dy).clamp(0.0, pos.maxScrollExtent);
        if (next != pos.pixels) _controller.jumpTo(next);
      });
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _step(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _step(-1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.bp;
    final n = widget.itemCount;
    final screenHeight = MediaQuery.sizeOf(context).height;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final pad = Layout.pagePadding(bp);
        final gap = Layout.gridGap(bp);
        final contentWidth = math.max(
          0.0,
          math.min(width - 2 * pad, Layout.maxContent),
        );
        final inset = math.max(0.0, (width - contentWidth) / 2);

        final double cardWidth;
        final int perView;
        switch (bp) {
          case Bp.mobile:
            perView = 1;
            cardWidth = n <= 1
                ? contentWidth
                : math.max(0.0, width - pad - HorizontalRail.mobilePeek - gap);
          case Bp.tablet:
          case Bp.desktop:
            final want = bp == Bp.tablet
                ? widget.tabletPerView
                : widget.desktopPerView;
            perView = math.max(1, math.min(want, n));
            cardWidth = math.max(
              0.0,
              (contentWidth - gap * (perView - 1)) / perView,
            );
        }
        final extent = math.max(1.0, cardWidth + gap);
        if (_initialJumpDone && (extent - _extent).abs() > 0.5) {
          // Resized: keep the current card aligned to the snap grid.
          final keep = _position.value;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _controller.hasClients) {
              _controller.jumpTo(_offsetFor(keep));
            }
          });
        }
        _extent = extent;
        _positions = math.max(1, n - perView + 1);

        if (!_initialJumpDone) {
          _initialJumpDone = true;
          final start = widget.initialIndex.clamp(0, _positions - 1);
          if (start > 0) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _controller.hasClients) {
                _controller.jumpTo(_offsetFor(start));
              }
            });
          }
        }

        // Fill the parent's height. An unbounded parent is a caller bug
        // (the rail is a sub-page body); fall back to a sane height.
        assert(
          box.hasBoundedHeight,
          'HorizontalRail needs a bounded height (it fills its parent).',
        );
        final available = box.hasBoundedHeight
            ? box.maxHeight
            : screenHeight * 0.6;
        final railHeight = math.max(
          0.0,
          available -
              HorizontalRail.indicatorHeight -
              HorizontalRail.indicatorGap,
        );
        final firstVisible = widget.initialIndex.clamp(0, _positions - 1);

        final list = ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false,
            dragDevices: const {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            physics: _CardSnapPhysics(
              extent: _extent,
              suspended: () => _wheeling,
            ),
            padding: EdgeInsets.symmetric(horizontal: inset),
            itemCount: n,
            separatorBuilder: (_, _) => SizedBox(width: gap),
            itemBuilder: (context, i) => _KeepAlive(
              child: SizedBox(
                width: cardWidth,
                height: railHeight,
                child: Reveal(
                  index: math.max(0, i - firstVisible),
                  child: widget.itemBuilder(context, i),
                ),
              ),
            ),
          ),
        );

        return Focus(
          focusNode: _focus,
          onKeyEvent: _onKey,
          child: Semantics(
            container: true,
            label: widget.semanticLabel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: railHeight,
                  child: Listener(
                    onPointerDown: (_) {
                      if (!_focus.hasFocus) _focus.requestFocus();
                    },
                    onPointerSignal: _onPointerSignal,
                    child: RepaintBoundary(child: list),
                  ),
                ),
                const SizedBox(height: HorizontalRail.indicatorGap),
                SizedBox(
                  height: HorizontalRail.indicatorHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: inset),
                    child: _RailIndicator(
                      position: _position,
                      positions: _positions,
                      perView: perView,
                      count: n,
                      showArrows: !context.isMobile && _positions > 1,
                      onPrev: () => _step(-1),
                      onNext: () => _step(1),
                      onDot: _goTo,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Keeps a rail card alive once built, so its one-shot [Reveal] never
/// replays when it is scrolled out of the cache extent and back.
class _KeepAlive extends StatefulWidget {
  const _KeepAlive({required this.child});

  final Widget child;

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin<_KeepAlive> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _RailIndicator extends StatelessWidget {
  const _RailIndicator({
    required this.position,
    required this.positions,
    required this.perView,
    required this.count,
    required this.showArrows,
    required this.onPrev,
    required this.onNext,
    required this.onDot,
  });

  final ValueListenable<int> position;
  final int positions;
  final int perView;
  final int count;
  final bool showArrows;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<int> onDot;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final duration = context.reduceMotion
        ? Duration.zero
        : Motion.indicatorStep;
    final dotsTappable = context.pointerEffects;
    return ValueListenableBuilder<int>(
      valueListenable: position,
      builder: (context, i, _) {
        final lastVisible = math.min(i + perView, count);
        final label =
            '${lastVisible.toString().padLeft(2, '0')} / '
            '${count.toString().padLeft(2, '0')}';
        return Row(
          children: [
            Semantics(
              label: 'Card $lastVisible of $count',
              excludeSemantics: true,
              child: Text(label, style: t.mono.copyWith(color: p.inkMuted)),
            ),
            const SizedBox(width: Space.s16),
            if (positions > 1)
              Flexible(
                child: ExcludeSemantics(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var d = 0; d < positions; d++)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            // Mouse convenience only: 6 px dots are not
                            // usable touch targets (swipe / arrows / keys are).
                            onTap: dotsTappable ? () => onDot(d) : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                                vertical: 12,
                              ),
                              child: AnimatedContainer(
                                duration: duration,
                                curve: Motion.indicator,
                                width: d == i ? 22 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: d == i ? p.primary : p.hairline,
                                  borderRadius: BorderRadius.circular(
                                    Radii.pill,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            const Spacer(),
            if (showArrows) ...[
              RoundIconButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Previous',
                variant: RoundVariant.neutral,
                size: 44,
                onPressed: i > 0 ? onPrev : null,
              ),
              const SizedBox(width: Space.s8),
              RoundIconButton(
                icon: Icons.arrow_forward_rounded,
                tooltip: 'Next',
                variant: RoundVariant.ink,
                size: 44,
                onPressed: i < positions - 1 ? onNext : null,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// PageView-like snapping per card of width [extent] (card + gap). While
/// [suspended] returns true (wheel / trackpad input in progress) no snap
/// simulation is created; the rail settles itself afterwards.
class _CardSnapPhysics extends ScrollPhysics {
  const _CardSnapPhysics({
    required this.extent,
    required this.suspended,
    super.parent,
  });

  final double extent;
  final ValueGetter<bool> suspended;

  @override
  _CardSnapPhysics applyTo(ScrollPhysics? ancestor) => _CardSnapPhysics(
    extent: extent,
    suspended: suspended,
    parent: buildParent(ancestor),
  );

  double _targetPixels(ScrollMetrics position, Tolerance tolerance, double v) {
    var page = position.pixels / extent;
    if (v < -tolerance.velocity) {
      page -= 0.5;
    } else if (v > tolerance.velocity) {
      page += 0.5;
    }
    final target = page.roundToDouble() * extent;
    return target.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }
    if (suspended()) return null;
    final tolerance = toleranceFor(position);
    final target = _targetPixels(position, tolerance, velocity);
    if (target != position.pixels) {
      return ScrollSpringSimulation(
        spring,
        position.pixels,
        target,
        velocity,
        tolerance: tolerance,
      );
    }
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}
