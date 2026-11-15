import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../shell/site_shell.dart';

/// Stub — replaced by the real page in the sections/pages step.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SiteShell(
      section: SiteSection.contact,
      children: [SizedBox(height: 400)],
    );
  }
}
