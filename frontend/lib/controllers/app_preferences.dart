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

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kHasSeenOnboarding) ?? false;
  }

  static Future<void> setHasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSeenOnboarding, true);
  }
}