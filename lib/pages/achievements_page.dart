import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../shell/sub_page_shell.dart';

/// Stub — replaced by the real page in the sections/pages step.
class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageShell(
      section: SiteSection.achievements,
      eyebrow: 'ACHIEVEMENTS',
      titleLines: const ['ACHIEVEMENTS'],
      tabs: SiteSection.achievements.tabs,
      bodyBuilder: (context, tab) => const SizedBox.expand(),
    );
  }
}
