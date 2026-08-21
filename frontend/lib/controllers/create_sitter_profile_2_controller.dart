import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// CreateSitterProfile2Controller
// ============================================================================
// 🔵 ZID: nafs mant9 CreateSitterProfileController - PATCH partiel
// (residenceType/hasTransportation/hasPetAtHome/ownedPetTypes BARK houni,
// mch "services" elli tzad déjà fel écran el 9bali).
// ============================================================================
class CreateSitterProfile2Controller {
  Future<bool> submitHomeAndTransport({
    required String residenceType, // 'apartment' / 'house' / 'countryHouse'
    required bool hasTransportation,
    required bool hasPetAtHome,
    required List<String> ownedPetTypes, // 'dog' / 'cat'
  }) async {
    try {
      final response = await ApiService.patch(
        '/users/sitter-details',
        {
          'residenceType': residenceType,
          'hasTransportation': hasTransportation,
          'hasPetAtHome': hasPetAtHome,
          'ownedPetTypes': ownedPetTypes,
        },
        token: AuthSession.token,
      );

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}