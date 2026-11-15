import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../shell/sub_page_shell.dart';

/// Stub — replaced by the real page in the sections/pages step.
class ExperiencePage extends StatelessWidget {
  const ExperiencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageShell(
      section: SiteSection.experience,
      eyebrow: 'EXPERIENCE',
      titleLines: const ['EXPERIENCE'],
      tabs: SiteSection.experience.tabs,
      bodyBuilder: (context, tab) => const SizedBox.expand(),
    );
  }
}
