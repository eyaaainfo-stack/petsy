import 'dart:convert';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// CreateSitterProfileController
// ============================================================================
// 🔵 ZID: kanet na9sa (l'écran create_sitter_profile.dart 3andou ghir
// TODO/debugPrint, mafamech appel API 7a9i9i) - nafs el mant9 tel
// CreatePetProfile2Controller (controllers/create_pet_profile_2_controller.dart):
// classe mnfassla, l'écran (View) ghir yesta3melha, ma yesta3melch
// ApiService direct.
//
// PATCH /api/users/sitter-details - partiel (services BARK houni, mch
// residenceType/... elli fel écran el jay).
// ============================================================================
class CreateSitterProfileController {
  Future<bool> submitServices({
    required List<Map<String, dynamic>> services,
  }) async {
    try {
      final response = await ApiService.patch(
        '/users/sitter-details',
        {'services': services},
        token: AuthSession.token,
      );

      return response.statusCode == 200;
    } catch (_) {
      // el server mch 5addem, mfamech connexion internet, etc.
      return false;
    }
  }
}