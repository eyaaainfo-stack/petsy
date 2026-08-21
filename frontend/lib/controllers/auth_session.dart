import 'package:shared_preferences/shared_preferences.dart';

// ============================================================================
// AuthSession
// ============================================================================
// 🔵 "singleton" bassit (static) yeh'fedh el token JWT + el ID/city/role
// tel user el connecté fel mémoire (bch kol controller ynajjam yosla
// AuthSession.token direct, bla ma yestenna Future).
//
// ✅ TAWA PERSISTANT: save()/clear() yekteb/yamsa7 zeda fel disque
// (SharedPreferences, mch bess fel mémoire kifha kif kanet 9bal) - w
// load() yerja3 el data mel disque lel mémoire ki el app tebda mel jdid
// (chrahtha fel splash_decider.dart). Hedhi elli t7ell el mochkla:
// "el app tensa el user login ki tsakkar el app w terja3 te7el".
// ============================================================================
class AuthSession {
  AuthSession._();

  static String? token;
  static String? userId;
  static String? userCity;
  static String? userRole;
  static String? userFullName;

  static const String _kToken = 'auth_token';
  static const String _kUserId = 'auth_user_id';
  static const String _kCity = 'auth_user_city';
  static const String _kRole = 'auth_user_role';
  static const String _kFullName = 'auth_user_full_name';

  // --------------------------------------------------------------------
  // save(): t7ott el data fel mémoire (instant, kifha kif 9bal) W
  // tektebha fel disque (async - lezemha "await" mel controller).
  // --------------------------------------------------------------------
  static Future<void> save({
    required String token,
    required String userId,
    String? city,
    String? role,
    String? fullName,
  }) async {
    AuthSession.token = token;
    AuthSession.userId = userId;
    AuthSession.userCity = city;
    AuthSession.userRole = role;
    AuthSession.userFullName = fullName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUserId, userId);
    await prefs.setString(_kCity, city ?? '');
    await prefs.setString(_kRole, role ?? '');
    await prefs.setString(_kFullName, fullName ?? '');
  }

  // --------------------------------------------------------------------
  // load(): t9ra el session mel disque (lowkan mawjouda) w t3amerha
  // fel mémoire - LEZEM tetsajel (await AuthSession.load()) 9bal ma
  // ay écran ye5dhem b AuthSession.isLoggedIn / .token (mathalan fel
  // bidaya tel app, fel SplashDecider).
  // --------------------------------------------------------------------
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString(_kToken);
    userId = prefs.getString(_kUserId);
    userCity = _emptyToNull(prefs.getString(_kCity));
    userRole = _emptyToNull(prefs.getString(_kRole));
    userFullName = _emptyToNull(prefs.getString(_kFullName));
  }

  static String? _emptyToNull(String? value) => (value == null || value.isEmpty) ? null : value;

  // --------------------------------------------------------------------
  // clear(): logout - yamsa7 el session mel mémoire W mel disque.
  // (Mazel ma3andhach écran/bouton "Log out" fel UI - kif tzidha,
  // te3yet lel AuthSession.clear() w temchi lel AccountTypeView.)
  // --------------------------------------------------------------------
  static Future<void> clear() async {
    token = null;
    userId = null;
    userCity = null;
    userRole = null;
    userFullName = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserId);
    await prefs.remove(_kCity);
    await prefs.remove(_kRole);
    await prefs.remove(_kFullName);
  }

  static bool get isLoggedIn => token != null;
}