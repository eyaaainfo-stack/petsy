import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// UpdatePetProfileController
// ============================================================================
// PATCH /api/pets/:petId - partiel (ghir el 7ou9oul elli el user
// beddel fi update_pet_profile.dart).
// ============================================================================
class UpdatePetProfileController {
  Future<bool> updatePet({
    required String petId,
    required String name,
    required String age,
    required String breed,
    required String size,
    required String gender,
    required List<String> behaviors,
    required Map<String, bool> careInfo,
    required String vetClinicName,
    required String vetClinicPhone,
    // 🔵 ZID (feature "compatibilite entre animaux"): 'small_dog' /
    // 'guard_dog' - null ken el pet 'cat' (category ma tetbeddelch,
    // el backend yfaraq 3ala 7sab petType tou3ha).
    String? category,
  }) async {
    try {
      final response = await ApiService.patch(
        '/pets/$petId',
        {
          'name': name,
          'age': age,
          'breed': breed,
          'size': size,
          'gender': gender,
          'behaviors': behaviors,
          'careInfo': careInfo,
          'vetClinicName': vetClinicName,
          'vetClinicPhone': vetClinicPhone,
          if (category != null) 'category': category,
        },
        token: AuthSession.token,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}