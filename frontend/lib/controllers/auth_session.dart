// ============================================================================
// AuthSession
// ============================================================================
// 🔵 "singleton" bassit (static) yeh'fedh el token JWT + el ID/city
// tel user el connecté fel mémoire (tul el session tel app). Kol
// controller (UserCreateProfileController, etc.) ynajjam yosla
// AuthSession.token ki yeb3ath requests "protégées".
//
// ⚠️ LIMITE: yenmسa7 kif el app terja3 tet7el (mch persistant). Bch
// yeb9a mahfoudh 7ata ba3d ma el user ysakkar el app, lezmek
// "shared_preferences" wala "flutter_secure_storage" (package jdid) -
// TODO lel mostakbal, mch lezem tawa.
// ============================================================================
class AuthSession {
  AuthSession._();

  static String? token;
  static String? userId;
  static String? userCity;

  static void save({required String token, required String userId, String? city}) {
    AuthSession.token = token;
    AuthSession.userId = userId;
    AuthSession.userCity = city;
  }

  static void clear() {
    token = null;
    userId = null;
    userCity = null;
  }

  static bool get isLoggedIn => token != null;
}