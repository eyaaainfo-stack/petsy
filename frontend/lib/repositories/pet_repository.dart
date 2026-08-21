import 'dart:convert';
import '../controllers/auth_session.dart';
import '../models/pet_summary.dart';
import '../services/api_service.dart';

// ============================================================================
// PetRepository
// ============================================================================
// 🔵 ZID: hedhi el mant9 elli kanet mkarrra (copié-collé) fi
// user_login.dart - tawa blasa WA7DA (bch lowkan lezemna nbeddlou chay,
// nbeddlouh houni bess, mch fi 3achra blayes - user_login.dart W
// splash_decider.dart el jdid kolhom ysta3mlouha).
// ============================================================================
class PetRepository {
  static Future<List<PetSummary>> fetchOwnerPets() async {
    try {
      final response = await ApiService.get('/pets', token: AuthSession.token);
      if (response.statusCode != 200) return [];

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> petsJson = data['pets'] as List<dynamic>;

      return petsJson.map((json) {
        final Map<String, dynamic> p = json as Map<String, dynamic>;
        return PetSummary(
          id: p['_id'] as String?,
          name: p['name'] as String? ?? '',
          petType: p['petType'] as String? ?? 'dog',
          photoUrl: (p['photoUrl'] as String?)?.isNotEmpty == true
              ? '${ApiService.mediaBaseUrl}${p['photoUrl']}'
              : null,
          age: p['age']?.toString(),
          breed: p['breed'] as String?,
          size: p['size']?.toString(),
          gender: p['gender'] as String?,
          behaviors: (p['behaviors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          careInfo: (p['careInfo'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v == true)) ?? {},
          vetClinicName: p['vetClinicName'] as String?,
          vetClinicPhone: p['vetClinicPhone'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }
}