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
          // 🔵 ZID (feature "compatibilite entre animaux")
          category: p['category'] as String?,
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

  // 🔵 ZID (kifma tlab: "supprimer le compte mtaa pets") - security_
  // settings_screen.dart, "Supprimer un animal". Yerja3 true ken el
  // delete njeh, false ken fama erreur (mathalan pet 3andou booking
  // active - conflit 409, message.errorMessage yban lel user).
  static Future<PetDeleteResult> deletePet(String petId) async {
    try {
      final response = await ApiService.delete('/pets/$petId', token: AuthSession.token);
      if (response.statusCode == 200) {
        return const PetDeleteResult(success: true);
      }
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return PetDeleteResult(success: false, errorMessage: data['message'] as String?);
    } catch (_) {
      return const PetDeleteResult(success: false);
    }
  }
}

// 🔵 ZID: résultat tel deletePet (success + errorMessage optionnel, bch
// el UI ynajjam ywarri el sabab el 7a9i9i - mathalan "active booking").
class PetDeleteResult {
  final bool success;
  final String? errorMessage;
  const PetDeleteResult({required this.success, this.errorMessage});
}