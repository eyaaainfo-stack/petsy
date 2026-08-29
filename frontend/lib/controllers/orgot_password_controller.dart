import 'dart:convert';
import '../services/api_service.dart';

// ============================================================================
// ForgotPasswordResult
// ============================================================================
// 🔵 result class 3ama (mch enum kifha kif LoginResult) - el 3 khtawet
// (email/code/password) 3andhom erreurs mo5talfa, fa n7ottou el message
// el 7a9i9i mel backend direct (déjà bel 7arf mfahoum, mathalan
// "No account found with this email for this account type").
// ============================================================================
class ForgotPasswordResult {
  final bool success;
  final String? errorMessage;
  final String? resetToken; // 🔵 mel écran 2 (verifyCode) bark

  const ForgotPasswordResult._(this.success, this.errorMessage, [this.resetToken]);

  factory ForgotPasswordResult.success({String? resetToken}) => ForgotPasswordResult._(true, null, resetToken);
  factory ForgotPasswordResult.failure(String message) => ForgotPasswordResult._(false, message);
}

// ============================================================================
// ForgotPasswordController
// ============================================================================
// 3 khtawet (mdp_oublier_1/2/3.dart):
//   1. requestReset: email + role -> el backend yeb3ath code (5 ra9mat)
//   2. verifyCode: email + code -> yrajja3 "resetToken" mo2a99at
//   3. resetPassword: email + resetToken + password jdid
// ============================================================================
class ForgotPasswordController {
  Future<ForgotPasswordResult> requestReset({required String email, required String role}) async {
    try {
      final response = await ApiService.post('/auth/forgot-password', {'email': email, 'role': role});
      if (response.statusCode == 200) return ForgotPasswordResult.success();

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return ForgotPasswordResult.failure(data['message'] as String? ?? 'login_generic_error');
    } catch (_) {
      return ForgotPasswordResult.failure('login_generic_error');
    }
  }

  Future<ForgotPasswordResult> verifyCode({required String email, required String code}) async {
    try {
      final response = await ApiService.post('/auth/verify-reset-code', {'email': email, 'code': code});
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200) {
        return ForgotPasswordResult.success(resetToken: data['resetToken'] as String?);
      }
      return ForgotPasswordResult.failure(data['message'] as String? ?? 'login_generic_error');
    } catch (_) {
      return ForgotPasswordResult.failure('login_generic_error');
    }
  }

  Future<ForgotPasswordResult> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final response = await ApiService.post('/auth/reset-password', {
        'email': email,
        'resetToken': resetToken,
        'newPassword': newPassword,
      });
      if (response.statusCode == 200) return ForgotPasswordResult.success();

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return ForgotPasswordResult.failure(data['message'] as String? ?? 'login_generic_error');
    } catch (_) {
      return ForgotPasswordResult.failure('login_generic_error');
    }
  }
}