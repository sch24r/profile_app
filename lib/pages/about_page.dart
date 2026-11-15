import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../sections/about_section.dart';
import '../sections/education_section.dart';
import '../shell/sub_page_shell.dart';

/// /about — one screen (SubPageShell) with a HorizontalRail body.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageShell(
      section: SiteSection.about,
      eyebrow: 'ABOUT',
      titleLines: const ['ABOUT', 'ME'],
      tabs: SiteSection.about.tabs,
      bodyBuilder: (context, tab) => switch (tab) {
        'education' => const EducationRail(
          key: ValueKey('page:about:education'),
        ),
        _ => const ProfileRail(key: ValueKey('page:about:profile')),
      },
    );
  }
}
