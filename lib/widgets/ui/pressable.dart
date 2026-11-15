import 'package:flutter/material.dart';

import '../../core/context_x.dart';
import '../../theme/motion.dart';

/// Shared interaction shell for the custom buttons/cards in `widgets/ui`.
///
/// * Keyboard: focusable, Enter / Space activate ([ActivateIntent]).
/// * Mouse: click cursor, hover callbacks (mouse only — touch never "hovers").
/// * Press feedback: optional scale to [pressScale] over [Motion.press]
///   (paint-only `ScaleTransition`; skipped under reduced motion).
/// * Focus: a 2 px ring ([ringColor], default `palette.primary`) drawn
///   [ringGap] px outside the child while focus is keyboard-highlighted.
/// * Semantics: one button node labelled [semanticLabel]; when
///   [excludeChildSemantics] is true the child's own semantics are dropped
///   (use when the visual duplicates the label, e.g. the P17 label roll).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.onTap,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.circle = false,
    this.pressScale = 1.0,
    this.ringColor,
    this.ringGap = 3,
    this.semanticLabel,
    this.tooltip,
    this.excludeChildSemantics = false,
    this.selected,
    this.inMutuallyExclusiveGroup = false,
    this.onHoverChanged,
    this.onFocusHighlightChanged,
    this.focusNode,
    this.autofocus = false,
  });

  final VoidCallback? onTap;
  final Widget child;

  /// Shape of the focus ring (ignored when [circle]).
  final BorderRadius borderRadius;
  final bool circle;

  /// 1.0 disables the press scale.
  final double pressScale;
  final Color? ringColor;
  final double ringGap;
  final String? semanticLabel;
  final String? tooltip;
  final bool excludeChildSemantics;
  final bool? selected;
  final bool inMutuallyExclusiveGroup;
  final ValueChanged<bool>? onHoverChanged;
  final ValueChanged<bool>? onFocusHighlightChanged;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    duration: Motion.press,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: widget.pressScale,
  ).animate(CurvedAnimation(parent: _press, curve: Motion.expoOut));
  bool _focusHighlight = false;

  bool get _enabled => widget.onTap != null;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down() {
    if (!_enabled || widget.pressScale == 1.0 || context.reduceMotion) return;
    _press.forward();
  }

  void _up() {
    if (_press.value == 0 && !_press.isAnimating) return;
    _press.reverse();
  }

  bool _hover = false;

  void _setHover(bool v) {
    if (v == _hover) return;
    _hover = v;
    if (_enabled || !v) widget.onHoverChanged?.call(v);
  }

  void _activate() {
    if (!_enabled) return;
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final ring = widget.ringColor ?? context.palette.primary;
    Widget body = widget.pressScale == 1.0
        ? widget.child
        : ScaleTransition(scale: _scale, child: widget.child);

    body = Stack(
      clipBehavior: Clip.none,
      children: [
        body,
        if (_focusHighlight)
          Positioned(
            left: -widget.ringGap,
            top: -widget.ringGap,
            right: -widget.ringGap,
            bottom: -widget.ringGap,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: widget.circle
                      ? null
                      : widget.borderRadius +
                            BorderRadius.circular(widget.ringGap),
                  border: Border.all(color: ring, width: 2),
                ),
              ),
            ),
          ),
      ],
    );

    body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _enabled ? (_) => _down() : null,
      onTapUp: _enabled ? (_) => _up() : null,
      onTapCancel: _enabled ? _up : null,
      onTap: _enabled ? _activate : null,
      child: body,
    );

    if (widget.excludeChildSemantics) body = ExcludeSemantics(child: body);

    body = Semantics(
      container: true,
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup ? true : null,
      label: widget.semanticLabel,
      child: body,
    );

    body = FocusableActionDetector(
      enabled: _enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      mouseCursor: _enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _activate();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (v) {
        if (v != _focusHighlight) setState(() => _focusHighlight = v);
        widget.onFocusHighlightChanged?.call(v);
      },
      child: body,
    );

    // Raw mouse hover (MouseRegion ignores touch). Not gated on the focus
    // highlight mode, so the hover effect works on hybrid devices too.
    if (widget.onHoverChanged != null) {
      body = MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        child: body,
      );
    }

    if (widget.tooltip != null) {
      body = Tooltip(
        message: widget.tooltip!,
        excludeFromSemantics: widget.semanticLabel != null,
        child: body,
      );
    }
    return body;
  }
}
