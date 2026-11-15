import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../sections/achievements_chapter.dart';
import '../shell/sub_page_shell.dart';

/// /achievements — one screen (SubPageShell) with a HorizontalRail body.
class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageShell(
      section: SiteSection.achievements,
      eyebrow: 'ACHIEVEMENTS',
      titleLines: const ['CAPTURE', 'THE FLAG'],
      tabs: SiteSection.achievements.tabs,
      bodyBuilder: (context, tab) => switch (tab) {
        'qualifications' => const QualificationsRail(
          key: ValueKey('page:achievements:qualifications'),
        ),
        _ => const PodiumRail(key: ValueKey('page:achievements:podium')),
      },
    );
  }
}
