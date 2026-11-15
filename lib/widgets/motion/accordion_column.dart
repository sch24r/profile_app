import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';

/// Builds one accordion item. [open] runs 0 → 1 while the item is open
/// (hovered on desktop, toggled by tap on touch); items use it for their
/// content swap (title out, caption in, art spread).
typedef AccordionItemBuilder = Widget Function(
  BuildContext context,
  Animation<double> open,
);

/// P11 bento hover accordion.
///
/// A column (or row when [axis] is [Axis.horizontal]) of N cards in a FIXED
/// total [extent] (main-axis size).
///
/// With pointer effects (desktop, no reduced motion): hovering item i grows it
/// to [openFraction] of the extent while the others share the rest (never
/// under [minClosedExtent] = 96 px). Motion.accordionIn / accordionOut with
/// Motion.expoOut, one open item at a time. The relayout is done with a
/// `CustomMultiChildLayout(relayout: animation)` inside a [RepaintBoundary] —
/// the documented exception to the "paint-only" rule (few small cards,
/// 450 ms, desktop only).
///
/// Without pointer effects (touch / mobile / tablet / reduced motion): equal
/// sizes (or intrinsic heights when [extent] is null for a vertical column),
/// and tapping toggles the item's `open` animation — content-only cross-fade
/// (Motion.fade), card sizes never change.
///
/// When [extent] is null on desktop the bounded incoming main-axis constraint
/// is used; a horizontal row additionally needs a bounded height (or
/// [crossExtent]). If either is unavailable the static layout is used and
/// hover only drives the content animation.
class AccordionColumn extends StatefulWidget {
  const AccordionColumn({
    super.key,
    required this.items,
    this.extent,
    this.gap = 16,
    this.axis = Axis.vertical,
    this.openFraction = 0.7,
    this.minClosedExtent = 96,
    this.crossExtent,
  }) : assert(openFraction > 0 && openFraction < 1);

  /// One builder per card.
  final List<AccordionItemBuilder> items;

  /// Total main-axis size including gaps. Null → constraint / intrinsic.
  final double? extent;

  /// Gap between cards along the main axis.
  final double gap;

  final Axis axis;

  /// Main-axis share of the open card (of the extent minus gaps).
  final double openFraction;

  /// Minimum main-axis size of a closed card while another is open.
  final double minClosedExtent;

  /// Optional cross-axis size (mainly for horizontal rows inside an
  /// unbounded-height parent).
  final double? crossExtent;

  @override
  State<AccordionColumn> createState() => _AccordionColumnState();
}

class _AccordionColumnState extends State<AccordionColumn>
    with TickerProviderStateMixin {
  final List<AnimationController> _controllers = [];
  final List<CurvedAnimation> _curves = [];
  late Listenable _relayout;

  /// Whether the controllers are configured for hover (true) or tap (false).
  bool? _hoverMode;

  @override
  void initState() {
    super.initState();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant AccordionColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) _syncControllers();
  }

  void _syncControllers() {
    while (_controllers.length > widget.items.length) {
      _curves.removeLast().dispose();
      _controllers.removeLast().dispose();
    }
    while (_controllers.length < widget.items.length) {
      final c = AnimationController(vsync: this);
      _controllers.add(c);
      _curves.add(
        CurvedAnimation(
          parent: c,
          curve: Motion.expoOut,
          reverseCurve: Motion.expoOut.flipped,
        ),
      );
    }
    if (_hoverMode != null) _configureDurations(_hoverMode!);
    _relayout = Listenable.merge(_curves);
  }

  void _configureDurations(bool hover) {
    for (final c in _controllers) {
      c.duration = hover ? Motion.accordionIn : Motion.fade;
      c.reverseDuration = hover ? Motion.accordionOut : Motion.fade;
    }
  }

  @override
  void dispose() {
    for (final c in _curves) {
      c.dispose();
    }
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// Opens [index] (closing every other item). `null` closes all.
  void _open(int? index, {bool animate = true}) {
    for (var i = 0; i < _controllers.length; i++) {
      final c = _controllers[i];
      final target = i == index ? 1.0 : 0.0;
      if (!animate) {
        c.value = target;
      } else if (target == 1.0) {
        if (!c.isForwardOrCompleted) c.forward();
      } else if (c.isForwardOrCompleted) {
        c.reverse();
      }
    }
  }

  void _toggle(int index, {required bool animate}) {
    final c = _controllers[index];
    _open(c.isForwardOrCompleted ? null : index, animate: animate);
  }

  @override
  Widget build(BuildContext context) {
    final hover = context.pointerEffects;
    final reduce = context.reduceMotion;
    if (_hoverMode != hover) {
      _hoverMode = hover;
      _configureDurations(hover);
      // Switching modes (e.g. window resized across the breakpoint): settle.
      if (!hover) _open(null, animate: false);
    }

    if (widget.items.isEmpty) return const SizedBox.shrink();

    final vertical = widget.axis == Axis.vertical;

    return LayoutBuilder(
      builder: (context, constraints) {
        final mainMax = vertical ? constraints.maxHeight : constraints.maxWidth;
        final crossMax = vertical
            ? constraints.maxWidth
            : constraints.maxHeight;
        final mainExtent = widget.extent ?? (mainMax.isFinite ? mainMax : null);
        final crossExtent =
            widget.crossExtent ?? (crossMax.isFinite ? crossMax : null);

        final cards = <Widget>[
          for (var i = 0; i < widget.items.length; i++)
            _AccordionItem(
              key: ValueKey<int>(i),
              open: _curves[i],
              builder: widget.items[i],
              hover: hover,
              onEnter: () => _open(i),
              onTap: () => _toggle(i, animate: !reduce),
              // Keyboard focus inside a card opens it like a hover would.
              onFocus: (focused) {
                if (focused) _open(i, animate: !reduce);
              },
            ),
        ];

        if (hover && mainExtent != null && crossExtent != null) {
          final size = vertical
              ? Size(crossExtent, mainExtent)
              : Size(mainExtent, crossExtent);
          return MouseRegion(
            onExit: (_) => _open(null),
            child: RepaintBoundary(
              child: SizedBox.fromSize(
                size: size,
                child: CustomMultiChildLayout(
                  delegate: _AccordionDelegate(
                    open: List.unmodifiable(_curves),
                    relayout: _relayout,
                    axis: widget.axis,
                    gap: widget.gap,
                    openFraction: widget.openFraction,
                    minClosed: widget.minClosedExtent,
                  ),
                  children: [
                    for (var i = 0; i < cards.length; i++)
                      LayoutId(id: i, child: cards[i]),
                  ],
                ),
              ),
            ),
          );
        }

        // Static layout: equal sizes, or intrinsic for an unsized column.
        final equal = widget.extent != null || !vertical;
        final spaced = <Widget>[
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0)
              vertical
                  ? SizedBox(height: widget.gap)
                  : SizedBox(width: widget.gap),
            equal ? Expanded(child: cards[i]) : cards[i],
          ],
        ];
        final stretch = vertical ? crossMax.isFinite : crossExtent != null;
        Widget flex = Flex(
          direction: widget.axis,
          mainAxisSize: equal ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: stretch
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          children: spaced,
        );
        if (widget.extent != null || widget.crossExtent != null) {
          flex = SizedBox(
            width: vertical ? widget.crossExtent : widget.extent,
            height: vertical ? widget.extent : widget.crossExtent,
            child: flex,
          );
        }
        return hover
            ? MouseRegion(onExit: (_) => _open(null), child: flex)
            : flex;
      },
    );
  }
}

/// One card slot: hover / tap / focus plumbing around the item builder.
class _AccordionItem extends StatelessWidget {
  const _AccordionItem({
    super.key,
    required this.open,
    required this.builder,
    required this.hover,
    required this.onEnter,
    required this.onTap,
    required this.onFocus,
  });

  final Animation<double> open;
  final AccordionItemBuilder builder;
  final bool hover;
  final VoidCallback onEnter;
  final VoidCallback onTap;
  final ValueChanged<bool> onFocus;

  @override
  Widget build(BuildContext context) {
    final content = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: onFocus,
      child: builder(context, open),
    );
    if (hover) {
      // Desktop: hover drives it; the region-level exit closes it.
      return MouseRegion(onEnter: (_) => onEnter(), child: content);
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}

/// Lays the cards out along the main axis, blending each item's open
/// contribution so the sizes always sum to the available extent.
class _AccordionDelegate extends MultiChildLayoutDelegate {
  _AccordionDelegate({
    required this.open,
    required Listenable relayout,
    required this.axis,
    required this.gap,
    required this.openFraction,
    required this.minClosed,
  }) : super(relayout: relayout);

  final List<Animation<double>> open;
  final Axis axis;
  final double gap;
  final double openFraction;
  final double minClosed;

  @override
  void performLayout(Size size) {
    final n = open.length;
    final vertical = axis == Axis.vertical;
    final main = vertical ? size.height : size.width;
    final cross = vertical ? size.width : size.height;
    final avail = math.max(0.0, main - gap * (n - 1));

    final equal = avail / n;
    var openSize = equal;
    var closedSize = equal;
    if (n > 1) {
      openSize = avail * openFraction;
      closedSize = (avail - openSize) / (n - 1);
      final floor = math.min(minClosed, equal);
      if (closedSize < floor) {
        closedSize = floor;
        openSize = avail - closedSize * (n - 1);
      }
    }
    final dOpen = openSize - equal;
    final dClosed = closedSize - equal;

    // Blend: every open item contributes its delta to all items; the deltas
    // of one open item sum to zero, so the total is preserved.
    final sizes = List<double>.filled(n, equal);
    for (var j = 0; j < n; j++) {
      final v = open[j].value;
      if (v == 0) continue;
      for (var i = 0; i < n; i++) {
        sizes[i] += v * (i == j ? dOpen : dClosed);
      }
    }
    // Overlapping in/out curves can push a size negative: clamp & normalise.
    var total = 0.0;
    for (var i = 0; i < n; i++) {
      sizes[i] = math.max(0.0, sizes[i]);
      total += sizes[i];
    }
    final k = total > 0 ? avail / total : 0.0;

    var pos = 0.0;
    for (var i = 0; i < n; i++) {
      final s = sizes[i] * k;
      final tight = vertical
          ? BoxConstraints.tightFor(width: cross, height: s)
          : BoxConstraints.tightFor(width: s, height: cross);
      layoutChild(i, tight);
      positionChild(i, vertical ? Offset(0, pos) : Offset(pos, 0));
      pos += s + gap;
    }
  }

  @override
  bool shouldRelayout(covariant _AccordionDelegate old) =>
      old.axis != axis ||
      old.gap != gap ||
      old.openFraction != openFraction ||
      old.minClosed != minClosed ||
      old.open.length != open.length ||
      !_sameItems(old.open, open);

  static bool _sameItems(List<Animation<double>> a, List<Animation<double>> b) {
    for (var i = 0; i < a.length; i++) {
      if (!identical(a[i], b[i])) return false;
    }
    return true;
  }
}
