import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// AccountActionResult
// ============================================================================
// 🔵 ZID (kifma tlab: "changer le mdp w supprimer le compte kima el
// confidentialite mtaa el fb") - success/errorMessage (mch bool bark) -
// bch el UI ynajjam ywarri l'user 3lech fchel (password ghalet, etc.).
// ============================================================================
class AccountActionResult {
  final bool success;
  final String? errorMessage;

  const AccountActionResult._(this.success, this.errorMessage);

  factory AccountActionResult.success() => const AccountActionResult._(true, null);
  factory AccountActionResult.failure(String message) => AccountActionResult._(false, message);
}

class AccountSecurityController {
  // 🔵 ZID: PATCH /api/users/me/password - password 9dim + jdid.
  Future<AccountActionResult> changePassword({required String currentPassword, required String newPassword}) async {
    try {
      final response = await ApiService.patch('/users/me/password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }, token: AuthSession.token);

      if (response.statusCode == 200) {
        return AccountActionResult.success();
      }

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final String backendMessage = (data['message'] as String?) ?? '';

      if (backendMessage.toLowerCase().contains('incorrect')) {
        return AccountActionResult.failure('current_password_incorrect_error'.tr());
      }
      return AccountActionResult.failure(backendMessage.isNotEmpty ? backendMessage : 'login_generic_error'.tr());
    } catch (_) {
      return AccountActionResult.failure('signup_connection_error'.tr());
    }
  }

  // 🔵 ZID: DELETE /api/users/me - password l'confirmation (action
  // destructive, mch ghir 1 clic).
  Future<AccountActionResult> deleteAccount({required String password}) async {
    try {
      final response = await ApiService.deleteWithBody('/users/me', {'password': password}, token: AuthSession.token);

      if (response.statusCode == 200) {
        return AccountActionResult.success();
      }

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final String backendMessage = (data['message'] as String?) ?? '';

      if (backendMessage.toLowerCase().contains('incorrect')) {
        return AccountActionResult.failure('current_password_incorrect_error'.tr());
      }
      return AccountActionResult.failure(backendMessage.isNotEmpty ? backendMessage : 'login_generic_error'.tr());
    } catch (_) {
      return AccountActionResult.failure('signup_connection_error'.tr());
    }
  }
}