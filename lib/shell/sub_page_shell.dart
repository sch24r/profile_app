import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../core/max_width.dart';
import '../core/router.dart';
import '../data/sections.dart';
import '../theme/motion.dart';
import '../theme/spacing.dart';
import '../widgets/motion/pointer_tilt.dart';
import 'intro_overlay.dart';
import 'page_header.dart';
import 'site_header.dart';
import 'site_shell.dart';

/// EVERY SUB-PAGE. One fixed screen: no vertical scroll view, no footer.
///
/// Layout: `Column[ header clearance, PageHeader, Expanded(body) ]` under the
/// floating [SiteHeader] (always expanded on sub-pages), plus a
/// [PointerTracker]. The active tab comes from [AppNav.tabOf] (default: the
/// first tab); tapping a tab calls [AppNav.setTab] (URL query replaced, no
/// route push). Bodies cross-fade ([Motion.segmentContent], no slide) and only
/// the active tab's body is built. The body receives all remaining height
/// (minus the bottom safe area + 16 px) — pass it to a `HorizontalRail`.
class SubPageShell extends StatefulWidget {
  const SubPageShell({
    super.key,
    required this.section,
    required this.eyebrow,
    required this.titleLines,
    this.lead,
    this.tabs = const [],
    required this.bodyBuilder,
  });

  final SiteSection section;
  final String eyebrow;
  final List<String> titleLines;
  final String? lead;

  /// (id, label); empty → no tab bar.
  final List<(String id, String label)> tabs;

  /// Builds the body for the active tab (null when there are no tabs).
  final Widget Function(BuildContext context, String? tab) bodyBuilder;

  @override
  State<SubPageShell> createState() => _SubPageShellState();
}

class _SubPageShellState extends State<SubPageShell> {
  final ValueNotifier<Offset?> _pointer = ValueNotifier<Offset?>(null);
  final ValueNotifier<String?> _noRoute = ValueNotifier<String?>(null);
  bool _trackPointer = false;

  @override
  void initState() {
    super.initState();
    // Whatever page is shown first consumes the once-per-session intro.
    IntroOverlay.markPlayed();
  }

  @override
  void dispose() {
    _pointer.dispose();
    _noRoute.dispose();
    super.dispose();
  }

  void _onPointer(PointerEvent e) {
    if (_trackPointer && e.kind == PointerDeviceKind.mouse) {
      _pointer.value = e.position;
    }
  }

  String? _resolve(String? tab) {
    if (widget.tabs.isEmpty) return null;
    return widget.tabs.any((t) => t.$1 == tab) ? tab : widget.tabs.first.$1;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bp = context.bp;
    final ValueListenable<String?> tabs = ModalRoute.of(context) == null
        ? _noRoute
        : AppNav.tabListenable(context);

    _trackPointer = context.pointerEffects;
    if (!_trackPointer && _pointer.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pointer.value = null;
      });
    }

    final content = ValueListenableBuilder<String?>(
      valueListenable: tabs,
      builder: (context, rawTab, _) {
        final tab = _resolve(rawTab);
        final body = KeyedSubtree(
          key: ValueKey<String?>('tab:$tab'),
          child: widget.bodyBuilder(context, tab),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: SiteShell.headerClearance(context)),
            MaxWidth(
              child: PageHeader(
                eyebrow: widget.eyebrow,
                titleLines: widget.titleLines,
                lead: widget.lead,
                tabs: widget.tabs,
                activeTab: tab,
                onTab: (id) => AppNav.setTab(context, widget.section, id),
              ),
            ),
            SizedBox(height: Layout.gridGap(bp) + Space.s8),
            Expanded(
              child: AnimatedSwitcher(
                duration: context.reduceMotion
                    ? Duration.zero
                    : Motion.segmentContent,
                switchInCurve: Motion.sineOut,
                switchOutCurve: Motion.sineOut,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [...previous, ?current],
                ),
                child: body,
              ),
            ),
            SizedBox(height: MediaQuery.paddingOf(context).bottom + 16),
          ],
        );
      },
    );

    return Scaffold(
      backgroundColor: palette.canvas,
      body: PointerTracker(
        position: _pointer,
        child: MouseRegion(
          opaque: false,
          onExit: (_) => _pointer.value = null,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerHover: _onPointer,
            onPointerMove: _onPointer,
            child: Stack(
              children: [
                Positioned.fill(child: content),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SiteHeader(section: widget.section),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
