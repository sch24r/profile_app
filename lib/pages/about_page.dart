import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../shell/sub_page_shell.dart';

/// Stub — replaced by the real page in the sections/pages step.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageShell(
      section: SiteSection.about,
      eyebrow: 'ABOUT',
      titleLines: const ['ABOUT'],
      tabs: SiteSection.about.tabs,
      bodyBuilder: (context, tab) => const SizedBox.expand(),
    );
  }
}
