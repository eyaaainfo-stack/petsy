import 'dart:convert';
import 'dart:typed_data';
import '../models/verification_status.dart';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// VerificationController
// ============================================================================
// 🔵 ZID: appel 7a9i9i lel GET /api/users/me/verification - el user
// (owner/sitter/courier) ychouf checklist + progress mte3ou nafsou.
// ============================================================================
class VerificationController {
  Future<VerificationStatus?> fetchMyStatus() async {
    try {
      final response = await ApiService.get('/users/me/verification', token: AuthSession.token);
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return VerificationStatus.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  // 🔵 ZID (kifma tlab: "sawae el cin mteek men kodem w men telii") -
  // POST /api/users/me/cin (recto+verso f'nefs el appel).
  Future<bool> uploadCin({required Uint8List frontBytes, required Uint8List backBytes}) async {
    try {
      final response = await ApiService.uploadTwoPhotos(
        '/users/me/cin',
        firstBytes: frontBytes,
        firstFieldName: 'front',
        secondBytes: backBytes,
        secondFieldName: 'back',
        token: AuthSession.token,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}