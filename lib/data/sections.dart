/// Top-level routes / sections of the site.
enum SiteSection {
  home('/', 'Home', 'Start'),
  about('/about', 'About', 'Profile · Education'),
  experience(
    '/experience',
    'Experience',
    'Work · Organizations · Volunteering',
  ),
  achievements('/achievements', 'Achievements', 'Podium · Qualifications'),
  projects('/projects', 'Projects', 'Things I\'ve built'),
  skills('/skills', 'Skills', 'Toolkit'),
  contact('/contact', 'Contact', 'Get in touch');

  const SiteSection(this.path, this.label, this.subtitle);
  final String path;
  final String label;
  final String subtitle;

  /// Tabs on this section's sub-page as (id, label); empty → no tab bar.
  /// The first tab is the default (unknown `?tab=` ids fall back to it).
  List<(String, String)> get tabs => switch (this) {
    about => const [('profile', 'Profile'), ('education', 'Education')],
    experience => const [
      ('work', 'Work'),
      ('organizations', 'Organizations'),
      ('volunteering', 'Volunteering'),
    ],
    achievements => const [
      ('podium', 'Podium'),
      ('qualifications', 'Qualifications'),
    ],
    _ => const [],
  };

  /// Normalises [tab] to one of [tabs] (first tab when unknown / null);
  /// null when this section has no tabs.
  String? resolveTab(String? tab) {
    final t = tabs;
    if (t.isEmpty) return null;
    return t.any((e) => e.$1 == tab) ? tab : t.first.$1;
  }

  /// Route name / URL location for this section (+ optional tab query).
  String location([String? tab]) {
    final t = resolveTab(tab);
    return t == null || (tab == null) ? path : '$path?tab=$t';
  }

  /// Links shown in the desktop navbar (Contact is the CTA pill).
  static const navLinks = [about, experience, achievements, projects, skills];

  /// Cards shown in the menu panel.
  static const menuCards = [
    about,
    experience,
    achievements,
    projects,
    skills,
    contact,
  ];

  static SiteSection fromPath(String? path) {
    var p = (path == null || path.isEmpty) ? '/' : path.split('?').first;
    if (p.length > 1 && p.endsWith('/')) p = p.substring(0, p.length - 1);
    return values.firstWhere((s) => s.path == p, orElse: () => home);
  }

  /// The `tab` query parameter of a route name / location, if any.
  static String? tabFromLocation(String? location) {
    if (location == null || !location.contains('?')) return null;
    return Uri.tryParse(location)?.queryParameters['tab'];
  }
}
