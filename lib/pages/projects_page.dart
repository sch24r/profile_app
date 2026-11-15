import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../sections/projects_chapter.dart';
import '../shell/sub_page_shell.dart';

/// /projects — one screen (SubPageShell) with a HorizontalRail body.
class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageShell(
      section: SiteSection.projects,
      eyebrow: 'PROJECTS',
      titleLines: const ['THINGS', "I'VE BUILT"],
      tabs: SiteSection.projects.tabs,
      bodyBuilder: (context, tab) =>
          const ProjectsRail(key: ValueKey('page:projects')),
    );
  }
}
