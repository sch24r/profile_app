import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../sections/achievements_chapter.dart';
import '../sections/contact_panel.dart';
import '../sections/education_section.dart';
import '../sections/experience_section.dart';
import '../sections/hero_story_stage.dart';
import '../sections/organizations_section.dart';
import '../sections/projects_chapter.dart';
import '../sections/skills_section.dart';
import '../sections/volunteers_section.dart';
import '../shell/site_shell.dart';
import '../widgets/motion/story_progress.dart';

/// Home: the only vertically scrolling page. Order and "recent" counts follow
/// the plan's Home table; SiteShell appends the Footer.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StoryProgress _progress = StoryProgress();

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SiteShell(
      section: SiteSection.home,
      storyProgress: _progress,
      children: const [
        HeroStoryStage(key: ValueKey('home:about')),
        EducationPreview(key: ValueKey('home:education')),
        WorkPreview(key: ValueKey('home:work')),
        AchievementsChapter(key: ValueKey('home:achievements')),
        ProjectsChapter(key: ValueKey('home:projects')),
        OrganizationsPreview(key: ValueKey('home:organizations')),
        VolunteeringPreview(key: ValueKey('home:volunteering')),
        SkillsTicker(key: ValueKey('home:skills')),
        ContactPanel(key: ValueKey('home:contact')),
      ],
    );
  }
}
