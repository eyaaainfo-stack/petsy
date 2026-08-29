import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// AppPreferences
// ============================================================================
// 🔵 ZID: flag sghira mahfoudha fel disque - "has_seen_onboarding" - bch
// el app te3raf lowkan el user 3adda el onboarding (Language + 4 slides
// + Welcome) marra 9bal. Hedhi elli tmanna3 el app "terja3 mel loul"
// (Language screen) kol ma el user yeftha, ken mch awl marra.
//
// n7ottouha "true" fel welcome.dart, ki el user yodhghot "Get Started"
// (yeb9a mfassel 3an el login/session - user ynajjam ye3adi el
// onboarding w ma ye3malch login, w el app te3raf ma tarja3louch
// twarrih el slides mel jdid).
// ============================================================================
class AppPreferences {
  AppPreferences._();

  static const String _kHasSeenOnboarding = 'has_seen_onboarding';
  // 🔴 FIX: kanet tetse2al fi KOL launch (splash_decider.dart initState)
  // - el user y7es beliha "tzid tji fi kol marra" (khousousan ken
  // dousit "Deny" marra, el dialog terja3 tban el launch elli jai).
  // Tawa: marra WA7DA bark fi 3omr el app (flag mahfoudha), 7atta ken
  // el user 7ram/denya - ma3andnach niya n-forsiwh, ghir na3lmouh marra.
  static const String _kHasAskedBatteryOptimization = 'has_asked_battery_optimization';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasSeenOnboarding) ?? false;
  }

  static Future<void> setHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSeenOnboarding, true);
  }

  static Future<bool> hasAskedBatteryOptimization() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasAskedBatteryOptimization) ?? false;
  }

  static Future<void> setHasAskedBatteryOptimization() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasAskedBatteryOptimization, true);
  }

  // ==========================================================================
  // Theme preference (theme.dart - Settings) - 'system' (par défaut,
  // yetba3 el brightness tel appareil) / 'light' / 'dark' (el user
  // ye5tar b yedou, override).
  // ==========================================================================
  static const String _kThemePreference = 'theme_preference';

  static Future<String> getThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kThemePreference) ?? 'system';
  }

  static Future<void> setThemePreference(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemePreference, value);
  }
}