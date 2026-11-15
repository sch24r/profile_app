import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../sections/experience_section.dart';
import '../sections/organizations_section.dart';
import '../sections/volunteers_section.dart';
import '../shell/sub_page_shell.dart';

/// /experience — one screen (SubPageShell) with a HorizontalRail body.
class ExperiencePage extends StatelessWidget {
  const ExperiencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageShell(
      section: SiteSection.experience,
      eyebrow: 'EXPERIENCE',
      titleLines: const ['EXPERIENCE'],
      tabs: SiteSection.experience.tabs,
      bodyBuilder: (context, tab) => switch (tab) {
        'organizations' => const OrganizationsRail(
          key: ValueKey('page:experience:organizations'),
        ),
        'volunteering' => const VolunteeringRail(
          key: ValueKey('page:experience:volunteering'),
        ),
        _ => const WorkRail(key: ValueKey('page:experience:work')),
      },
    );
  }
}
