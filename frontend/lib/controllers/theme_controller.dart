import 'package:flutter/material.dart';
import 'app_preferences.dart';

// ============================================================================
// ThemeController
// ============================================================================
// 🔵 ZID (settings.dart -> theme.dart) - "override" mo3ayan mel user
// (Light/Dark), fou9 el behavior el automatique (system brightness,
// chrahtha fel app.dart). "null" = "System" (yeb9a yetba3 el appareil,
// nafs el behavior el 9dim).
//
// ValueNotifier (mch package zeyed kifha kif Provider/Riverpod) - app.dart
// yesma3 biha (ValueListenableBuilder), w theme.dart ybaddel biha direct
// (live update, bla restart).
// ============================================================================
class ThemeController {
  ThemeController._();

  static final ValueNotifier<ThemeMode?> mode = ValueNotifier<ThemeMode?>(null);

  static Future<void> load() async {
    final String saved = await AppPreferences.getThemePreference();
    mode.value = _fromString(saved);
  }

  static Future<void> setMode(ThemeMode? newMode) async {
    mode.value = newMode;
    await AppPreferences.setThemePreference(_toString(newMode));
  }

  static ThemeMode? _fromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return null; // 'system'
    }
  }

  static String _toString(ThemeMode? mode) {
    if (mode == ThemeMode.light) return 'light';
    if (mode == ThemeMode.dark) return 'dark';
    return 'system';
  }
}