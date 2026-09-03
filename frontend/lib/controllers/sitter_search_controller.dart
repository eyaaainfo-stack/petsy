import 'dart:convert';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// SitterSearchResult
// ============================================================================
class SitterSearchResult {
  final String id;
  final String fullName;
  final String city;
  final String? photoUrl;
  final String? gender;
  final String? residenceType;
  final DateTime? memberSince;
  final double? distanceKm;
  final bool isFavorite;
  final bool isVerified;
  // 🔴 FIX (kifma tlab: "les note mch deja dispo?") - kanet mafamech
  // (filtre "Note" désactivé b'ghalta) - el data el 7a9i9iya déjà
  // mawjouda mel backend (CheckoutQuestionnaire) - houni ghir n-parsiha.
  final double rating;
  final int reviewsCount;

  const SitterSearchResult({
    required this.id,
    required this.fullName,
    required this.city,
    this.photoUrl,
    this.gender,
    this.residenceType,
    this.memberSince,
    this.distanceKm,
    this.isFavorite = false,
    this.isVerified = false,
    this.rating = 0,
    this.reviewsCount = 0,
  });

  factory SitterSearchResult.fromJson(Map<String, dynamic> json) {
    final String? rawPhotoUrl = json['photoUrl'] as String?;
    final String? rawMemberSince = json['memberSince'] as String?;
    return SitterSearchResult(
      id: json['_id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      city: json['city'] as String? ?? '',
      photoUrl: (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawPhotoUrl' : null,
      gender: json['gender'] as String?,
      residenceType: json['residenceType'] as String?,
      memberSince: rawMemberSince != null ? DateTime.tryParse(rawMemberSince) : null,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      isFavorite: json['isFavorite'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: json['reviewsCount'] as int? ?? 0,
    );
  }
}

// ============================================================================
// SitterSearchFilters
// ============================================================================
// 🔵 kol 7a9el "null" = "Any" (bla filtre). "minMemberMonths": 3/6/12
// (chhour) - "kadeh 3ndou fel app" (mel date el inscription).
// ============================================================================
class SitterSearchFilters {
  final String? gender; // 'male' / 'female'
  final String? city;
  final String? residenceType; // 'apartment' / 'house' / 'countryHouse'
  final double? maxDistanceKm;
  final int? minMemberMonths;
  // 🔴 FIX (kifma tlab: "les note mch deja dispo?") - filtre "Note"
  // 7a9i9i tawa (kan désactivé b'ghalta).
  final double? minRating;

  const SitterSearchFilters({
    this.gender,
    this.city,
    this.residenceType,
    this.maxDistanceKm,
    this.minMemberMonths,
    this.minRating,
  });

  bool get isEmpty => gender == null && city == null && residenceType == null && maxDistanceKm == null && minMemberMonths == null && minRating == null;

  SitterSearchFilters copyWith({
    String? gender,
    bool clearGender = false,
    String? city,
    bool clearCity = false,
    String? residenceType,
    bool clearResidenceType = false,
    double? maxDistanceKm,
    bool clearMaxDistanceKm = false,
    int? minMemberMonths,
    bool clearMinMemberMonths = false,
    double? minRating,
    bool clearMinRating = false,
  }) {
    return SitterSearchFilters(
      gender: clearGender ? null : (gender ?? this.gender),
      city: clearCity ? null : (city ?? this.city),
      residenceType: clearResidenceType ? null : (residenceType ?? this.residenceType),
      maxDistanceKm: clearMaxDistanceKm ? null : (maxDistanceKm ?? this.maxDistanceKm),
      minMemberMonths: clearMinMemberMonths ? null : (minMemberMonths ?? this.minMemberMonths),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
    );
  }
}

class SitterSearchController {
  Future<List<SitterSearchResult>> search({String? query, SitterSearchFilters filters = const SitterSearchFilters()}) async {
    try {
      final Map<String, String> params = {};
      if (query != null && query.trim().isNotEmpty) params['q'] = query.trim();
      if (filters.gender != null) params['gender'] = filters.gender!;
      if (filters.city != null) params['city'] = filters.city!;
      if (filters.residenceType != null) params['residenceType'] = filters.residenceType!;
      if (filters.maxDistanceKm != null) params['maxDistanceKm'] = filters.maxDistanceKm!.toString();
      if (filters.minMemberMonths != null) params['minMemberMonths'] = filters.minMemberMonths!.toString();
      if (filters.minRating != null) params['minRating'] = filters.minRating!.toString();

      final String queryString = params.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&');
      final String path = '/users/sitters/search${queryString.isNotEmpty ? '?$queryString' : ''}';

      final response = await ApiService.get(path, token: AuthSession.token);
      if (response.statusCode != 200) return [];

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = data['sitters'] as List<dynamic>;
      return list.map((e) => SitterSearchResult.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}