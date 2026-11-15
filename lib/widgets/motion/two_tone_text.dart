import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../../theme/spacing.dart';

/// P8 split-colour title.
///
/// Paints the same text twice: [outsideColor] everywhere, then [insideColor]
/// clipped to [insideRect] (an RRect in this widget's local coordinates,
/// radius [radius], default `Radii.card`). [insideRect] is a
/// [ValueListenable], so moving the card only repaints this widget — no
/// rebuild, no relayout. `null` → all outside colour.
///
/// Layout: one line per entry in [lines], stacked; when [fit] the whole block
/// is scaled down uniformly (never up) so the widest line fits the width.
/// In a bounded width the widget fills it and aligns lines per [textAlign].
class TwoToneText extends StatelessWidget {
  const TwoToneText(
    this.lines, {
    super.key,
    required this.style,
    required this.outsideColor,
    required this.insideColor,
    required this.insideRect,
    this.textAlign = TextAlign.center,
    this.fit = true,
    this.radius = Radii.card,
  });

  final List<String> lines;
  final TextStyle style;
  final Color outsideColor;
  final Color insideColor;

  /// Local-coordinate rect of the "inside" region; null → all outside colour.
  final ValueListenable<Rect?> insideRect;
  final TextAlign textAlign;

  /// Scale down to fit the available width (otherwise lines wrap).
  final bool fit;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style.merge(style);
    return Semantics(
      label: lines.join(' '),
      child: _TwoToneLeaf(
        lines: lines,
        outsideStyle: base.copyWith(color: outsideColor),
        insideStyle: base.copyWith(color: insideColor),
        insideRect: insideRect,
        textAlign: textAlign,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        fit: fit,
        radius: radius,
      ),
    );
  }
}

class _TwoToneLeaf extends LeafRenderObjectWidget {
  const _TwoToneLeaf({
    required this.lines,
    required this.outsideStyle,
    required this.insideStyle,
    required this.insideRect,
    required this.textAlign,
    required this.textDirection,
    required this.textScaler,
    required this.fit,
    required this.radius,
  });

  final List<String> lines;
  final TextStyle outsideStyle;
  final TextStyle insideStyle;
  final ValueListenable<Rect?> insideRect;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final bool fit;
  final double radius;

  @override
  _RenderTwoTone createRenderObject(BuildContext context) =>
      _RenderTwoTone(insideRect: insideRect, fit: fit, radius: radius)
        ..configure(
          lines,
          outsideStyle,
          insideStyle,
          textAlign,
          textDirection,
          textScaler,
        );

  @override
  void updateRenderObject(BuildContext context, _RenderTwoTone renderObject) {
    renderObject
      ..configure(
        lines,
        outsideStyle,
        insideStyle,
        textAlign,
        textDirection,
        textScaler,
      )
      ..insideRect = insideRect
      ..fit = fit
      ..radius = radius;
  }
}

/// Two TextPainters per line (identical layout, different colour). Layout
/// happens only when text/style/width change; the clip moves at paint time.
class _RenderTwoTone extends RenderBox {
  _RenderTwoTone({
    required this._insideRect,
    required this._fit,
    required this._radius,
  });

  final List<TextPainter> _outside = [];
  final List<TextPainter> _inside = [];
  List<String> _lines = const [];
  TextStyle? _outsideStyle;
  TextStyle? _insideStyle;
  TextAlign _textAlign = TextAlign.center;
  TextDirection _textDirection = TextDirection.ltr;
  TextScaler _textScaler = TextScaler.noScaling;

  /// Per-line paint offsets in unscaled content space.
  List<Offset> _offsets = const [];
  double _scale = 1;

  void configure(
    List<String> lines,
    TextStyle outsideStyle,
    TextStyle insideStyle,
    TextAlign textAlign,
    TextDirection textDirection,
    TextScaler textScaler,
  ) {
    final sameText =
        listEquals(lines, _lines) &&
        _textAlign == textAlign &&
        _textDirection == textDirection &&
        _textScaler == textScaler;
    final outsideCmp = _outsideStyle == null
        ? RenderComparison.layout
        : outsideStyle.compareTo(_outsideStyle!);
    final insideCmp = _insideStyle == null
        ? RenderComparison.layout
        : insideStyle.compareTo(_insideStyle!);
    if (sameText &&
        outsideCmp == RenderComparison.identical &&
        insideCmp == RenderComparison.identical) {
      return;
    }

    _lines = List.unmodifiable(lines);
    _outsideStyle = outsideStyle;
    _insideStyle = insideStyle;
    _textAlign = textAlign;
    _textDirection = textDirection;
    _textScaler = textScaler;
    _sync(_outside, outsideStyle);
    _sync(_inside, insideStyle);

    final relayout =
        !sameText ||
        outsideCmp.index >= RenderComparison.layout.index ||
        insideCmp.index >= RenderComparison.layout.index;
    relayout ? markNeedsLayout() : markNeedsPaint();
  }

  void _sync(List<TextPainter> painters, TextStyle style) {
    while (painters.length > _lines.length) {
      painters.removeLast().dispose();
    }
    while (painters.length < _lines.length) {
      painters.add(TextPainter());
    }
    for (var i = 0; i < _lines.length; i++) {
      painters[i]
        ..text = TextSpan(text: _lines[i], style: style)
        ..textAlign = _textAlign
        ..textDirection = _textDirection
        ..textScaler = _textScaler;
    }
  }

  ValueListenable<Rect?> _insideRect;
  set insideRect(ValueListenable<Rect?> v) {
    if (identical(v, _insideRect)) return;
    if (attached) _insideRect.removeListener(markNeedsPaint);
    _insideRect = v;
    if (attached) _insideRect.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  bool _fit;
  set fit(bool v) {
    if (v == _fit) return;
    _fit = v;
    markNeedsLayout();
  }

  double _radius;
  set radius(double v) {
    if (v == _radius) return;
    _radius = v;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _insideRect.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _insideRect.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void dispose() {
    for (final p in [..._outside, ..._inside]) {
      p.dispose();
    }
    super.dispose();
  }

  // ── Layout ──────────────────────────────────────────────────────────────

  /// Lays out all painters for [maxWidth]; returns (widest, totalHeight).
  (double, double) _layoutText(double maxWidth) {
    final wrapWidth = _fit ? double.infinity : maxWidth;
    var widest = 0.0;
    var total = 0.0;
    for (var i = 0; i < _outside.length; i++) {
      _outside[i].layout(maxWidth: wrapWidth);
      _inside[i].layout(maxWidth: wrapWidth);
      widest = math.max(widest, _outside[i].width);
      total += _outside[i].height;
    }
    return (widest, total);
  }

  ({Size size, double scale}) _measure(BoxConstraints c) {
    final (widest, total) = _layoutText(c.maxWidth);
    final scale = _fit && c.hasBoundedWidth && widest > c.maxWidth && widest > 0
        ? c.maxWidth / widest
        : 1.0;
    final width = c.hasBoundedWidth ? c.maxWidth : widest * scale;
    return (size: c.constrain(Size(width, total * scale)), scale: scale);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    // Fitted text can shrink to any width; wrapped text to its longest word.
    if (_fit) return 0;
    _layoutText(double.infinity);
    return _outside.fold(0.0, (m, p) => math.max(m, p.minIntrinsicWidth));
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _layoutText(double.infinity).$1;

  @override
  double computeMinIntrinsicHeight(double width) =>
      _measure(BoxConstraints(maxWidth: width)).size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _measure(constraints).size;

  @override
  void performLayout() {
    final m = _measure(constraints);
    size = m.size;
    _scale = m.scale;

    // Horizontal alignment inside the (unscaled) content width.
    final innerWidth = size.width / _scale;
    final rtl = _textDirection == TextDirection.rtl;
    final offsets = <Offset>[];
    var y = 0.0;
    for (final p in _outside) {
      final free = math.max(0.0, innerWidth - p.width);
      final x = switch (_textAlign) {
        TextAlign.center => free / 2,
        TextAlign.right => free,
        TextAlign.left || TextAlign.justify => 0.0,
        TextAlign.end => rtl ? 0.0 : free,
        TextAlign.start => rtl ? free : 0.0,
      };
      offsets.add(Offset(x, y));
      y += p.height;
    }
    _offsets = offsets;
  }

  // ── Paint ───────────────────────────────────────────────────────────────

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_outside.isEmpty) return;
    // Intrinsic / dry layout calls may have re-laid the painters: restore.
    _layoutText(constraints.maxWidth);
    final canvas = context.canvas;

    void paintAll(List<TextPainter> painters) {
      canvas
        ..save()
        ..translate(offset.dx, offset.dy)
        ..scale(_scale);
      for (var i = 0; i < painters.length; i++) {
        painters[i].paint(canvas, _offsets[i]);
      }
      canvas.restore();
    }

    paintAll(_outside);

    final r = _insideRect.value;
    if (r == null || r.isEmpty || !r.overlaps(Offset.zero & size)) return;
    canvas
      ..save()
      ..clipRRect(
        RRect.fromRectAndRadius(r.shift(offset), Radius.circular(_radius)),
      );
    paintAll(_inside);
    canvas.restore();
  }
}

/// Clip that reveals with a slanted ([slantDeg], default 12°) leading edge
/// moving right → left as [t] goes 0 → 1. The revealed area is to the right
/// of the edge; the top of the edge leads. `t <= 0` → nothing, `t >= 1` →
/// the whole box.
class SlantWipeClipper extends CustomClipper<Path> {
  SlantWipeClipper(this.t, {this.slantDeg = 12, super.reclip});

  final double t;
  final double slantDeg;

  @override
  Path getClip(Size size) {
    if (t <= 0) return Path();
    if (t >= 1) return Path()..addRect(Offset.zero & size);
    final dx = size.height * math.tan(slantDeg * math.pi / 180);
    // Top x of the edge travels from the right edge to -dx so the bottom
    // corner is cleared exactly at t = 1.
    final top = size.width + (-dx - size.width) * t;
    return Path()
      ..moveTo(top, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(top + dx, size.height)
      ..close();
  }

  @override
  bool shouldReclip(SlantWipeClipper oldClipper) =>
      oldClipper.t != t || oldClipper.slantDeg != slantDeg;
}
