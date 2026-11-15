// Content rules (docs/plan.md › Content rules, Verification › Content).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profile_app/data/cv.dart';
import 'package:profile_app/data/models.dart';
import 'package:profile_app/pages/home_page.dart';

import 'support/harness.dart';

/// Text that only exists in the CV's excluded Trainings / Certifications &
/// Courses sections. (Bare "Training" is not listed: the UKM Cyber Security
/// ITS bullet "Training members on information security." is CV text.)
const _excluded = [
  'Trainings',
  'TRAININGS',
  'Certif',
  'CERTIF',
  'LinuxONE',
  'Dicoding',
  'Sololearn',
  'Scrum',
  'Pelatihan',
  'Latihan Keterampilan',
  'Turbonomic',
  'Ichiro',
  'Study Jam',
  'ISE! Academy',
  'Talent Scouting',
  'Version Control System Training',
  'Courses',
];

const _homeSections = [
  'about',
  'education',
  'work',
  'achievements',
  'projects',
  'organizations',
  'volunteering',
  'skills',
  'contact',
];

/// Expected card counts on Home per kind (plan › Home table).
const _homeCounts = {
  'profile': 1,
  'interests': 3,
  'languages': 1,
  'education': 1,
  'work': 2,
  'podium': 5,
  'projects': 3,
  'organizations': 2,
  'volunteering': 3,
};

Iterable<File> _dartFiles(String dir) =>
    Directory(dir)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

void main() {
  group('CV model', () {
    test('counts match the CV', () {
      expect(Cv.occupations, hasLength(4));
      expect(Cv.organizations, hasLength(4));
      expect(Cv.volunteers, hasLength(12));
      expect(Cv.volunteers.expand((v) => v.roles), hasLength(13));
      expect(Cv.achievements, hasLength(8));
      expect(Cv.projects, hasLength(4));
      expect(Cv.languages, hasLength(3));
      expect(Cv.education, hasLength(2));
      expect(Cv.interests, hasLength(3));
      expect(Cv.skills, hasLength(5));
      expect(Cv.skills.map((g) => g.items.length), [14, 3, 5, 13, 3]);
      expect(
        Cv.volunteers.where((v) => v.roles.any((r) => r.isChallengeAuthor)),
        hasLength(6),
      );
      expect(
        Cv.volunteers.where((v) => v.roles.any((r) => !r.isChallengeAuthor)),
        hasLength(7),
      );
      expect(Cv.qualifications, hasLength(3));
    });

    test('key entries are transcribed verbatim', () {
      expect(Cv.contact.email, 'schello24r@gmail.com');
      expect(Cv.contact.linkedin, 'linkedin.com/in/marchelloputrar');
      expect(Cv.education.first.scoreText, '3.66/4.00');
      expect(Cv.occupations.map((o) => o.role).toSet(), {
        'Teaching Assistant',
        'Regional Innovation Assessor Intern',
      });
      expect(
        Cv.achievements.map((a) => a.outcome),
        contains('1st place out of 473 participating teams.'),
      );
      expect(
        Cv.organizations.expand((o) => o.bullets),
        contains('Training members on information security.'),
      );
      expect(Cv.status, 'Based in Kediri, East Java');
    });

    test('recent helpers are newest first with the plan counts', () {
      expect(Cv.recentOccupations(2).map((o) => o.period.start.year), [
        2026,
        2026,
      ]);
      expect(
        Cv.recentOccupations(2).last.role,
        'Regional Innovation Assessor Intern',
      );
      expect(Cv.recentOccupations(4), hasLength(4));
      expect(Cv.recentOrganizations(2).map((o) => o.org), [
        'OSMOSIS Association',
        'UKM Cyber Security ITS',
      ]);
      expect(Cv.recentVolunteers(3).map((v) => v.event), [
        'Schematics ITS National Programming Contest CTF 2026',
        'Diskominfo Jatim Cybersecurity Competition 2026',
        'Heroes Cyber Security Webinar and Internal Selection CTF 2026',
      ]);
      expect(Cv.podiumByRecency.map((a) => a.event), [
        'GEMATIK V Cyber Security',
        'FIK CUP CTF 2025',
        'No Hack No CTF 2025',
        'Standoff Cyberbattle SPIEF 2025',
        'GKSK #9 OSINTATHON',
      ]);
      expect(Cv.recentProjects(3).map((p) => p.title), [
        'AccelerEd',
        'Hum Catcher',
        'Blockchain 101',
      ]);
    });

    test('Trainings and Certifications are absent from all app code', () {
      for (final f in _dartFiles('lib')) {
        // Code and string literals only: comments may document the exclusion.
        final src = f
            .readAsLinesSync()
            .where((l) => !l.trimLeft().startsWith('//'))
            .join('\n');
        for (final word in _excluded) {
          expect(src.contains(word), isFalse, reason: '"$word" in ${f.path}');
        }
      }
      for (final path in ['web/index.html', 'web/manifest.json']) {
        final src = File(path).readAsStringSync();
        for (final word in _excluded) {
          expect(src.contains(word), isFalse, reason: '"$word" in $path');
        }
      }
    });

    test('no stats model remains', () {
      final src = File('lib/data/cv.dart').readAsStringSync();
      expect(src.contains('stats'), isFalse);
      expect(src.contains('topAchievement'), isFalse);
      expect(File('lib/widgets/ui/stat_tile.dart').existsSync(), isFalse);
    });
  });

  for (final size in const [Size(390, 844), Size(1440, 900)]) {
    testWidgets('Home ${size.width.toInt()}: every section, recent counts, '
        'no repeated facts', (tester) async {
      setViewport(tester, size, reduceMotion: true);
      await pumpApp(tester, settle: const Duration(milliseconds: 600));
      expect(find.byType(HomePage), findsOneWidget);

      final scrollable = find
          .descendant(
            of: find.byType(HomePage),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is Scrollable &&
                  axisDirectionToAxis(w.axisDirection) == Axis.vertical,
            ),
          )
          .first;

      final seenKinds = <String, Set<String>>{};
      final seeAll = <String>{};
      final facts = <String, int>{'473': 0, '3.66': 0, 'Kediri': 0};
      for (final name in _homeSections) {
        final section = find.byKey(ValueKey('home:$name'), skipOffstage: false);
        await tester.scrollUntilVisible(section, 300, scrollable: scrollable);
        await tester.pump(const Duration(milliseconds: 200));
        expect(section, findsOneWidget, reason: 'home:$name is rendered');
        for (final k in cardKeys(tester, scope: section)) {
          if (k.endsWith(':see-all')) {
            seeAll.add(k);
            continue;
          }
          seenKinds.putIfAbsent(kindOf(k), () => {}).add(k);
        }
        for (final fact in facts.keys.toList()) {
          facts[fact] =
              facts[fact]! + textOccurrences(tester, fact, scope: section);
        }
      }

      for (final MapEntry(key: kind, value: n) in _homeCounts.entries) {
        expect(seenKinds[kind]?.length ?? 0, n, reason: 'Home "$kind" cards');
      }
      expect(
        seenKinds.keys.toSet().difference(_homeCounts.keys.toSet()),
        isEmpty,
      );
      expect(seeAll, {
        'card:projects:see-all',
      }, reason: 'See all projects card');
      // Each fact once on Home (location only in the hero toast).
      facts.forEach((fact, n) => expect(n, 1, reason: '"$fact" on Home'));
      for (final word in _excluded) {
        expect(textOccurrences(tester, word), 0, reason: word);
      }
      await unmount(tester);
    });
  }

  test('Period labels', () {
    expect(const Period(YM(2024, 8)).monoLabel, 'AUG 2024 — NOW');
    expect(const Period.month(YM(2025, 9)).label, 'Sep 2025');
  });
}
