import 'package:flutter/material.dart';

import '../data/sections.dart';
import '../shell/sub_page_shell.dart';

/// Stub — replaced by the real page in the sections/pages step.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SubPageShell(
      section: SiteSection.contact,
      eyebrow: 'CONTACT',
      titleLines: const ['CONTACT'],
      tabs: SiteSection.contact.tabs,
      bodyBuilder: (context, tab) => const SizedBox.expand(),
    );
  }
}
