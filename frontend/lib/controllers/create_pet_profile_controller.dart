import 'package:easy_localization/easy_localization.dart';

// ============================================================================
// PetProfileValidators
// ============================================================================
class PetProfileValidators {
  PetProfileValidators._();

  // --------------------------------------------------------------------
  // 🔵 el max mte3 el 3omor w el wazn (kg), mokhtelfin bin dog w cat -
  // ar9am wassi3in (mch précision biologique, ghrad houm ye7bsou ghalta
  // fel edkhal - typo zeda 200 3am mathalan).
  // --------------------------------------------------------------------
  static const int dogMaxAge = 25;
  static const int catMaxAge = 30;

  static const int dogMaxWeight = 90; // kg
  static const int catMaxWeight = 15; // kg

  static String? petName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'pet_name_required_error'.tr();
    }
    return null;
  }

  // --------------------------------------------------------------------
  // Age: optionnel (lowkan fadhi, ok), lakin lowkan mimla, lezem:
  //   - ra9m 7a9i9i
  //   - > 0
  //   - <= max el noue3 (dog/cat)
  // --------------------------------------------------------------------
  static String? petAge(String? value, String petType) {
    if (value == null || value.trim().isEmpty) {
      return null; // optionnel
    }
    final int? age = int.tryParse(value.trim());
    if (age == null || age <= 0) {
      return 'pet_age_invalid_error'.tr();
    }
    final int max = petType == 'cat' ? catMaxAge : dogMaxAge;
    if (age > max) {
      return 'pet_age_max_error'.tr(namedArgs: {'max': max.toString()});
    }
    return null;
  }

  // --------------------------------------------------------------------
  // Size (= wazn bel kg): nafs el mant9 tel age.
  // --------------------------------------------------------------------
  static String? petSize(String? value, String petType) {
    if (value == null || value.trim().isEmpty) {
      return null; // optionnel
    }
    final double? size = double.tryParse(value.trim());
    if (size == null || size <= 0) {
      return 'pet_size_invalid_error'.tr();
    }
    final int max = petType == 'cat' ? catMaxWeight : dogMaxWeight;
    if (size > max) {
      return 'pet_size_max_error'.tr(namedArgs: {'max': max.toString()});
    }
    return null;
  }
}

// ============================================================================
// CreatePetProfileController
// ============================================================================
// 🔴 MOCK (nafs mant9 auth_controller.dart / user_create_profile_controller)
// TODO: appel API 7a9i9i ki ykoun 3andek backend route mounasba.
// ============================================================================
class CreatePetProfileController {
  Future<bool> submitPetProfile({
    required String petType, // 'dog' wala 'cat'
    required String name,
    required String age,
    required String breed,
    required String size,
    required String? gender,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: POST 7a9i9i lel backend
    return true;
  }
}