import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../sections/contact_panel.dart';
import '../shell/sub_page_shell.dart';

/// /contact — one screen; the ContactPanel fills the remaining height.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageShell(
      section: SiteSection.contact,
      eyebrow: 'CONTACT',
      titleLines: const ['GET IN', 'TOUCH'],
      bodyBuilder: (context, tab) =>
          const ContactPanel(key: ValueKey('page:contact'), fill: true),
    );
  }
}
