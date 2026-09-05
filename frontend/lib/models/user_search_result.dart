import '../services/api_service.dart';

// ============================================================================
// UserSearchResult (kifma tlab: "wkt nlawej ala had f recherche ena
// nebda nekteb w houa yjini des proposition lel asemi eli mawjoudin
// fel app") - messages_list_screen.dart, autocomplete "live" (AY user
// fel app, mch ghir contacts/conversations mawjoudin déjà).
// ============================================================================
class UserSearchResult {
  final String userId;
  final String fullName;
  final String? photoUrl;
  final String? city;
  final String? role;

  const UserSearchResult({
    required this.userId,
    required this.fullName,
    this.photoUrl,
    this.city,
    this.role,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    final String? rawPhotoUrl = json['photoUrl'] as String?;
    return UserSearchResult(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      photoUrl: (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawPhotoUrl' : null,
      city: json['city'] as String?,
      role: json['role'] as String?,
    );
  }
}