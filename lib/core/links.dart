import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/cv.dart';

abstract final class Links {
  static Future<void> open(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  static Future<void> email() =>
      open(Uri(scheme: 'mailto', path: Cv.contact.email));
  static Future<void> phone() =>
      open(Uri(scheme: 'tel', path: Cv.contact.phone));
  static Future<void> linkedin() => open(Uri.parse(Cv.contact.linkedinUrl));

  static Future<void> copy(
    BuildContext context,
    String text,
    String message,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
  }
}
