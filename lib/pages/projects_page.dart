import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../shell/site_shell.dart';

/// Stub — replaced by the real page in the sections/pages step.
class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SiteShell(
      section: SiteSection.projects,
      children: [SizedBox(height: 400)],
    );
  }
}
