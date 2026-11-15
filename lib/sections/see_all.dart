import 'package:flutter/material.dart';

import '../core/router.dart';
import '../data/sections.dart';
import '../widgets/ui/pill_button.dart';

/// The "See all →" pill used by every Home preview section. Opens [section]
/// (and [tab], via `?tab=`) with [AppNav.go].
class SeeAllButton extends StatelessWidget {
  const SeeAllButton({
    super.key,
    required this.section,
    this.tab,
    this.label = 'See all',
    this.variant = PillVariant.outline,
  });

  final SiteSection section;
  final String? tab;
  final String label;
  final PillVariant variant;

  @override
  Widget build(BuildContext context) {
    return PillButton(
      key: ValueKey('see-all:${section.name}${tab == null ? '' : ':$tab'}'),
      label: label,
      icon: Icons.arrow_forward_rounded,
      variant: variant,
      dense: true,
      semanticLabel: '$label ${tab ?? section.label}',
      onPressed: () => AppNav.go(context, section, tab: tab),
    );
  }
}
