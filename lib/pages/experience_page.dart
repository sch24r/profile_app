import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../shell/site_shell.dart';

/// Stub — replaced by the real page in the sections/pages step.
class ExperiencePage extends StatelessWidget {
  const ExperiencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SiteShell(
      section: SiteSection.experience,
      children: [SizedBox(height: 400)],
    );
  }
}
