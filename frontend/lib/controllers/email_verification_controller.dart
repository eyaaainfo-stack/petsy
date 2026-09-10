import 'dart:convert';
import '../services/api_service.dart';

// ============================================================================
// EmailVerificationResult
// ============================================================================
class EmailVerificationResult {
  final bool success;
  final String? errorMessage;

  const EmailVerificationResult._(this.success, [this.errorMessage]);

  factory EmailVerificationResult.success() => const EmailVerificationResult._(true);
  factory EmailVerificationResult.failure(String message) => EmailVerificationResult._(false, message);
}

// ============================================================================
// EmailVerificationController
// ============================================================================
// 🔵 ZID (kifma tlab: "el email ykoun réellement mawjoud - vérification
// bloquante") - nafs mant9 ForgotPasswordController (verifyCode) - ghir
// houni l'confirmation el email nafsou ba3d el signup, mch reset password.
// ============================================================================
class EmailVerificationController {
  Future<EmailVerificationResult> verifyEmail({required String email, required String code}) async {
    try {
      final response = await ApiService.post('/auth/verify-email', {'email': email, 'code': code});
      if (response.statusCode == 200) return EmailVerificationResult.success();

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return EmailVerificationResult.failure(data['message'] as String? ?? 'login_generic_error');
    } catch (_) {
      return EmailVerificationResult.failure('login_generic_error');
    }
  }

  Future<EmailVerificationResult> resend({required String email}) async {
    try {
      final response = await ApiService.post('/auth/resend-verification-email', {'email': email});
      if (response.statusCode == 200) return EmailVerificationResult.success();

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return EmailVerificationResult.failure(data['message'] as String? ?? 'login_generic_error');
    } catch (_) {
      return EmailVerificationResult.failure('login_generic_error');
    }
  }
}