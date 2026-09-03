import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import '../models/admin_user.dart';
import '../models/admin_user_detail.dart';
import '../models/admin_validation_candidate.dart';
import '../models/admin_verification_settings.dart';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// AdminUserFormResult
// ============================================================================
// 🔵 ZID: nafs mant9 SignUpResult (auth_controller.dart) - success/
// errorMessage, bch el UI ynajjam ywarri rasala mfahma (mch generic
// dima) - user (ken success) bch el écran yenjam yaktech el état
// mba3ad create/update bla appel API zeyda.
// ============================================================================
class AdminUserFormResult {
  final bool success;
  final AdminUser? user;
  final String? errorMessage;

  const AdminUserFormResult._(this.success, this.user, this.errorMessage);

  factory AdminUserFormResult.success(AdminUser user) => AdminUserFormResult._(true, user, null);
  factory AdminUserFormResult.failure(String message) => AdminUserFormResult._(false, null, message);
}

// ============================================================================
// AdminDeleteResult
// ============================================================================
// 🔵 ZID (kifma tlab: "tjini errerur réessayez") - nafs mant9
// AdminUserFormResult - success/errorMessage (mch bool bark) bch el
// UI ynajjam ywarri l'admin 3lech fchel el delete 7a9i9i.
// ============================================================================
class AdminDeleteResult {
  final bool success;
  final String? errorMessage;

  const AdminDeleteResult._(this.success, this.errorMessage);

  factory AdminDeleteResult.success() => const AdminDeleteResult._(true, null);
  factory AdminDeleteResult.failure(String message) => AdminDeleteResult._(false, message);
}

// ============================================================================
// AdminUsersController
// ============================================================================
// 🔵 ZID: appels 7a9i9iyin lel /api/admin/users (protégée, admin bark) -
// list/search/filter, create, update, delete.
// ============================================================================
class AdminUsersController {
  Future<List<AdminUser>?> fetchUsers({String? search, String? role}) async {
    try {
      final params = <String>[];
      if (search != null && search.trim().isNotEmpty) {
        params.add('search=${Uri.encodeQueryComponent(search.trim())}');
      }
      if (role != null && role != 'all') {
        params.add('role=${Uri.encodeQueryComponent(role)}');
      }
      final query = params.isNotEmpty ? '?${params.join('&')}' : '';

      final response = await ApiService.get('/admin/users$query', token: AuthSession.token);
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> rawUsers = (data['users'] as List<dynamic>?) ?? [];
      return rawUsers.map((u) => AdminUser.fromJson(u as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Future<AdminUserFormResult> createUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String city,
    required String birthday,
    required String role,
  }) async {
    try {
      final response = await ApiService.post('/admin/users', {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'city': city,
        'birthday': birthday,
        'role': role,
      }, token: AuthSession.token);

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 201) {
        return AdminUserFormResult.success(AdminUser.fromJson(data['user'] as Map<String, dynamic>));
      }

      final String backendMessage = (data['message'] as String?) ?? '';
      if (backendMessage.toLowerCase().contains('email already exists')) {
        return AdminUserFormResult.failure('signup_email_exists_error'.tr());
      }
      return AdminUserFormResult.failure('login_generic_error'.tr());
    } catch (_) {
      return AdminUserFormResult.failure('signup_connection_error'.tr());
    }
  }

  Future<AdminUserFormResult> updateUser({
    required String id,
    required String email,
    required String fullName,
    required String phone,
    required String city,
    required String birthday,
    // 🔵 ZID (kifma tlab: "les données mtaa el admin... w mdp") -
    // optionnel - null/fadhi = password ma yetbeddelch.
    String? password,
  }) async {
    try {
      final Map<String, dynamic> body = {
        'email': email,
        'fullName': fullName,
        'phone': phone,
        // 🔴 FIX (kifma tlab: "el modification... nhbha hiya bidha eli
        // todhhor fel données mtaa el user") - city/birthday tawa
        // modifiables (kanou ghir affichés, mch modifiables).
        'city': city,
        'birthday': birthday,
      };
      if (password != null && password.trim().isNotEmpty) {
        body['password'] = password;
      }

      final response = await ApiService.put('/admin/users/$id', body, token: AuthSession.token);

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return AdminUserFormResult.success(AdminUser.fromJson(data['user'] as Map<String, dynamic>));
      }

      final String backendMessage = (data['message'] as String?) ?? '';
      if (backendMessage.toLowerCase().contains('email already exists')) {
        return AdminUserFormResult.failure('signup_email_exists_error'.tr());
      }
      if (response.statusCode == 403) {
        return AdminUserFormResult.failure('principal_admin_protected_error'.tr());
      }
      return AdminUserFormResult.failure('login_generic_error'.tr());
    } catch (_) {
      return AdminUserFormResult.failure('signup_connection_error'.tr());
    }
  }

  // 🔵 ZID: GET /api/admin/users/:id - écran détail (Informations
  // personnelles + statistiques 7asb el role).
  Future<AdminUserDetail?> fetchUserDetail(String id) async {
    try {
      final response = await ApiService.get('/admin/users/$id', token: AuthSession.token);
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return AdminUserDetail.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // 🔵 true/false bark (mafamech 7aja lezمha terja3 lel UI ken najja7 -
  // el écran ghir ye7ذef el card mel liste locale).
  // 🔴 FIX (kifma tlab: "tjini errerur réessayez") - kanet terja3 bool
  // bark (true/false), tetfa9ad el rasala 7a9i9iya elli el backend
  // yerja3ha (mathalan "You can't delete your own account" wla
  // "principal admin protected") - el UI kanet twarri "réessayez"
  // GENERIC dima, mch mfahhma l'admin 3lech fchel el delete 7a9i9i.
  // Tawa: nafs pattern AdminUserFormResult (create/update) - rasala
  // mfahhma.
  Future<AdminDeleteResult> deleteUser(String id) async {
    try {
      final response = await ApiService.delete('/admin/users/$id', token: AuthSession.token);
      if (response.statusCode == 200) {
        return AdminDeleteResult.success();
      }

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final String backendMessage = (data['message'] as String?) ?? '';

      if (backendMessage.toLowerCase().contains("can't delete your own account")) {
        return AdminDeleteResult.failure('delete_self_error'.tr());
      }
      if (backendMessage.toLowerCase().contains('principal admin')) {
        return AdminDeleteResult.failure('principal_admin_protected_error'.tr());
      }
      if (response.statusCode == 404) {
        return AdminDeleteResult.failure('user_not_found_error'.tr());
      }
      return AdminDeleteResult.failure(backendMessage.isNotEmpty ? backendMessage : 'login_generic_error'.tr());
    } catch (_) {
      return AdminDeleteResult.failure('signup_connection_error'.tr());
    }
  }

  // 🔵 ZID (kifma tlab: "wkt el checklist tekmel tjii lel admin
  // proposition") - GET /api/admin/validations - kol el comptes elli
  // checklist tou3hom KAMLA (el backend déjà ye-filtri, chraht fel
  // adminController.js/listValidations).
  Future<List<AdminValidationCandidate>?> fetchValidations() async {
    try {
      final response = await ApiService.get('/admin/validations', token: AuthSession.token);
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> raw = (data['validations'] as List<dynamic>?) ?? [];
      return raw.map((v) => AdminValidationCandidate.fromJson(v as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  // 🔵 ZID: bouton "Valider" (écran Validation) - POST
  // /api/admin/users/:id/verify.
  Future<bool> verifyUser(String id) async {
    try {
      final response = await ApiService.post('/admin/users/$id/verify', {}, token: AuthSession.token);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 🔴 FIX (kifma tlab: "fazet el cin... el USER nafsou") - uploadCin
  // (l'admin yeb3ath 3la isem el user) etna77a - tawa
  // VerificationController.uploadMyCin (el USER nafsou, frontend/lib/
  // controllers/verification_controller.dart).

  // 🔵 ZID (kifma tlab: "khalli les conditions hedhom yodhhrou 3and el
  // admin w ynajem yamlelhom modification") - seuils configurables
  // (services/clients/% avis) - GET/PUT /api/admin/verification-settings.
  Future<AdminVerificationSettings?> fetchVerificationSettings() async {
    try {
      final response = await ApiService.get('/admin/verification-settings', token: AuthSession.token);
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return AdminVerificationSettings.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateVerificationSettings(AdminVerificationSettings settings) async {
    try {
      final response = await ApiService.put('/admin/verification-settings', settings.toJson(), token: AuthSession.token);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}