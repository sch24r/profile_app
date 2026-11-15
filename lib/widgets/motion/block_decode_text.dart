import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';
import 'in_view.dart';

/// P13 block-decode headline.
///
/// Renders [lines] (one line each, `FittedBox(scaleDown)` when [fit]) in
/// [style]. One-shot animation, started when 40 % of the widget is in view
/// (or when [start] becomes true, if provided), after [delay]:
///
/// 1. Each glyph is first shown as a chamfered solid block in the text colour
///    (glyph box from `TextPainter.getBoxesForSelection`, computed once per
///    layout; corner cut 18 % of the box height). Line `i` fades in at
///    `i * Motion.blockLineStagger` over `Motion.blockFadeIn`.
/// 2. Hold until `Motion.blockHold`.
/// 3. Swap to the real glyphs over `Motion.blockSwap` (blocks fade out while
///    the text fades in, `Motion.sineOut`).
///
/// Spaces get no block. Semantics: one label (`lines.join(' ')`), the visual
/// is excluded. Reduced motion → plain text. Each frame only repaints the
/// line render objects (no rebuilds, no relayout).
class BlockDecodeText extends StatefulWidget {
  const BlockDecodeText(
    this.lines, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.start,
    this.fit = true,
    this.delay = Duration.zero,
    this.start,
    this.color,
    this.triggerFraction = 0.4,
  });

  final List<String> lines;
  final TextStyle style;
  final TextAlign textAlign;

  /// Scale each line down (never up) to fit the available width. When false
  /// lines wrap instead.
  final bool fit;
  final Duration delay;

  /// External trigger; when provided the in-view trigger is not used.
  final ValueListenable<bool>? start;

  /// Overrides `style.color`.
  final Color? color;

  /// Visible fraction that triggers the animation (when [start] is null).
  /// P13: 40 % in view.
  final double triggerFraction;

  @override
  State<BlockDecodeText> createState() => _BlockDecodeTextState();
}

class _BlockDecodeTextState extends State<BlockDecodeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this);
  _BlockTiming _timing = const _BlockTiming(1, 0);
  ValueListenable<bool>? _start;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    _timing = _BlockTiming.of(widget.lines.length, widget.delay);
    _listenTo(widget.start);
  }

  @override
  void didUpdateWidget(BlockDecodeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start) {
      _listenTo(widget.start);
    }
    // Timing is frozen once the sequence has started.
    if (!_triggered) {
      _timing = _BlockTiming.of(widget.lines.length, widget.delay);
    }
  }

  void _listenTo(ValueListenable<bool>? listenable) {
    _start?.removeListener(_onStart);
    _start = listenable;
    _start?.addListener(_onStart);
    if (_start?.value ?? false) _scheduleTrigger();
  }

  void _onStart() {
    if (_start?.value ?? false) _trigger();
  }

  /// Safe to call from build: starts the clock right after this frame.
  void _scheduleTrigger() {
    if (_triggered) return;
    scheduleMicrotask(() {
      if (mounted) _trigger();
    });
  }

  void _trigger() {
    if (_triggered) return;
    _triggered = true;
    _clock.duration = Duration(microseconds: (_timing.totalMs * 1000).round());
    _clock.forward();
  }

  @override
  void dispose() {
    _start?.removeListener(_onStart);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(widget.style);
    final style = base.copyWith(
      color: widget.color ?? base.color ?? context.palette.ink,
    );
    final reduce = context.reduceMotion;
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final locale = Localizations.maybeLocaleOf(context);

    Widget line(int i) {
      final text = widget.lines[i];
      Widget child = reduce
          ? Text(
              text,
              style: style,
              textAlign: widget.textAlign,
              maxLines: widget.fit ? 1 : null,
              softWrap: !widget.fit,
            )
          : _BlockLine(
              text: text,
              style: style,
              textAlign: widget.textAlign,
              textDirection: direction,
              textScaler: scaler,
              locale: locale,
              wrap: !widget.fit,
              index: i,
              timing: _timing,
              clock: _clock,
            );
      if (widget.fit) child = FittedBox(fit: BoxFit.scaleDown, child: child);
      return child;
    }

    final (cross, align) = _alignment(widget.textAlign);
    Widget body = Align(
      // Fill a bounded width so center/end alignment works; shrink-wrap
      // when the width is unbounded (e.g. inside a Row).
      alignment: align,
      heightFactor: 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: cross,
        children: [for (var i = 0; i < widget.lines.length; i++) line(i)],
      ),
    );

    if (!reduce && widget.start == null) {
      body = InView(
        fraction: widget.triggerFraction,
        builder: (context, inView, child) {
          if (inView) _scheduleTrigger();
          return child!;
        },
        child: body,
      );
    }

    return Semantics(
      label: widget.lines.join(' '),
      child: ExcludeSemantics(child: body),
    );
  }

  static (CrossAxisAlignment, AlignmentDirectional) _alignment(TextAlign a) =>
      switch (a) {
        TextAlign.center => (
          CrossAxisAlignment.center,
          AlignmentDirectional.topCenter,
        ),
        TextAlign.end => (CrossAxisAlignment.end, AlignmentDirectional.topEnd),
        // left/right are treated as start/end of an LTR layout.
        TextAlign.right => (
          CrossAxisAlignment.end,
          AlignmentDirectional.topEnd,
        ),
        _ => (CrossAxisAlignment.start, AlignmentDirectional.topStart),
      };
}

// ─────────────────────────────────────────────────────────────────────────
// Timing
// ─────────────────────────────────────────────────────────────────────────

double _ms(Duration d) => d.inMicroseconds / 1000.0;

/// Immutable schedule of the sequence, in milliseconds since trigger.
@immutable
class _BlockTiming {
  const _BlockTiming(this.lineCount, this.delayMs);

  factory _BlockTiming.of(int lineCount, Duration delay) =>
      _BlockTiming(math.max(1, lineCount), _ms(delay));

  final int lineCount;
  final double delayMs;

  static final double _stagger = _ms(Motion.blockLineStagger);
  static final double _fadeIn = _ms(Motion.blockFadeIn);
  static final double _hold = _ms(Motion.blockHold);
  static final double _swap = _ms(Motion.blockSwap);

  /// Swap starts at blockHold, later only if many lines need time to appear.
  double get swapStartMs =>
      math.max(_hold, (lineCount - 1) * _stagger + _fadeIn + 160);

  double get totalMs => delayMs + swapStartMs + _swap;

  double _swapT(double e) =>
      Motion.sineOut.transform(((e - swapStartMs) / _swap).clamp(0.0, 1.0));

  /// Block opacity of line [index] at elapsed time [e] (ms, delay removed).
  double blockAlpha(double e, int index) {
    final appear = ((e - index * _stagger) / _fadeIn).clamp(0.0, 1.0);
    if (e <= swapStartMs) return appear;
    return appear * (1 - _swapT(e));
  }

  /// Real-glyph opacity at elapsed time [e].
  double textAlpha(double e) => e <= swapStartMs ? 0 : _swapT(e);

  @override
  bool operator ==(Object other) =>
      other is _BlockTiming &&
      other.lineCount == lineCount &&
      other.delayMs == delayMs;

  @override
  int get hashCode => Object.hash(lineCount, delayMs);
}

// ─────────────────────────────────────────────────────────────────────────
// One line: leaf render object
// ─────────────────────────────────────────────────────────────────────────

class _BlockLine extends LeafRenderObjectWidget {
  const _BlockLine({
    required this.text,
    required this.style,
    required this.textAlign,
    required this.textDirection,
    required this.textScaler,
    required this.locale,
    required this.wrap,
    required this.index,
    required this.timing,
    required this.clock,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final Locale? locale;
  final bool wrap;
  final int index;
  final _BlockTiming timing;
  final Animation<double> clock;

  @override
  _RenderBlockLine createRenderObject(BuildContext context) => _RenderBlockLine(
    text: text,
    style: style,
    textAlign: textAlign,
    textDirection: textDirection,
    textScaler: textScaler,
    locale: locale,
    wrap: wrap,
    index: index,
    timing: timing,
    clock: clock,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderBlockLine renderObject) {
    renderObject
      ..setText(text, style)
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..textScaler = textScaler
      ..locale = locale
      ..wrap = wrap
      ..index = index
      ..timing = timing
      ..clock = clock;
  }
}

/// Lays out one line of text, caches its glyph-block [Path] per layout and
/// paints blocks / glyphs according to the shared clock.
class _RenderBlockLine extends RenderBox {
  _RenderBlockLine({
    required String text,
    required TextStyle style,
    required TextAlign textAlign,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required Locale? locale,
    required this._wrap,
    required this._index,
    required this._timing,
    required this._clock,
  }) : _text = text,
       _style = style,
       _painter = TextPainter(
         text: TextSpan(text: text, style: style),
         textAlign: textAlign,
         textDirection: textDirection,
         textScaler: textScaler,
         locale: locale,
       );

  final TextPainter _painter;
  final LayerHandle<OpacityLayer> _opacityLayer = LayerHandle<OpacityLayer>();

  String _text;
  TextStyle _style;
  bool _textPartial = false;

  /// Chamfered glyph blocks for the current layout (built lazily, cached
  /// until the next layout).
  Path? _blocks;
  final Paint _blockPaint = Paint()..isAntiAlias = true;

  // ── Properties ──────────────────────────────────────────────────────────

  void setText(String text, TextStyle style) {
    if (text == _text && style == _style) return;
    final relayout =
        text != _text ||
        style.compareTo(_style).index >= RenderComparison.layout.index;
    _text = text;
    _style = style;
    _painter.text = TextSpan(text: text, style: style);
    // Glyph blocks depend on the layout; a colour-only change just repaints.
    relayout ? markNeedsLayout() : markNeedsPaint();
  }

  set textAlign(TextAlign v) {
    if (_painter.textAlign == v) return;
    _painter.textAlign = v;
    markNeedsLayout();
  }

  set textDirection(TextDirection v) {
    if (_painter.textDirection == v) return;
    _painter.textDirection = v;
    markNeedsLayout();
  }

  set textScaler(TextScaler v) {
    if (_painter.textScaler == v) return;
    _painter.textScaler = v;
    markNeedsLayout();
  }

  set locale(Locale? v) {
    if (_painter.locale == v) return;
    _painter.locale = v;
    markNeedsLayout();
  }

  bool _wrap;
  set wrap(bool v) {
    if (_wrap == v) return;
    _wrap = v;
    markNeedsLayout();
  }

  int _index;
  set index(int v) {
    if (_index == v) return;
    _index = v;
    _onTick();
  }

  _BlockTiming _timing;
  set timing(_BlockTiming v) {
    if (_timing == v) return;
    _timing = v;
    _onTick();
  }

  Animation<double> _clock;
  set clock(Animation<double> v) {
    if (identical(_clock, v)) return;
    if (attached) _clock.removeListener(_onTick);
    _clock = v;
    if (attached) _clock.addListener(_onTick);
    _onTick();
  }

  // ── Clock ───────────────────────────────────────────────────────────────

  double get _elapsed => _clock.value * _timing.totalMs - _timing.delayMs;

  void _onTick() {
    final a = _timing.textAlpha(_elapsed);
    final partial = a > 0 && a < 1;
    if (partial != _textPartial) {
      _textPartial = partial;
      markNeedsCompositingBitsUpdate();
    }
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => _textPartial;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _clock.addListener(_onTick);
    _onTick(); // the clock may have moved while detached
  }

  @override
  void detach() {
    _clock.removeListener(_onTick);
    super.detach();
  }

  @override
  void dispose() {
    _opacityLayer.layer = null;
    _painter.dispose();
    super.dispose();
  }

  // ── Layout ──────────────────────────────────────────────────────────────

  void _layoutText(double maxWidth) =>
      _painter.layout(maxWidth: _wrap ? maxWidth : double.infinity);

  @override
  double computeMinIntrinsicWidth(double height) {
    _layoutText(double.infinity);
    return _wrap ? _painter.minIntrinsicWidth : _painter.maxIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _layoutText(double.infinity);
    return _painter.maxIntrinsicWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _layoutText(width);
    return _painter.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    _layoutText(constraints.maxWidth);
    return _painter.computeDistanceToActualBaseline(baseline);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    _layoutText(constraints.maxWidth);
    return constraints.constrain(_painter.size);
  }

  @override
  void performLayout() {
    _layoutText(constraints.maxWidth);
    size = constraints.constrain(_painter.size);
    _blocks = null;
  }

  /// One chamfered rect per non-space glyph (box from
  /// `getBoxesForSelection`), corner cut 18 % of the box height on the
  /// top-left and bottom-right corners. Requires the painter to be laid out.
  Path _buildBlocks() {
    final path = Path();
    var start = 0;
    for (final rune in _text.runes) {
      final length = rune > 0xFFFF ? 2 : 1;
      final end = start + length;
      if (!_isSpace(rune)) {
        final boxes = _painter.getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: end),
        );
        for (final b in boxes) {
          final r = b.toRect();
          if (r.width <= 0 || r.height <= 0) continue;
          // Hairline seam between neighbouring cells.
          final inset = math.min(1.0, r.width * 0.06);
          final cell = Rect.fromLTRB(
            r.left + inset,
            r.top,
            r.right - inset,
            r.bottom,
          );
          final cut = math.min(cell.height * 0.18, cell.width / 2);
          path.addPolygon([
            Offset(cell.left + cut, cell.top),
            Offset(cell.right, cell.top),
            Offset(cell.right, cell.bottom - cut),
            Offset(cell.right - cut, cell.bottom),
            Offset(cell.left, cell.bottom),
            Offset(cell.left, cell.top + cut),
          ], true);
        }
      }
      start = end;
    }
    return path;
  }

  static bool _isSpace(int rune) =>
      rune == 0x20 ||
      rune == 0x09 ||
      rune == 0x0A ||
      rune == 0x0D ||
      rune == 0xA0 ||
      rune == 0x3000 ||
      (rune >= 0x2000 && rune <= 0x200B);

  // ── Paint ───────────────────────────────────────────────────────────────

  @override
  void paint(PaintingContext context, Offset offset) {
    // Intrinsic / dry layout calls may have re-laid the painter: restore.
    _layoutText(constraints.maxWidth);
    final e = _elapsed;
    final blockA = _timing.blockAlpha(e, _index);
    final textA = _timing.textAlpha(e);

    final color = _style.color;
    if (blockA > 0 && color != null) {
      final blocks = _blocks ??= _buildBlocks();
      _blockPaint.color = color.withValues(alpha: color.a * blockA);
      context.canvas
        ..save()
        ..translate(offset.dx, offset.dy)
        ..drawPath(blocks, _blockPaint)
        ..restore();
    }

    if (textA > 0 && textA < 1 && _textPartial) {
      _opacityLayer.layer = context.pushOpacity(
        offset,
        (textA * 255).round(),
        (context, offset) => _painter.paint(context.canvas, offset),
        oldLayer: _opacityLayer.layer,
      );
    } else {
      _opacityLayer.layer = null;
      if (textA > 0) _painter.paint(context.canvas, offset);
    }
  }
}
