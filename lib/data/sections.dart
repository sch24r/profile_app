/// Top-level routes / sections of the site.
enum SiteSection {
  home('/', 'Home', 'Start'),
  about('/about', 'About', 'Profile · Education'),
  experience('/experience', 'Experience', 'Work · Communities · Volunteering'),
  achievements('/achievements', 'Achievements', 'CTF results'),
  projects('/projects', 'Projects', 'Things I\'ve built'),
  skills('/skills', 'Skills', 'Toolkit · Languages'),
  contact('/contact', 'Contact', 'Get in touch');

  const SiteSection(this.path, this.label, this.subtitle);
  final String path;
  final String label;
  final String subtitle;

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
    final p = (path == null || path.isEmpty) ? '/' : path.split('?').first;
    return values.firstWhere((s) => s.path == p, orElse: () => home);
  }
}
