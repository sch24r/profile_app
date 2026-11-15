import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../shell/site_shell.dart';

/// Stub — replaced by the real page in the sections/pages step.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SiteShell(
      section: SiteSection.about,
      children: [SizedBox(height: 400)],
    );
  }
}
