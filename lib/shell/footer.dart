import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../core/max_width.dart';
import '../core/router.dart';
import '../data/cv.dart';
import '../data/sections.dart';
import '../theme/motion.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// Static Home-only footer on `surface`: large wordmark, page links,
/// hairline and the copyright line. No motion. Deliberately holds NO contact
/// details or location (those live in ContactPanel and the hero toast).
class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final bp = context.bp;
    final gap = Layout.headerGap(bp);

    final wordmark = Semantics(
      header: true,
      child: Text(
        Cv.nameLines.join('\n'),
        style: t.displayM.copyWith(color: p.display),
      ),
    );

    final pages = _FooterColumn(
      title: 'Pages',
      children: [
        for (final s in SiteSection.values)
          ShellTextLink(label: s.label, onTap: () => AppNav.go(context, s)),
      ],
    );

    final Widget columns = bp == Bp.mobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              wordmark,
              SizedBox(height: gap),
              pages,
            ],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: wordmark),
              const SizedBox(width: Space.s32),
              Expanded(child: pages),
            ],
          );

    return ColoredBox(
      color: p.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            top: Layout.sectionPadding(bp),
            bottom: Space.s32,
          ),
          child: MaxWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                columns,
                SizedBox(height: gap),
                Divider(color: p.hairline, height: 1, thickness: 1),
                const SizedBox(height: Space.s24),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: Space.s16,
                  runSpacing: Space.s8,
                  children: [
                    Text(
                      '© 2026 ${Cv.contact.name}',
                      style: t.caption.copyWith(color: p.inkMuted),
                    ),
                    ShellTextLink(
                      label: 'Back to top ↑',
                      style: t.caption.copyWith(color: p.inkMuted),
                      onTap: () {
                        final position = Scrollable.maybeOf(context)?.position;
                        if (position == null) return;
                        if (context.reduceMotion) {
                          position.jumpTo(0);
                        } else {
                          position.animateTo(
                            0,
                            duration: Motion.scrollToDuration,
                            curve: Motion.scrollTo,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '// ${title.toUpperCase()}',
          style: AppType.of(context).label.copyWith(color: p.inkMuted),
        ),
        const SizedBox(height: Space.s16),
        for (final c in children)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.s8),
            child: c,
          ),
      ],
    );
  }
}

/// Plain text link used by the shell (footer, menu panel): underline on
/// hover, 2 px primary focus ring, Enter/Space activation, link semantics.
/// Min touch height on touch layouts.
class ShellTextLink extends StatefulWidget {
  const ShellTextLink({
    super.key,
    required this.label,
    required this.onTap,
    this.style,
    this.color,
  });

  final String label;
  final VoidCallback onTap;

  /// Defaults to `AppType.body`.
  final TextStyle? style;

  /// Defaults to `palette.ink`.
  final Color? color;

  @override
  State<ShellTextLink> createState() => _ShellTextLinkState();
}

class _ShellTextLinkState extends State<ShellTextLink> {
  bool _hover = false;
  bool _focus = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = widget.color ?? p.ink;
    final style = (widget.style ?? AppType.of(context).body).copyWith(
      color: color,
      decoration: _hover ? TextDecoration.underline : TextDecoration.none,
      decorationColor: color,
    );
    return FocusableActionDetector(
      mouseCursor: SystemMouseCursors.click,
      onShowHoverHighlight: (v) => setState(() => _hover = v),
      onShowFocusHighlight: (v) => setState(() => _focus = v),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: Semantics(
        link: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: context.isDesktop ? 0 : 40),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.xs),
                border: _focus ? Border.all(color: p.primary, width: 2) : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Text(widget.label, style: style),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
