import 'dart:convert';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// CreatePetProfile2Controller
// ============================================================================
// 🔴 TAWA REAL - kolla el data tel pet (mel 2 écrans, kanet mfassla)
// tetba3ath fi POST /api/pets WA7DA (route "protégée" - te7taj token).
// Terja3 el "petId" el 7a9i9i (mel MongoDB) - lezmou l'add_pet_photo.dart
// bch ta3raf win tab3ath el photo (POST /api/pets/:petId/photo).
// ============================================================================
class CreatePetProfile2Controller {
  Future<String?> submitPetBehaviorAndCare({
    required String petType,
    required String name,
    String? age,
    String? breed,
    String? size,
    String? gender,
    required Set<String> behaviors,
    required Map<String, bool> careInfo,
    required String clinicName,
    required String clinicPhone,
  }) async {
    try {
      final response = await ApiService.post(
        '/pets',
        {
          'petType': petType,
          'name': name,
          // 🔵 age/size: el backend yestennahom Number, mch String -
          // n7awlouhom houni ("int.tryParse"/"double.tryParse" yرجع
          // null lowkan el text mch ra9m sa7i7 wla fadhi).
          'age': (age != null && age.isNotEmpty) ? int.tryParse(age) : null,
          'breed': breed,
          'size': (size != null && size.isNotEmpty) ? double.tryParse(size) : null,
          'gender': gender,
          'behaviors': behaviors.toList(),
          'careInfo': careInfo,
          'vetClinicName': clinicName,
          'vetClinicPhone': clinicPhone,
        },
        token: AuthSession.token,
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final Map<String, dynamic> pet = data['pet'] as Map<String, dynamic>;
        return pet['_id'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}