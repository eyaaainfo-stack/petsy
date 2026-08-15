// ============================================================================
// CreatePetProfile2Controller
// ============================================================================
// 🔴 MOCK - TODO: appel API 7a9i9i ki ykoun 3andek backend route mounasba.
// ============================================================================
class CreatePetProfile2Controller {
  Future<bool> submitPetBehaviorAndCare({
    required Set<String> behaviors,
    required Map<String, bool?> careInfo,
    required String clinicName,
    required String clinicPhone,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: POST 7a9i9i lel backend
    return true;
  }
}