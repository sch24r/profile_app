import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../shell/sub_page_shell.dart';

/// Stub — replaced by the real page in the sections/pages step.
class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageShell(
      section: SiteSection.skills,
      eyebrow: 'SKILLS',
      titleLines: const ['SKILLS'],
      tabs: SiteSection.skills.tabs,
      bodyBuilder: (context, tab) => const SizedBox.expand(),
    );
  }
}
