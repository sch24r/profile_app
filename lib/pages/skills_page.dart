import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../sections/skills_section.dart';
import '../shell/sub_page_shell.dart';

/// /skills — one screen (SubPageShell) with a HorizontalRail body.
class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageShell(
      section: SiteSection.skills,
      eyebrow: 'SKILLS',
      titleLines: const ['TOOLKIT'],
      tabs: SiteSection.skills.tabs,
      bodyBuilder: (context, tab) =>
          const SkillsRail(key: ValueKey('page:skills')),
    );
  }
}
