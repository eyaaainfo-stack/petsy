import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// LoginErrorType / LoginResult
// ============================================================================
enum LoginErrorType { invalidEmail, invalidPassword, generic, none }

class LoginResult {
  final bool success;
  final LoginErrorType errorType;
  final String? token; // 🔵 ZID: el JWT token elli el backend yrajja3
  // 🔵 ZID: bch nnajjmou n3amlou navigation lel ProfileOwnerScreen
  // (7ata el "esm"/"blasa" tel user connecté, mch bess el token).
  final String? fullName;
  final String? city;
  final String? role;
  // 🔴 FIX: kanet na9sa - photo tel owner (mel backend, mathalan
  // "/uploads/users/xxx.jpg") ma kanetch tetba3ath l'ProfileOwnerScreen
  // ba3d login (kanet tban ghir ba3d signup direct, mel mémoire).
  final String? photoUrl;

  const LoginResult._(this.success, this.errorType, [this.token, this.fullName, this.city, this.role, this.photoUrl]);

  factory LoginResult.success(String token, {String? fullName, String? city, String? role, String? photoUrl}) =>
      LoginResult._(true, LoginErrorType.none, token, fullName, city, role, photoUrl);
  factory LoginResult.emailNotFound() => const LoginResult._(false, LoginErrorType.invalidEmail);
  factory LoginResult.wrongPassword() => const LoginResult._(false, LoginErrorType.invalidPassword);
  factory LoginResult.genericError() => const LoginResult._(false, LoginErrorType.generic);
}

// ============================================================================
// SignUpResult
// ============================================================================
// 🔵 ZID: 9bal, signUp() kanet terja3 "bool" bess - lowkan el signup
// yefchel (email mawjoud déjà, server mch 5addem, etc.), el UI kan
// "yeskot" bla ay rasala (chrahtha: "el bouton ma y7ebch yemchi w ma
// na3rafch 3lech"). Tاوة terja3 SignUpResult, fiha rasala jahza bch
// tban lel user (SnackBar).
// ============================================================================
class SignUpResult {
  final bool success;
  final String? errorMessage;

  const SignUpResult._(this.success, [this.errorMessage]);

  factory SignUpResult.success() => const SignUpResult._(true);
  factory SignUpResult.failure(String message) => SignUpResult._(false, message);
}

// ============================================================================
// AuthController
// ============================================================================
// 🔴 TAWA REAL - appels http.post() 7a9i9iyin lel backend (mch mock).
// Lezem el backend ykoun 5addem (node server.js) w el baseUrl fel
// ApiService sa7i7 bch te5dem.
// ============================================================================
class AuthController {
  Future<LoginResult> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final String token = data['token'] as String;
        final Map<String, dynamic> user = data['user'] as Map<String, dynamic>;
        // 🔵 ZID: n7ottou el token/userId fel AuthSession (mémoire) -
        // bch UserCreateProfileController w profile_owner ynajmou
        // yosloula ba3d.
        // 🔴 FIX: "role" (w "city"/"fullName") kanou MA yeb3thouch l
        // AuthSession.save() - AuthSession.userRole kan DIMA null (7ata
        // ba3d el login), w kol kod ye3tamed 3lih (mathalan
        // notifications_screen.dart, "sitter" vs "owner") ma yekhdemch.
        AuthSession.save(
          token: token,
          userId: user['id'] as String,
          city: user['city'] as String?,
          role: user['role'] as String?,
          fullName: user['fullName'] as String?,
        );
        return LoginResult.success(
          token,
          fullName: user['fullName'] as String?,
          city: user['city'] as String?,
          role: user['role'] as String?,
          photoUrl: user['photoUrl'] as String?,
        );
      } else if (response.statusCode == 404) {
        // el backend yrajja3 404 kif el email mch mawjoud
        return LoginResult.emailNotFound();
      } else if (response.statusCode == 400) {
        // el backend yrajja3 400 kif el password ghalet
        return LoginResult.wrongPassword();
      } else {
        return LoginResult.genericError();
      }
    } catch (_) {
      // el server mch 5addem, mfamech connexion internet, etc.
      return LoginResult.genericError();
    }
  }

  Future<SignUpResult> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await ApiService.post('/auth/register', {
        'email': email,
        'password': password,
        'role': role,
        // 🔵 fullName/phone/city ma nab3thouhomch houni - el backend
        // ye5alliihom optionnels ('') w yet3amrou ba3d fel écran
        // UserCreateProfileScreen (PATCH /api/users/profile).
      });

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final String token = data['token'] as String;
        final Map<String, dynamic> user = data['user'] as Map<String, dynamic>;
        // 🔵 ZID: nafs el mant9 tel login - n7ottou el token direct,
        // bch UserCreateProfileScreen (elli tji ba3d) tنجم te3yet lel
        // route "protégée" (PATCH profile) bla ma te7taj écran login.
        // 🔴 FIX: nafs mochkla el login - "role" lezem yetb3ath l
        // AuthSession.save() (bla ha, AuthSession.userRole yeb9a null
        // 7ata ba3d el signup, w écrans zeyda te7taj tel role).
        AuthSession.save(token: token, userId: user['id'] as String, role: user['role'] as String? ?? role);
        return SignUpResult.success();
      }

      // 🔵 el backend yrajja3 "message" (JSON, mathalan "Email already
      // exists") - n7awlou n9raweh bch nwarriw rasala mfahma, mch
      // generic dima.
      String backendMessage = '';
      try {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        backendMessage = (data['message'] as String?) ?? '';
      } catch (_) {
        // el response mch JSON sa7i7 - nkamlou b message generic
      }

      if (backendMessage.toLowerCase().contains('email already exists')) {
        return SignUpResult.failure('signup_email_exists_error'.tr());
      }
      return SignUpResult.failure('login_generic_error'.tr());
    } catch (_) {
      // 🔵 hedhi TA7T ("catch") tji ki el http request nafsou yefchel
      // (server mch 5addem "node server.js", mafamech connexion,
      // baseUrl ghalet fel api_service.dart...) - message مختلف عمدا
      // (connection error), bch el user ye3raf el moukachla mokhtelfa
      // 3an "email mawjoud" mathalan.
      return SignUpResult.failure('signup_connection_error'.tr());
    }
  }
}