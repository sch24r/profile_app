import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../shell/sub_page_shell.dart';

/// Stub — replaced by the real page in the sections/pages step.
class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageShell(
      section: SiteSection.projects,
      eyebrow: 'PROJECTS',
      titleLines: const ['PROJECTS'],
      tabs: SiteSection.projects.tabs,
      bodyBuilder: (context, tab) => const SizedBox.expand(),
    );
  }
}
