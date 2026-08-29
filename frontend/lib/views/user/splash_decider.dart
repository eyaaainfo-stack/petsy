import 'dart:convert';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/auth_session.dart';
import '../../controllers/app_preferences.dart';
import '../../repositories/pet_repository.dart';
import '../../services/api_service.dart';
import '../../services/power_save_service.dart';
import 'language.dart';
import 'account_type.dart';
import 'owner/profile_owner.dart';
import 'sitter/sitter_profile.dart';

// ============================================================================
// SplashDecider
// ============================================================================
// 🔵 ZID: hedha el écran el JDID elli el app tebda bih (bdal
// "LanguageView()" el fixe elli kan fel app.dart) - ye9ra el état
// mahfoudh (SharedPreferences, via AuthSession.load() + AppPreferences)
// w ye9arrar win ymchi 9bal ma el user ychouf ay 7aja:
//
//   1) Session mawjouda w sa7i7a (token mahfoudh, el user 3amel
//      connexion w ma 3amelch logout) -> tمchي DIRECT lel home tou3ou
//      (ProfileOwnerScreen lel role "owner" - el roles l'okhrin
//      mazelhom ma tsawbouch home fel front, ف tarja3 lel AccountTypeView,
//      chrahtha tحت).
//   2) Mafamech session (wala expiré), lakin el user 3adda el
//      onboarding déjà marra 9bal (flag "has_seen_onboarding") ->
//      tمchي direct lel AccountTypeView (mch tارجع twarri
//      language/slides/welcome mel jdid).
//   3) Mafamech session W lawla marra 7a9i9i (flag false) -> tبda mel
//      LanguageView (el onboarding kaملha), kifha kif kanet 9bal.
// ============================================================================
class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  @override
  void initState() {
    super.initState();
    _decide();

    // 🔴 FIX: kanet tetse2al fi KOL launch (fi kol ma el app tefte7)
    // - tawa marra WA7DA bark fi 3omr el app (flag mahfoudha fel
    // AppPreferences). Zeda: el appel yesir GHIR ba3d ma el 1er frame
    // yban, w bark ken el app fel foreground/resumed (bch ma ye-crashich
    // ken el screen tel telefon msakker wa9t el flutter run/launch).
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bool alreadyAsked = await AppPreferences.hasAskedBatteryOptimization();
      if (alreadyAsked) return;

      await AppPreferences.setHasAskedBatteryOptimization();
      PowerSaveService.requestIgnoreBatteryOptimizations();
    });
  }

  Future<void> _decide() async {
    // 1️⃣ n7awlou n3amrou el session mel disque lel mémoire
    await AuthSession.load();
    final bool hasSeenOnboarding = await AppPreferences.hasSeenOnboarding();

    if (!mounted) return;

    // 2️⃣ Session mawjouda (token mahfoudh)?
    if (AuthSession.isLoggedIn) {
      final Widget? homeScreen = await _resolveHomeScreen();
      if (!mounted) return;

      if (homeScreen != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => homeScreen),
        );
        return;
      }

      // 🔴 Token mawjoud lakin ghalet/expiré (401 mel backend), wala
      // el role mazel ma3andouch home fel front (sitter/admin/courier)
      // - nnaddfou el session (bch ma neb9awch ndouro fel mahzour) w
      // namchiw lel AccountTypeView (mch ne7bsou el user "block").
      await AuthSession.clear();
    }

    if (!mounted) return;

    // 3️⃣ Mafamech session sa7i7a - el onboarding déjà mchiya marra?
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => hasSeenOnboarding ? const AccountTypeView() : const LanguageView(),
      ),
    );
  }

  // --------------------------------------------------------------------
  // 🔵 ZID: 3ala 7sab el role el mahfoudh, njibou el data el lezmha mel
  // backend (GET /users/profile - endpoint jdid, w GET /pets lel
  // owner), w narj3ou el écran el sa7i7 el jahez (bel data el
  // 7a9i9iya, mch fadhya/mock).
  //
  // Terja3 "null" lowkan: token ghalet/expiré, wala el role mazelou
  // home fel front (splash ye3raf ken yestannew, mch yfeshel).
  // --------------------------------------------------------------------
  Future<Widget?> _resolveHomeScreen() async {
    try {
      final response = await ApiService.get('/users/profile', token: AuthSession.token);
      if (response.statusCode != 200) return null; // token expiré/invalide

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic> user = data['user'] as Map<String, dynamic>;
      final String role = user['role'] as String? ?? '';

      if (role == 'owner') {
        final pets = await PetRepository.fetchOwnerPets();
        if (!mounted) return null;
        final String? photoUrl = user['photoUrl'] as String?;
        return ProfileOwnerScreen(
          ownerName: user['fullName'] as String? ?? '',
          ownerCity: user['city'] as String? ?? '',
          pets: pets,
          // 🔴 FIX: nafs mochkla el login manuel - kanet na9sa houni zeda.
          ownerPhotoUrl: (photoUrl != null && photoUrl.isNotEmpty)
              ? '${ApiService.mediaBaseUrl}$photoUrl'
              : null,
        );
      }

      if (role == 'sitter') {
        final String? photoUrl = user['photoUrl'] as String?;
        return SitterProfileScreen(
          sitterName: user['fullName'] as String? ?? '',
          sitterCity: user['city'] as String? ?? '',
          sitterPhotoUrl: (photoUrl != null && photoUrl.isNotEmpty)
              ? '${ApiService.mediaBaseUrl}$photoUrl'
              : null,
        );
      }

      // 🔴 TODO: courier/admin home mazel ma tsawbetch fel front (ghir
      // el design fel Figma export, mch el code Flutter) - ki tetsawweb,
      // zid "case" houni (nafs el fikra tel owner/sitter).
      return null;
    } catch (_) {
      // ay 5ata (mfamech internet, server twaqqaf, etc.) - n5alliw el
      // user ydakhal mel jdid (mch ne7bsou el app "loading" l'infini).
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    // écran d'attente sghir (logo + spinner) waqt el décision - bla
    // ha el user ychouf écran abyadh farigh waqt el appels API.
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: sizes.splashLogoWidth,
              child: Image.asset('assets/images/ppetsy.png', fit: BoxFit.contain),
            ),
            SizedBox(height: sizes.splashLogoGap),
            CircularProgressIndicator(color: AppColors.pinkpetsy),
          ],
        ),
      ),
    );
  }
}