import 'dart:convert';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// FavoritesController
// ============================================================================
class FavoriteSitter {
  final String id;
  final String name;
  final String? photoUrl;
  final double? distanceKm;
  final double? startingPrice;
  // 🔵 ZID (kifma tlab: "el tick bhdha pdp hta el users lokhrin yrawha").
  final bool isVerified;

  const FavoriteSitter({
    required this.id,
    required this.name,
    this.photoUrl,
    this.distanceKm,
    this.startingPrice,
    this.isVerified = false,
  });

  factory FavoriteSitter.fromJson(Map<String, dynamic> json) {
    final String? rawPhotoUrl = json['photoUrl'] as String?;
    return FavoriteSitter(
      id: json['_id'] as String? ?? '',
      name: json['fullName'] as String? ?? '',
      photoUrl: (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawPhotoUrl' : null,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      startingPrice: (json['startingPrice'] as num?)?.toDouble(),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

class FavoritesController {
  // 🔵 terja3 el état el JDID (true = tawa favori) - el card (profile_
  // owner.dart) testa3milha bch tbeddel el heart icon direct.
  Future<bool?> toggleFavorite(String sitterId) async {
    try {
      final response = await ApiService.patch('/users/favorites/$sitterId/toggle', {}, token: AuthSession.token);
      if (response.statusCode != 200) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['isFavorite'] as bool?;
    } catch (_) {
      return null;
    }
  }

  Future<List<FavoriteSitter>> fetchMyFavorites() async {
    try {
      final response = await ApiService.get('/users/favorites', token: AuthSession.token);
      if (response.statusCode != 200) return [];
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = data['favorites'] as List<dynamic>;
      return list.map((e) => FavoriteSitter.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
