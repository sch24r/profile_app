import 'models.dart';

/// Single source of CV content (from "CV_Marchello Putra Ramadhan.pdf").
/// Trainings and Certifications & Courses are intentionally NOT included.
abstract final class Cv {
  static const showPhone = true;

  static const contact = ContactInfo(
    name: 'Marchello Putra Ramadhan',
    shortName: 'Marchello',
    location: 'Kediri, East Java, Indonesia',
    phone: '+6289509985214',
    phoneDisplay: '+62 895-0998-5214',
    email: 'schello24r@gmail.com',
    linkedin: 'linkedin.com/in/marchelloputrar',
    linkedinUrl: 'https://linkedin.com/in/marchelloputrar',
  );

  /// Hero name lines.
  static const nameLines = ['MARCHELLO', 'PUTRA', 'RAMADHAN'];

  static const headline =
      'Information Systems undergraduate at ITS · Cyber security, digital forensics & OSINT';

  /// Status toast (P5) — location only; the only place location appears on Home.
  static const status = 'Based in Kediri, East Java';

  static const profile =
      'An undergraduate student with a vision of becoming an idea initiator in '
      'the world of information technology, driven by a passion for computer '
      'systems and cyber security. Enthusiastic in exploring new knowledge, '
      'honing skills, following the latest technological developments, and '
      'always open to valuable input and collaborative opportunities. My goals '
      'are to shape groundbreaking innovations that address real-world '
      'challenges and deliver meaningful solutions for the future.';

  static const education = [
    Education(
      school: 'Institut Teknologi Sepuluh Nopember',
      department: 'Information Systems Department',
      program: 'Undergraduate in Digital Innovation',
      location: 'Surabaya, Indonesia',
      period: Period(YM(2024, 8)),
      scoreLabel: 'GPA',
      score: 3.66,
      scoreMax: 4.00,
    ),
    Education(
      school: 'SMA Negeri 2 Kediri',
      program: 'Senior High School in Mathematics and Science',
      location: 'Kediri, Indonesia',
      period: Period(YM(2021, 7), YM(2024, 6)),
      scoreLabel: 'GPA',
      score: 93.57,
      scoreMax: 100.00,
    ),
  ];

  /// Occupations, newest first (CV text verbatim).
  static const occupations = [
    Experience(
      org: 'Information Asset Protection - Information Systems of ITS',
      role: 'Teaching Assistant',
      location: 'Surabaya, Indonesia',
      period: Period(YM(2026, 9)),
      bullets: [
        'Guiding practical learning in cryptography and hash cracking.',
      ],
    ),
    Experience(
      org: 'Innovative Government Award 2026 - Badan Riset dan Inovasi Daerah Kota Surabaya',
      role: 'Regional Innovation Assessor Intern',
      location: 'Surabaya, Indonesia',
      period: Period(YM(2026, 7), YM(2026, 8)),
      bullets: [
        'Evaluating integrated services to ensure clear and standardized documentation.',
        'Performing quality and compliance checks on regional cooperation agreements.',
      ],
    ),
    Experience(
      org: 'Cyber Security - Informatics Engineering of Esa Unggul',
      role: 'Teaching Assistant',
      location: 'Online',
      period: Period(YM(2026, 3), YM(2026, 8)),
      bullets: [
        'Arranging theoretical materials and providing practical assignments.',
      ],
    ),
    Experience(
      org: 'Information Asset Protection - Information Systems of ITS',
      role: 'Teaching Assistant',
      location: 'Surabaya, Indonesia',
      period: Period(YM(2025, 9), YM(2025, 12)),
      bullets: [
        'Guiding practical learning in intelligence gathering and social engineering.',
      ],
    ),
  ];

  static const organizations = [
    Experience(
      org: 'Heroes Cyber Security',
      role: 'Member',
      location: 'Online',
      period: Period(YM(2024, 9)),
      bullets: [
        'Exchanging insights on information security.',
        'Collaborating with others to solve weekly cyber security challenges.',
      ],
    ),
    Experience(
      org: 'Google Developer Group on Campus ITS',
      role: 'Member of Cyber Security',
      location: 'Surabaya, Indonesia',
      period: Period(YM(2024, 12), YM(2025, 12)),
      bullets: [
        'Exchanging insights on web vulnerabilities and information disclosure.',
        'Completing weekly web exploitation challenges.',
      ],
    ),
    Experience(
      org: 'UKM Cyber Security ITS',
      role: 'Expert Staff of Internal Affairs',
      location: 'Surabaya, Indonesia',
      period: Period(YM(2025, 6)),
      bullets: [
        'Training members on information security.',
        'Directing member activities and maintaining well-documented archives.',
      ],
    ),
    Experience(
      org: 'OSMOSIS Association',
      role: 'Member',
      location: 'Online',
      period: Period(YM(2026, 1)),
      bullets: ['Exchanging insights on intelligence gathering disciplines.'],
    ),
  ];

  /// Volunteer events in CV order (12 events, 13 roles).
  static const volunteers = [
    VolunteerEntry(
      event: 'YouthBiz Project ITS 2025',
      location: 'Surabaya, Indonesia',
      period: Period(YM(2024, 11), YM(2025, 7)),
      roles: [
        VolunteerRole(
          title: 'Staff of Data Management',
          bullets: [
            'Contributing to the data collection and documentation process under defined responsibilities.',
          ],
        ),
      ],
    ),
    VolunteerEntry(
      event: 'Inovasi Digital Exhibition ITS 2025',
      location: 'Surabaya, Indonesia',
      period: Period(YM(2025, 4), YM(2025, 10)),
      roles: [
        VolunteerRole(
          title: 'Lead of Data Management',
          bullets: [
            'Overseeing event data and archival systems to ensure accuracy, accessibility, and compliance.',
          ],
        ),
      ],
    ),
    VolunteerEntry(
      event: 'Information Systems Expo ITS 2025',
      location: 'Surabaya, Indonesia',
      period: Period(YM(2025, 5), YM(2025, 10)),
      roles: [
        VolunteerRole(
          title: 'Staff of IT Development',
          bullets: [
            'Implementing assigned backend components.',
            'Contributing to the microservice system based on defined tasks.',
          ],
        ),
      ],
    ),
    VolunteerEntry(
      event: 'Mini CTF UCS ITS 2025',
      location: 'Surabaya, Indonesia',
      period: Period.month(YM(2025, 9)),
      roles: [
        VolunteerRole(
          title: 'Challenge Author',
          bullets: ['Providing git forensics challenges.'],
          isChallengeAuthor: true,
          focus: 'Git forensics',
        ),
      ],
    ),
    VolunteerEntry(
      event: 'Heroes Cyber Security Webinar and Internal Selection CTF 2025',
      location: 'Online',
      period: Period.month(YM(2025, 9)),
      roles: [
        VolunteerRole(
          title: 'Staff of Event and Publication',
          bullets: [
            'Handling event operations and producing promotional publications.',
          ],
        ),
        VolunteerRole(
          title: 'Challenge Author',
          bullets: ['Providing open source intelligence challenges.'],
          isChallengeAuthor: true,
          focus: 'OSINT',
        ),
      ],
    ),
    VolunteerEntry(
      event: 'Schematics ITS National Programming Contest CTF 2025',
      location: 'Surabaya, Indonesia',
      period: Period(YM(2025, 10), YM(2025, 11)),
      roles: [
        VolunteerRole(
          title: 'Challenge Author',
          bullets: ['Providing digital forensics challenges.'],
          isChallengeAuthor: true,
          focus: 'Digital forensics',
        ),
      ],
    ),
    VolunteerEntry(
      event: 'A Renewal Agent ITS 7.0 CTF',
      location: 'Surabaya, Indonesia',
      period: Period.month(YM(2026, 2)),
      roles: [
        VolunteerRole(
          title: 'Challenge Author',
          bullets: ['Providing git forensics challenges.'],
          isChallengeAuthor: true,
          focus: 'Git forensics',
        ),
      ],
    ),
    VolunteerEntry(
      event: 'Information Systems Expo ITS 2026',
      location: 'Surabaya, Indonesia',
      period: Period(YM(2026, 3)),
      roles: [
        VolunteerRole(
          title: 'Expert Staff of IT Development',
          bullets: [
            'Troubleshooting and debugging backend systems to resolve technical issues efficiently.',
            'Reviewing codes to ensure backend implementations meet technical standards.',
          ],
        ),
      ],
    ),
    VolunteerEntry(
      event: 'CyberHack 2026',
      location: 'Surabaya, Indonesia',
      period: Period(YM(2026, 5), YM(2026, 6)),
      roles: [
        VolunteerRole(
          title: 'Staff of Event',
          bullets: [
            'Serving as a liaison officer to brief participants and judges on the facility and schedule.',
            'Serving as a timekeeper to track session timings and alert speakers on the schedule.',
          ],
        ),
      ],
    ),
    VolunteerEntry(
      event: 'Heroes Cyber Security Webinar and Internal Selection CTF 2026',
      location: 'Online',
      period: Period.month(YM(2026, 9)),
      roles: [
        VolunteerRole(
          title: 'Staff of Marketing',
          bullets: [
            'Designing visual content to drive promotional publications.',
          ],
        ),
      ],
    ),
    VolunteerEntry(
      event: 'Diskominfo Jatim Cybersecurity Competition 2026',
      location: 'Surabaya, Indonesia',
      period: Period.month(YM(2026, 9)),
      roles: [
        VolunteerRole(
          title: 'Challenge Author',
          bullets: ['Providing digital forensics challenges.'],
          isChallengeAuthor: true,
          focus: 'Digital forensics',
        ),
      ],
    ),
    VolunteerEntry(
      event: 'Schematics ITS National Programming Contest CTF 2026',
      location: 'Surabaya, Indonesia',
      period: Period(YM(2026, 10), YM(2026, 11)),
      roles: [
        VolunteerRole(
          title: 'Challenge Author',
          bullets: ['Providing digital forensics challenges.'],
          isChallengeAuthor: true,
          focus: 'Digital forensics',
        ),
      ],
    ),
  ];

  /// Achievements in CV order (chronological).
  static const achievements = [
    Achievement(
      event: 'GKSK #9 OSINTATHON',
      organizer: 'HIMAPRODI Sistem Komputer ITB STIKOM Bali',
      scope: Scope.national,
      date: YM(2025, 5),
      description: 'A national-level capture the flag competition focused on open source intelligence.',
      outcome: '3rd place out of 22 participating teams.',
      rank: 3,
      field: 22,
    ),
    Achievement(
      event: 'Standoff Cyberbattle SPIEF 2025',
      organizer: 'Positive Technologies',
      scope: Scope.international,
      date: YM(2025, 6),
      description: 'An international-level cyberbattle that features live attack and defense across industrial infrastructures.',
      outcome: '5th place out of 20 participating teams in the oil and gas industry.',
      rank: 5,
      field: 20,
      note: 'Oil and gas industry',
    ),
    Achievement(
      event: 'No Hack No CTF 2025',
      organizer: 'ICEDTEA',
      scope: Scope.international,
      date: YM(2025, 7),
      description: 'An international-level capture the flag competition.',
      outcome: '1st place out of 473 participating teams.',
      rank: 1,
      field: 473,
    ),
    Achievement(
      event: 'FIK CUP CTF 2025',
      organizer: 'Fakultas Ilmu Komputer Universitas Internasional Batam',
      scope: Scope.national,
      date: YM(2025, 7),
      description: 'A national-level capture the flag competition.',
      outcome: '1st place out of 10 participating teams.',
      rank: 1,
      field: 10,
    ),
    Achievement(
      event: 'GEMASTIK XVIII Cyber Security',
      organizer: 'Kementerian Pendidikan Dasar dan Menengah',
      scope: Scope.national,
      date: YM(2025, 8),
      description: 'A national-level capture the flag competition.',
      outcome: 'Qualified as 1 of 9 representative teams from ITS through internal selection.',
    ),
    Achievement(
      event: 'SRIFOTON CTF 2025',
      organizer: 'HMIF Universitas Sriwijaya',
      scope: Scope.national,
      date: YM(2025, 9),
      description: 'A national-level capture the flag competition.',
      outcome: 'Qualified as 1 of 15 finalists out of 51 participating teams.',
      field: 51,
    ),
    Achievement(
      event: 'GEMATIK V Cyber Security',
      organizer: 'FTIK Universitas Teknokrat Indonesia',
      scope: Scope.national,
      date: YM(2025, 11),
      description: 'A national-level capture the flag competition.',
      outcome: '2nd place out of 54 participating teams.',
      rank: 2,
      field: 54,
    ),
    Achievement(
      event: 'GEMASTIK XIX Cyber Security',
      organizer: 'Kementerian Pendidikan Dasar dan Menengah',
      scope: Scope.national,
      date: YM(2026, 8),
      description: 'A national-level capture the flag competition.',
      outcome: 'Qualified as 1 of 10 representative teams from ITS through internal selection.',
    ),
  ];

  /// The 5 ranked results, newest first. Ties (same month) resolve to the
  /// entry listed later in the CV first: GEMATIK V 2nd, FIK CUP 1st,
  /// No Hack No CTF 1st, Standoff 5th, OSINTATHON 3rd.
  static List<Achievement> get podiumByRecency => _newestFirst(
    achievements.where((a) => a.isRanked).toList(),
    (a) => a.date,
  );

  static List<Achievement> get qualifications =>
      achievements.where((a) => !a.isRanked).toList(growable: false);

  static const interests = [
    InterestGroup(
      'Cyber Security',
      'Digital forensics, steganography, and open source intelligence.',
    ),
    InterestGroup(
      'System Administration',
      'Scripting, networking, and log analysis.',
    ),
    InterestGroup(
      'Web App Development',
      'Database interactions, server logic, and user experience of web applications.',
    ),
  ];

  static const skills = [
    SkillGroup('Programming Languages', [
      'C',
      'C++',
      'Dart',
      'Go',
      'Java',
      'JavaScript',
      'Lua',
      'Nix',
      'PHP',
      'Python',
      'QT',
      'R',
      'Shell Script',
      'Solidity',
    ]),
    SkillGroup('Databases', ['MongoDB', 'Redis', 'SQL']),
    SkillGroup('Frameworks', ['FastAPI', 'Flask', 'Flutter', 'Gin', 'Laravel']),
    SkillGroup('Softwares', [
      'Android Studio',
      'Apidog',
      'Autopsy',
      'Burp Suite',
      'Docker',
      'FTK Imager',
      'Git',
      'Neovim',
      'Office',
      'Packet Tracer',
      'Visual Studio Code',
      'Virtual Machine Manager',
      'Wireshark',
    ]),
    SkillGroup('Operating Systems', ['Android', 'Linux', 'Windows']),
  ];

  static const projects = [
    Project(
      title: 'Native Kernel Emulation',
      period: Period.month(YM(2024, 6)),
      summary: 'Emulating Ubuntu ARM LTS on mobile hardware by directly leverage the host’s native kernel.',
      tags: ['Ubuntu ARM LTS', 'Native kernel'],
      art: ProjectArt.terminal,
    ),
    Project(
      title: 'Blockchain 101',
      period: Period.month(YM(2025, 4)),
      summary: 'Developing a stateless web-based simulator in Go to demonstrate core blockchain mechanisms.',
      tags: ['Go', 'Blockchain'],
      art: ProjectArt.blocks,
    ),
    Project(
      title: 'Hum Catcher',
      period: Period.month(YM(2025, 11)),
      summary: 'Engineering a digital forensics tool in Python to extract and match ENF signals from audio recordings against power grid frequency databases.',
      tags: ['Python', 'ENF signals', 'Digital forensics'],
      art: ProjectArt.waveform,
    ),
    Project(
      title: 'AccelerEd',
      period: Period(YM(2026, 4), YM(2026, 6)),
      summary: 'Architecting a full-stack platform in Next.js that features AI-driven insights to streamline achievement tracking and career guidance for students.',
      tags: ['Next.js', 'AI-driven insights', 'Full-stack'],
      art: ProjectArt.bars,
    ),
  ];

  static const languages = [
    LanguageSkill('Indonesian', 5, 'Native or bilingual proficiency'),
    LanguageSkill('Javanese', 5, 'Native or bilingual proficiency'),
    LanguageSkill('English', 3, 'Limited working proficiency'),
  ];

  /// Ticker / marquee items (tools & topics).
  static const tickerItems = [
    'Autopsy',
    'FTK Imager',
    'Wireshark',
    'Burp Suite',
    'OSINT',
    'Steganography',
    'Git forensics',
    'Docker',
    'Neovim',
    'Go',
    'Python',
    'Flutter',
    'Gin',
    'FastAPI',
    'Redis',
    'MongoDB',
    'Linux',
    'Nix',
    'Solidity',
  ];

  static const focusAreas = ['Digital forensics', 'Steganography', 'OSINT'];

  // ---- "Recent" helpers (newest first by period start / date). ----------
  // Ties resolve to the entry listed later in the CV (the CV lists oldest →
  // newest within a section).

  static List<Experience> recentOccupations(int n) =>
      _newestFirst(occupations, (e) => e.period.start).take(n).toList();

  static List<Experience> recentOrganizations(int n) =>
      _newestFirst(organizations, (e) => e.period.start).take(n).toList();

  /// By event: Schematics NPC CTF 2026, Diskominfo Jatim 2026, Heroes CTF 2026, …
  static List<VolunteerEntry> recentVolunteers(int n) =>
      _newestFirst(volunteers, (e) => e.period.start).take(n).toList();

  static List<Project> recentProjects(int n) =>
      _newestFirst(projects, (p) => p.period.start).take(n).toList();

  static List<T> _newestFirst<T>(List<T> items, YM Function(T) key) {
    final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
    indexed.sort((a, b) {
      final ka = key(a.$2), kb = key(b.$2);
      final c = (kb.year * 12 + kb.month).compareTo(ka.year * 12 + ka.month);
      return c != 0 ? c : b.$1.compareTo(a.$1);
    });
    return [for (final e in indexed) e.$2];
  }
}
