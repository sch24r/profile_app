import 'package:flutter/foundation.dart';

/// Simple month-precision date. `null` end means "Now".
@immutable
class YM {
  const YM(this.year, this.month);
  final int year;
  final int month;

  static const _m = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _full = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get short => '${_m[month - 1]} $year';
  String get long => '${_full[month - 1]} $year';
  String get mono => '${_m[month - 1].toUpperCase()} $year';
}

@immutable
class Period {
  const Period(this.start, [this.end, this.single = false]);

  /// A single month (start == end).
  const Period.month(this.start) : end = null, single = true;
  final YM start;
  final YM? end;
  final bool single;

  bool get isCurrent => !single && end == null;

  /// "Sep 2025 – Dec 2025", "Mar 2026 – Now", "Sep 2025".
  String get label {
    if (single) {
      return start.short;
    }
    if (end == null) {
      return '${start.short} – Now';
    }
    if (end!.year == start.year && end!.month == start.month) {
      return start.short;
    }
    return '${start.short} – ${end!.short}';
  }

  /// "SEP 2025 — NOW" style for mono labels.
  String get monoLabel {
    if (single) {
      return start.mono;
    }
    if (end == null) {
      return '${start.mono} — NOW';
    }
    return '${start.mono} — ${end!.mono}';
  }
}

@immutable
class ContactInfo {
  const ContactInfo({
    required this.name,
    required this.shortName,
    required this.location,
    required this.phone,
    required this.phoneDisplay,
    required this.email,
    required this.linkedin,
    required this.linkedinUrl,
  });
  final String name;
  final String shortName;
  final String location;
  final String phone; // E.164 for tel:
  final String phoneDisplay;
  final String email;
  final String linkedin; // display
  final String linkedinUrl;
}

@immutable
class Education {
  const Education({
    required this.school,
    required this.program,
    required this.location,
    required this.period,
    required this.scoreLabel,
    required this.score,
    required this.scoreMax,
    this.department,
  });
  final String school;
  final String? department;
  final String program;
  final String location;
  final Period period;
  final String scoreLabel; // "GPA"
  final double score;
  final double scoreMax;

  String get scoreText =>
      '${score.toStringAsFixed(2)}/${scoreMax.toStringAsFixed(2)}';
}

@immutable
class Experience {
  const Experience({
    required this.org,
    required this.role,
    required this.location,
    required this.period,
    required this.bullets,
    this.tags = const [],
  });
  final String org;
  final String role;
  final String location;
  final Period period;
  final List<String> bullets;
  final List<String> tags;
}

@immutable
class VolunteerRole {
  const VolunteerRole({
    required this.title,
    required this.bullets,
    this.isChallengeAuthor = false,
    this.focus,
  });
  final String title;
  final List<String> bullets;
  final bool isChallengeAuthor;

  /// e.g. "Git forensics", "OSINT", "Digital forensics".
  final String? focus;
}

@immutable
class VolunteerEntry {
  const VolunteerEntry({
    required this.event,
    required this.location,
    required this.period,
    required this.roles,
  });
  final String event;
  final String location;
  final Period period;
  final List<VolunteerRole> roles;
}

enum Scope { national, international }

@immutable
class Achievement {
  const Achievement({
    required this.event,
    required this.organizer,
    required this.scope,
    required this.date,
    required this.description,
    required this.outcome,
    this.rank,
    this.field,
    this.note,
  });
  final String event;
  final String organizer;
  final Scope scope;
  final YM date;

  /// "A national-level capture the flag competition."
  final String description;

  /// CV bullet, verbatim: "1st place out of 473 participating teams."
  final String outcome;

  /// Podium rank (1, 2, 3, 5) — null for qualifications.
  final int? rank;

  /// Number of participating teams.
  final int? field;

  /// e.g. "Oil and gas industry".
  final String? note;

  bool get isRanked => rank != null;

  String get ordinal => switch (rank) {
    1 => '1st',
    2 => '2nd',
    3 => '3rd',
    null => '',
    _ => '${rank}th',
  };
}

@immutable
class InterestGroup {
  const InterestGroup(this.title, this.items);
  final String title;
  final String items; // CV text verbatim
}

@immutable
class SkillGroup {
  const SkillGroup(this.title, this.items);
  final String title;
  final List<String> items;
}

enum ProjectArt { terminal, blocks, waveform, bars }

@immutable
class Project {
  const Project({
    required this.title,
    required this.period,
    required this.summary,
    required this.tags,
    required this.art,
  });
  final String title;
  final Period period;
  final String summary; // CV text verbatim
  final List<String> tags;
  final ProjectArt art;
}

@immutable
class LanguageSkill {
  const LanguageSkill(this.name, this.level, this.label);
  final String name;
  final int level; // 1..5
  final String label; // CV text verbatim
}

@immutable
class Stat {
  const Stat({
    required this.value,
    required this.caption,
    required this.detail,
  });

  /// Display string, e.g. "1st", "4", "6", "3.66".
  final String value;
  final String caption;

  /// Hover / tap swap text (P11 caption swap).
  final String detail;
}
