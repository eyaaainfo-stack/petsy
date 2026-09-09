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
  // 🔵 ZID (feature "filtres search: age/prestations")
  final int? age;
  final int completedBookingsCount;

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
    this.age,
    this.completedBookingsCount = 0,
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
      age: (json['age'] as num?)?.toInt(),
      completedBookingsCount: (json['completedBookingsCount'] as num?)?.toInt() ?? 0,
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
  // 🔵 ZID (feature "filtres search: age/disponibilite/categorie/prestations")
  final int? minAge;
  final bool onlyAvailable;
  final String? acceptedPetCategory; // 'small_dog' / 'guard_dog' / 'cat'
  final int? minCompletedBookings;
  // 🔴 FIX (kifma tlab: "les filtres lkol khallihomli fi boutons filtres
  // tht el recherche" - el user y7eb Date/Heure/Animaux ykounou 3 boutons
  // MFAR9IN fi nefs el sef tel filtres el o5rin, mch ghir chip WA7DA
  // "disponibilité" tefte7 sheet fiha el 3 7ajet mjam3in) - "availabilityAt"
  // (DateTime wa7ed) etna77a, tawa "availabilityDate" (youm bark, heure
  // = 00:00 dima) + "availabilityHour"/"availabilityMinute" (mنفصلين -
  // bch "l'heure ma tetkhtaretch" ma yetle5belch m3a "l'heure 00:00
  // mkhtara 7a9i9atan").
  final DateTime? availabilityDate;
  final int? availabilityHour;
  final int? availabilityMinute;
  final Set<String> availabilityPetIds;
  final List<String> availabilityPetCategories;

  const SitterSearchFilters({
    this.gender,
    this.city,
    this.residenceType,
    this.maxDistanceKm,
    this.minMemberMonths,
    this.minRating,
    this.minAge,
    this.onlyAvailable = false,
    this.acceptedPetCategory,
    this.minCompletedBookings,
    this.availabilityDate,
    this.availabilityHour,
    this.availabilityMinute,
    this.availabilityPetIds = const {},
    this.availabilityPetCategories = const [],
  });

  bool get isEmpty =>
      gender == null &&
      city == null &&
      residenceType == null &&
      maxDistanceKm == null &&
      minMemberMonths == null &&
      minRating == null &&
      minAge == null &&
      !onlyAvailable &&
      acceptedPetCategory == null &&
      minCompletedBookings == null &&
      availabilityDate == null &&
      availabilityHour == null &&
      availabilityPetIds.isEmpty;

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
    int? minAge,
    bool clearMinAge = false,
    bool? onlyAvailable,
    String? acceptedPetCategory,
    bool clearAcceptedPetCategory = false,
    int? minCompletedBookings,
    bool clearMinCompletedBookings = false,
    DateTime? availabilityDate,
    bool clearAvailabilityDate = false,
    int? availabilityHour,
    int? availabilityMinute,
    bool clearAvailabilityTime = false,
    Set<String>? availabilityPetIds,
    List<String>? availabilityPetCategories,
  }) {
    return SitterSearchFilters(
      gender: clearGender ? null : (gender ?? this.gender),
      city: clearCity ? null : (city ?? this.city),
      residenceType: clearResidenceType ? null : (residenceType ?? this.residenceType),
      maxDistanceKm: clearMaxDistanceKm ? null : (maxDistanceKm ?? this.maxDistanceKm),
      minMemberMonths: clearMinMemberMonths ? null : (minMemberMonths ?? this.minMemberMonths),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
      minAge: clearMinAge ? null : (minAge ?? this.minAge),
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      acceptedPetCategory: clearAcceptedPetCategory ? null : (acceptedPetCategory ?? this.acceptedPetCategory),
      minCompletedBookings: clearMinCompletedBookings ? null : (minCompletedBookings ?? this.minCompletedBookings),
      availabilityDate: clearAvailabilityDate ? null : (availabilityDate ?? this.availabilityDate),
      availabilityHour: clearAvailabilityTime ? null : (availabilityHour ?? this.availabilityHour),
      availabilityMinute: clearAvailabilityTime ? null : (availabilityMinute ?? this.availabilityMinute),
      availabilityPetIds: availabilityPetIds ?? this.availabilityPetIds,
      availabilityPetCategories: availabilityPetCategories ?? this.availabilityPetCategories,
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
      if (filters.minAge != null) params['minAge'] = filters.minAge!.toString();
      if (filters.onlyAvailable) params['isAvailable'] = 'true';
      if (filters.acceptedPetCategory != null) params['acceptedPetCategory'] = filters.acceptedPetCategory!;
      if (filters.minCompletedBookings != null) params['minCompletedBookings'] = filters.minCompletedBookings!.toString();
      // 🔵 ZID (kifma tlab): "filtre disponible - date/wa9t/pets" (tawa
      // 3 boutons mfar9in, mch chip wa7da) - njam3ou "availabilityDate"
      // + "availabilityHour/Minute" (ken el heure mkhtara zeda) f DateTime
      // wa7ed l'backend (el categories el kol tel pets el mkhtarin, mch
      // wa7da bark - el backend ye5dem b AND ($all), mch OR).
      if (filters.availabilityDate != null) {
        final d = filters.availabilityDate!;
        final combined = DateTime(d.year, d.month, d.day, filters.availabilityHour ?? 0, filters.availabilityMinute ?? 0);
        params['date'] = combined.toIso8601String();
        // 🔵 ZID (kifma tlab: "el disponibilité tzid horaire zeda") -
        // "hasTime" ye3allem el backend ken el owner 5tar HEURE 7a9i9iya
        // (mch bark date, elli tji b minuit b default lowkan heure ma
        // tkhtaretch) - bla hedha, blocages horaire (recurringHoursOff/
        // specificHoursOff) ynajjmou yeb3thou ghalat 3ala minuit implicite.
        params['hasTime'] = (filters.availabilityHour != null).toString();
      }
      if (filters.availabilityPetCategories.isNotEmpty) params['petCategories'] = filters.availabilityPetCategories.join(',');

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