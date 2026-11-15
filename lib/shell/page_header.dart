import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/motion/block_decode_text.dart';
import '../widgets/ui/segmented_pill.dart';

/// Sub-page title block used by [SubPageShell]: mono eyebrow, block-decoded
/// title (displayM on mobile, displayL on desktop, max 2 lines), optional
/// one-line lead and the P25 [SegmentedPill] tab bar.
///
/// Compact: the whole block is kept within 28% of the viewport height — the
/// title size shrinks (never below displayS) to fit that budget.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.titleLines,
    this.lead,
    this.tabs = const [],
    this.activeTab,
    this.onTab,
  });

  final String eyebrow;
  final List<String> titleLines;
  final String? lead;
  final List<(String, String)> tabs;
  final String? activeTab;
  final ValueChanged<String>? onTab;

  /// Fraction of the viewport height the header may use.
  static const double maxHeightFraction = 0.28;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final mobile = context.isMobile;
    final lines = titleLines.take(2).toList();

    final eyebrowText = eyebrow.trimLeft().startsWith('//')
        ? eyebrow
        : '// $eyebrow';
    final eyebrowStyle = t.label.copyWith(color: p.primary);
    final leadStyle = t.body.copyWith(color: p.inkMuted);
    final hasTabs = tabs.isNotEmpty && activeTab != null;
    final tabsHeight = hasTabs ? (mobile ? 44.0 : 48.0) : 0.0;

    // Height budget → title font size.
    final base = mobile ? t.displayM : t.displayL;
    final lineHeight = base.height ?? 0.95;
    final fixed =
        (eyebrowStyle.fontSize ?? 13) * 1.3 +
        Space.s8 +
        (lead != null ? (leadStyle.fontSize ?? 16) * 1.55 + Space.s8 : 0) +
        (hasTabs && mobile ? tabsHeight + Space.s16 : 0);
    final budget = context.screenHeight * maxHeightFraction - fixed;
    final maxSize = budget / (lines.length * lineHeight);
    final size = math.max(
      t.displayS.fontSize ?? 22,
      math.min(base.fontSize ?? 56, maxSize),
    );
    final titleStyle = base.copyWith(fontSize: size, color: p.ink);

    final title = BlockDecodeText(lines, style: titleStyle);

    final tabBar = hasTabs
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SegmentedPill<String>(
              options: tabs,
              value: activeTab!,
              dense: mobile,
              onChanged: (id) => onTab?.call(id),
            ),
          )
        : null;

    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(eyebrowText.toUpperCase(), style: eyebrowStyle),
        const SizedBox(height: Space.s8),
        Semantics(header: true, child: title),
        if (lead != null) ...[
          const SizedBox(height: Space.s8),
          Text(
            lead!,
            style: leadStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );

    if (tabBar == null) return text;
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          text,
          const SizedBox(height: Space.s16),
          tabBar,
        ],
      );
    }
    // Tablet / desktop: tabs sit at the right, aligned to the title baseline
    // area, so the header stays short.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: text),
        const SizedBox(width: Space.s24),
        Flexible(
          child: Align(alignment: Alignment.bottomRight, child: tabBar),
        ),
      ],
    );
  }
}
