import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../core/max_width.dart';
import '../data/cv.dart';
import '../data/sections.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/motion/horizontal_rail.dart';
import '../widgets/motion/reveal.dart';
import '../widgets/ui/section_header.dart';
import 'experience_section.dart';
import 'see_all.dart';

/// Home row 7 — the 2 most recent organizations as equal-height cards
/// (Reveal). No location on Home (it lives only in the hero toast).
class OrganizationsPreview extends StatelessWidget {
  const OrganizationsPreview({super.key});

  static const _tones = [CardTone.lilac, CardTone.periwinkle];

  @override
  Widget build(BuildContext context) {
    final bp = context.bp;
    final gap = Layout.gridGap(bp);
    final orgs = Cv.recentOrganizations(2);
    final cards = [
      for (var i = 0; i < orgs.length; i++)
        Reveal(
          index: i,
          child: ExperienceCard(
            key: ValueKey('card:organizations:$i'),
            experience: orgs[i],
            tone: _tones[i % _tones.length],
            showLocation: false,
            fit: false,
          ),
        ),
    ];
    final Widget body;
    if (context.isMobile) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) SizedBox(height: gap),
            cards[i],
          ],
        ],
      );
    } else {
      body = IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(child: cards[i]),
            ],
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Layout.sectionPadding(bp)),
      child: MaxWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionHeader(
              eyebrow: 'Experience',
              titleLines: ['ORGANIZATIONS'],
              trailing: SeeAllButton(
                section: SiteSection.experience,
                tab: 'organizations',
              ),
            ),
            SizedBox(height: Layout.headerGap(bp)),
            body,
          ],
        ),
      ),
    );
  }
}

/// Experience › Organizations: all 4 organizations, newest first.
class OrganizationsRail extends StatelessWidget {
  const OrganizationsRail({super.key});

  static const _tones = [
    CardTone.lilac,
    CardTone.periwinkle,
    CardTone.surface,
    CardTone.mint,
  ];

  @override
  Widget build(BuildContext context) {
    final orgs = Cv.recentOrganizations(4);
    return HorizontalRail(
      itemCount: orgs.length,
      semanticLabel: 'Organizations',
      itemBuilder: (context, i) => ExperienceCard(
        key: ValueKey('card:organizations:$i'),
        experience: orgs[i],
        tone: _tones[i % _tones.length],
      ),
    );
  }
}
