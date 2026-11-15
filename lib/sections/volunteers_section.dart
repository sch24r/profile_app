import 'package:flutter/material.dart';

import '../core/context_x.dart';
import '../core/max_width.dart';
import '../data/cv.dart';
import '../data/models.dart';
import '../data/sections.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';
import '../widgets/motion/horizontal_rail.dart';
import '../widgets/motion/reveal.dart';
import '../widgets/ui/bento_card.dart';
import '../widgets/ui/chip_tag.dart';
import '../widgets/ui/fit_height.dart';
import '../widgets/ui/section_header.dart';
import '../widgets/ui/segmented_pill.dart';
import 'experience_section.dart';
import 'see_all.dart';

/// Home row 8 — the 3 most recent volunteer events as compact rows:
/// event, role(s), focus chip, mono date (Reveal). No location on Home.
class VolunteeringPreview extends StatelessWidget {
  const VolunteeringPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final bp = context.bp;
    final events = Cv.recentVolunteers(3);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Layout.sectionPadding(bp)),
      child: MaxWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SectionHeader(
              eyebrow: 'Experience',
              titleLines: ['VOLUNTEERING'],
              trailing: SeeAllButton(
                section: SiteSection.experience,
                tab: 'volunteering',
              ),
            ),
            SizedBox(height: Layout.headerGap(bp)),
            for (var i = 0; i < events.length; i++)
              Reveal(
                index: i,
                child: _VolunteerRow(
                  key: ValueKey('card:volunteering:$i'),
                  entry: events[i],
                  last: i == events.length - 1,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _VolunteerRow extends StatelessWidget {
  const _VolunteerRow({super.key, required this.entry, required this.last});

  final VolunteerEntry entry;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final t = AppType.of(context);
    final side = BorderSide(color: p.hairline);
    final roles = entry.roles.map((r) => r.title).join(' · ');
    final focus = <String>{
      for (final r in entry.roles)
        if (r.focus != null) r.focus!,
    };

    final date = Text(
      entry.period.monoLabel,
      style: t.mono.copyWith(color: p.primary),
    );
    final chips = [for (final f in focus) ChipTag(f, style: ChipStyle.filled)];
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(entry.event, style: t.title.copyWith(color: p.ink)),
        const SizedBox(height: Space.s4),
        Text(roles, style: t.body.copyWith(color: p.inkMuted)),
      ],
    );

    final Widget content;
    if (context.isMobile) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          date,
          const SizedBox(height: Space.s8),
          titleBlock,
          if (chips.isNotEmpty) ...[
            const SizedBox(height: Space.s12),
            Wrap(spacing: Space.s8, runSpacing: Space.s8, children: chips),
          ],
        ],
      );
    } else {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 6, child: titleBlock),
          const SizedBox(width: Space.s24),
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: Space.s8,
              runSpacing: Space.s8,
              children: chips,
            ),
          ),
          const SizedBox(width: Space.s24),
          SizedBox(
            width: context.isDesktop ? 220 : 170,
            child: Align(alignment: Alignment.centerRight, child: date),
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: side, bottom: last ? side : BorderSide.none),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: context.isMobile ? Space.s20 : Space.s24,
        ),
        child: content,
      ),
    );
  }
}

enum _VolunteerFilter { all, author, organizing }

/// Experience › Volunteering: a local (non-URL) SegmentedPill filter above a
/// rail of the 12 events, newest first. An event with both kinds of roles
/// counts in both filters.
class VolunteeringRail extends StatefulWidget {
  const VolunteeringRail({super.key});

  @override
  State<VolunteeringRail> createState() => _VolunteeringRailState();
}

class _VolunteeringRailState extends State<VolunteeringRail> {
  static final List<VolunteerEntry> _all = Cv.recentVolunteers(
    Cv.volunteers.length,
  );

  _VolunteerFilter _filter = _VolunteerFilter.all;

  static bool _matches(VolunteerEntry e, _VolunteerFilter f) => switch (f) {
    _VolunteerFilter.all => true,
    _VolunteerFilter.author => e.roles.any((r) => r.isChallengeAuthor),
    _VolunteerFilter.organizing => e.roles.any((r) => !r.isChallengeAuthor),
  };

  static List<VolunteerEntry> _of(_VolunteerFilter f) => [
    for (final e in _all)
      if (_matches(e, f)) e,
  ];

  static const _tones = [
    CardTone.surface,
    CardTone.lilac,
    CardTone.periwinkle,
    CardTone.mint,
    CardTone.peach,
  ];

  @override
  Widget build(BuildContext context) {
    final items = _of(_filter);
    String label(String name, _VolunteerFilter f) => '$name (${_of(f).length})';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MaxWidth(
          child: SegmentedPill<_VolunteerFilter>(
            dense: true,
            value: _filter,
            onChanged: (f) => setState(() => _filter = f),
            options: [
              (_VolunteerFilter.all, label('All', _VolunteerFilter.all)),
              (
                _VolunteerFilter.author,
                // Phones: the full term cannot fit a third of 312 px.
                label(
                  context.isMobile ? 'Author' : 'Challenge Author',
                  _VolunteerFilter.author,
                ),
              ),
              (
                _VolunteerFilter.organizing,
                label('Organizing', _VolunteerFilter.organizing),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.s12),
        Expanded(
          child: HorizontalRail(
            key: ValueKey(_filter),
            itemCount: items.length,
            semanticLabel: 'Volunteering',
            itemBuilder: (context, i) => _VolunteerCard(
              key: ValueKey('card:volunteering:$i'),
              entry: items[i],
              tone: _tones[i % _tones.length],
            ),
          ),
        ),
      ],
    );
  }
}

class _VolunteerCard extends StatelessWidget {
  const _VolunteerCard({super.key, required this.entry, required this.tone});

  final VolunteerEntry entry;
  final CardTone tone;

  @override
  Widget build(BuildContext context) {
    final t = AppType.of(context);
    final tones = tone.resolve(context.palette);
    final mobile = context.isMobile;
    return BentoCard(
      tone: tone,
      child: FitHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              entry.period.monoLabel,
              style: t.label.copyWith(color: tones.accent),
            ),
            const SizedBox(height: Space.s12),
            Text(
              entry.event,
              style: (mobile ? t.title : t.headingM).copyWith(color: tones.fg),
            ),
            const SizedBox(height: Space.s8),
            Text(
              entry.location,
              style: t.caption.copyWith(color: tones.fgMuted),
            ),
            for (final role in entry.roles) ...[
              SizedBox(height: mobile ? Space.s12 : Space.s16),
              Text(
                role.title,
                style: (mobile ? t.caption : t.title).copyWith(
                  color: tones.fg,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: Space.s8),
              CvBullets(
                role.bullets,
                style: t.body.copyWith(color: tones.fgMuted),
                dotColor: tones.accent,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
