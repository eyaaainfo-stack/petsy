import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
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
  // 🔵 ZID (kifma tlab: "el tick... fel home fel pdp mteou") - bch
  // ProfileOwnerScreen/SitterProfileScreen ynajjmou ywarrou el badge
  // direct ba3d login (mch ghir ba3d restart/session-restore).
  final bool isVerified;
  // 🔵 ZID (kifma tlab: "ken el user homme nkhalliwh vert, keno femme
  // pink") - couleur el sidebar 7asb el gender ('male'/'female'/'').
  final String? gender;
  // 🔵 ZID (kifma tlab: "idha el creation du compte mch fini ma
  // yethallich el home") - user_login.dart yestenna 3ala hedha bch
  // ye5tar ykhalliه ykammel el signup (UserCreateProfileScreen), mch
  // home direct.
  final bool isProfileComplete;
  // 🔵 ZID (kifma tlab: "el email ykoun réellement mawjoud - vérification
  // bloquante") - "true" par défaut (bla ha, ay comportement mch metwaqqa3
  // lowkan el backend ma yeb3athch had field - mafhouma "verified"
  // GHIR ken el backend ye9oul EXPLICITEMENT "false").
  final bool isEmailVerified;
  // 🔵 ye7taj-ha VerifyEmailScreen (email el user - déjà 3andna fel
  // formulaire, ama nzidouha houni zeda l'consistency/reuse mel
  // splash_decider.dart, elli ma3andouch el TextEditingController).
  final String? email;

  const LoginResult._(this.success, this.errorType, [this.token, this.fullName, this.city, this.role, this.photoUrl, this.isVerified = false, this.gender, this.isProfileComplete = true, this.isEmailVerified = true, this.email]);

  factory LoginResult.success(
    String token, {
    String? fullName,
    String? city,
    String? role,
    String? photoUrl,
    bool isVerified = false,
    String? gender,
    bool isProfileComplete = true,
    bool isEmailVerified = true,
    String? email,
  }) =>
      LoginResult._(true, LoginErrorType.none, token, fullName, city, role, photoUrl, isVerified, gender, isProfileComplete, isEmailVerified, email);
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
// GoogleAuthErrorType / GoogleAuthResult
// ============================================================================
// 🔵 ZID (kifma tlab: "Continue with Google") - "Continue with Google"
// ye5dem ZOUZ 7alat m3a NEFS el endpoint (backend/googleAuth): LOGIN
// (email mawjoud déjà) WELA SIGNUP (email jdid + role). "noAccountFound"
// tji GHIR ki el bouton mel écran LOGIN w el email mch mawjoud (el écran
// signup dima yeb3ath role, fa el backend ma yrajja3ch had el حالة).
// ============================================================================
enum GoogleAuthErrorType { cancelled, noAccountFound, generic, none }

class GoogleAuthResult {
  final bool success;
  final GoogleAuthErrorType errorType;
  final String? token;
  final String? fullName;
  final String? city;
  final String? role;
  final String? photoUrl;
  final bool isVerified;
  final String? gender;
  final bool isProfileComplete;
  final bool isEmailVerified;
  final String? email;

  const GoogleAuthResult._(this.success, this.errorType, [this.token, this.fullName, this.city, this.role, this.photoUrl, this.isVerified = false, this.gender, this.isProfileComplete = true, this.isEmailVerified = true, this.email]);

  factory GoogleAuthResult.success(
    String token, {
    String? fullName,
    String? city,
    String? role,
    String? photoUrl,
    bool isVerified = false,
    String? gender,
    bool isProfileComplete = true,
    bool isEmailVerified = true,
    String? email,
  }) =>
      GoogleAuthResult._(true, GoogleAuthErrorType.none, token, fullName, city, role, photoUrl, isVerified, gender, isProfileComplete, isEmailVerified, email);
  factory GoogleAuthResult.cancelled() => const GoogleAuthResult._(false, GoogleAuthErrorType.cancelled);
  factory GoogleAuthResult.noAccountFound() => const GoogleAuthResult._(false, GoogleAuthErrorType.noAccountFound);
  factory GoogleAuthResult.genericError() => const GoogleAuthResult._(false, GoogleAuthErrorType.generic);
}

// ============================================================================
// AuthController
// ============================================================================
// 🔴 TAWA REAL - appels http.post() 7a9i9iyin lel backend (mch mock).
// Lezem el backend ykoun 5addem (node server.js) w el baseUrl fel
// ApiService sa7i7 bch te5dem.
// ============================================================================
class AuthController {
  // 🔵 ZID (kifma tlab: "Continue with Google") - "serverClientId" LEZEM
  // ykoun el "Web application" Client ID (mch el Android/iOS wa7ed) -
  // houwa eli ykhalli Google yrajja3lna "idToken" ynajjam el BACKEND
  // yverifih (audience match). 7ottou fel Google Cloud Console
  // (APIs & Services > Credentials > Create Credentials > OAuth client
  // ID > Web application), w badlou houni.
  // 🔵 ZID (kifma tlab: "Continue with Google") - "serverClientId"
  // LEZEM ykoun el "Web application" Client ID, ama GHIR l'Android/iOS
  // - "google_sign_in_web" (Chrome) YERFED had paramètre khales (assertion
  // "serverClientId is not supported on Web") - houni el Client ID
  // ya5dhou mel meta tag "google-signin-client_id" fel web/index.html.
  final GoogleSignIn _googleSignIn = kIsWeb
      ? GoogleSignIn()
      : GoogleSignIn(
          serverClientId: '364744387888-sn2282dlen93ff0b1iketjgrrrdcu56d.apps.googleusercontent.com',
        );

  // 🔵 ZID (kifma tlab: "Continue with Google") - role == null ki el
  // bouton fel écran LOGIN (email lezem ykoun mawjoud déjà), role !=
  // null ki el bouton fel écran SIGNUP (user_signin.dart, deja ye39ed
  // "role" kel paramètre - ken el email jdid, ye39od b'hedha el role).
  Future<GoogleAuthResult> signInWithGoogle({String? role}) async {
    try {
      // "signIn()" el SDK yhandliw wa7dou: ken compte wa7ed mawjoud
      // fel appareil w déjà autorisé l'app, ye5dem quasi-instantané
      // (bla dialogue zeyda) - ken 3ada wala barcha comptes, ywarri
      // "account picker" (kifha kif Instagram/kol app okhra).
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // el user 3andlou el picker w far 9bal ma ye5tar (cancel)
        return GoogleAuthResult.cancelled();
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return GoogleAuthResult.genericError();
      }

      final response = await ApiService.post('/auth/google', {
        'idToken': idToken,
        if (role != null) 'role': role,
      });

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        final String token = data['token'] as String;
        final Map<String, dynamic> user = data['user'] as Map<String, dynamic>;
        AuthSession.save(
          token: token,
          userId: user['id'] as String,
          city: user['city'] as String?,
          role: user['role'] as String?,
          fullName: user['fullName'] as String?,
        );
        return GoogleAuthResult.success(
          token,
          fullName: user['fullName'] as String?,
          city: user['city'] as String?,
          role: user['role'] as String?,
          photoUrl: user['photoUrl'] as String?,
          isVerified: user['isVerified'] as bool? ?? false,
          gender: user['gender'] as String?,
          isProfileComplete: user['isProfileComplete'] as bool? ?? true,
          isEmailVerified: user['isEmailVerified'] as bool? ?? true,
          email: user['email'] as String?,
        );
      } else if (response.statusCode == 404 && data['code'] == 'NO_ACCOUNT') {
        // el bouton mel écran LOGIN w el email Google mafamouch compte
        return GoogleAuthResult.noAccountFound();
      } else {
        return GoogleAuthResult.genericError();
      }
    } catch (e) {
      // 🔵 DEBUG mo2a99at: bech nchoufou el error el 7a9i9i fel terminal
      // (flutter run) - nnaddhouh ba3d ma nel9awh (mch besoin l'el production).
      // ignore: avoid_print
      print('❌ [GOOGLE SIGN-IN] Error 7a9i9i: $e');
      return GoogleAuthResult.genericError();
    }
  }

  Future<LoginResult> login({
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
        // 🔴 FIX (kifma tlab: "el compte mta3 sitter ma ynajemch yet7all
        // ken ma el marra jeya ye5tar account type sitter... mch yhellou
        // men owner par exemple") - "role" kan mجاmou3 kel paramètre
        // ama LA JAMAIS mab3outh fel body - el backend ma kanch ynajjam
        // ychek 3lih. Tawa: yeb3ath, w el backend (login()) yesta3milou
        // fel filter {email, role} (nafs mant9 forgotPassword).
        'role': role,
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
          isVerified: user['isVerified'] as bool? ?? false,
          gender: user['gender'] as String?,
          isProfileComplete: user['isProfileComplete'] as bool? ?? true,
          // 🔵 ZID (kifma tlab): "?? true" (mch "?? false") - comptes
          // 9dam (backend ma yeb3athch had field) grandfathered.
          isEmailVerified: user['isEmailVerified'] as bool? ?? true,
          email: user['email'] as String?,
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