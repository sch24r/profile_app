import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final theme = await ThemeController.load();
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(PortfolioApp(theme: theme));
}

/// SIL Open Font License for the bundled variable fonts.
Stream<LicenseEntry> _fontLicenses() async* {
  final text = await rootBundle.loadString('assets/fonts/OFL.txt');
  yield LicenseEntryWithLineBreaks(const [
    'Unbounded',
    'Plus Jakarta Sans',
    'JetBrains Mono',
  ], text);
}
