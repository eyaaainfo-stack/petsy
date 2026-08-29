import 'dart:convert';
import '../models/my_profile_data.dart';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// MyProfileController
// ============================================================================
// 🔵 GET /api/users/profile - yesta3milha "My Profile" screen (my_profile_
// sitter.dart) bch yjib el data el kamla (esm/photo/birthday/bio +
// services/residence/transport lel sitter).
// ============================================================================
class MyProfileController {
  Future<MyProfileData?> fetchMyProfile() async {
    try {
      final response = await ApiService.get('/users/profile', token: AuthSession.token);

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return MyProfileData.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // 🔵 ZID: view_profile_sitter.dart - profile 7AD OKHOR (sitter), mch
  // el user el connecté nafsou (nafs "shape" mel MyProfileData, backend
  // route mnfassla: GET /users/:sitterId/public-profile).
  Future<MyProfileData?> fetchSitterPublicProfile(String sitterId) async {
    try {
      final response = await ApiService.get('/users/$sitterId/public-profile', token: AuthSession.token);

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return MyProfileData.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}