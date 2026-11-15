import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light / Dark / System theme choice, persisted with shared_preferences.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController([super.value = ThemeMode.system]);

  static const _key = 'theme_mode';

  static Future<ThemeController> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final i = prefs.getInt(_key);
      if (i != null && i >= 0 && i < ThemeMode.values.length) {
        return ThemeController(ThemeMode.values[i]);
      }
    } catch (_) {
      // Storage unavailable (tests, private mode) — fall back to system.
    }
    return ThemeController();
  }

  Future<void> set(ThemeMode mode) async {
    if (mode == value) return;
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, mode.index);
    } catch (_) {}
  }
}

/// Provides the [ThemeController] to the tree. `ThemeScope.of(context)`.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemeScope>()!.notifier!;
}
