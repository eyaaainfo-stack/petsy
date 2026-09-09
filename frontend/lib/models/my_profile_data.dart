// ============================================================================
// SitterServiceEntry / MyProfileData
// ============================================================================
// 🔵 el "shape" el kamel tel profile (esm/blasa/photo/birthday/bio +
// el 7ou9oul el 5assa bel sitter: services+prix, residence, transport,
// pets) - GET /api/users/profile (backend, userController.js
// getProfile) yrajja3 el kol f nefs el appel.
// ============================================================================
// 🔵 ZID (feature "compatibilite entre animaux"): {category, price} -
// kol service tawa 3andou barcha prix (wa7ed l'kol category elli el
// sitter ye9bel - small_dog/guard_dog/cat), mch price+petType wa7dania.
class ServiceCategoryPrice {
  final String category;
  final double price;

  const ServiceCategoryPrice({required this.category, required this.price});

  factory ServiceCategoryPrice.fromJson(Map<String, dynamic> json) {
    return ServiceCategoryPrice(
      category: json['category'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
    );
  }
}

class SitterServiceEntry {
  final String serviceId; // 'grooming_full_bath' / 'walking_daily_walk' / 'custom' / ...
  final List<ServiceCategoryPrice> prices;
  // 🔵 ZID (kifma tlab: "ken yhb yzid service ekher") - esm el service
  // "Autre" (custom, serviceId == 'custom') - el sitter kteb b ydik,
  // mafamech labelKey lel translation (mch mel catalogue - chraht fel
  // models/sitter_service_catalog.dart).
  final String? customLabel;

  const SitterServiceEntry({
    required this.serviceId,
    required this.prices,
    this.customLabel,
  });

  factory SitterServiceEntry.fromJson(Map<String, dynamic> json) {
    return SitterServiceEntry(
      serviceId: json['serviceId'] as String? ?? '',
      prices: (json['prices'] as List<dynamic>? ?? [])
          .map((e) => ServiceCategoryPrice.fromJson(e as Map<String, dynamic>))
          .toList(),
      customLabel: json['customLabel'] as String?,
    );
  }
}

class MyProfileData {
  final String fullName;
  final String city;
  final String phone;
  final String birthday;
  final String bio;
  final String? photoUrl;
  final String role;
  // 🔵 ZID (my_profile_owner.dart/update_profile_owner.dart)
  final String? gender; // 'male' / 'female' / ''
  final String? locationName;

  // 🔵 el 7ou9oul el 5assa bel sitter bark - null/fadhya lel owner/b39dhin.
  final String? residenceType;
  final bool? hasTransportation;
  final bool? hasPetAtHome;
  final List<String> ownedPetTypes;
  final List<SitterServiceEntry> services;
  // 🔵 ZID (feature "compatibilite entre animaux"): GHIR el categories
  // (small_dog/guard_dog/cat), BLA prix (el prix per-service, mawjoud
  // fel SitterServiceEntry.prices fou9).
  final List<String> acceptedPetCategories;
  // 🔵 ZID (kifma tlab): "el rating ma waletach todhhor" - moyenne
  // 7a9i9iya (getSitterPublicProfile, backend) - null lowkan mafamech
  // 7atta review l'hin (mch 0 fake).
  final double? averageRating;
  final int reviewsCount;
  // 🔵 ZID (kifma tlab): "el owner ma yenajjamch ye5tar youm el sitter
  // mch dispo fih" - request_a_book.dart ye7taj had data bch yebloki
  // el ayemet el mou7addda.
  final List<int> recurringDaysOff; // 1=Mon..7=Sun
  final List<DateTime> specificDatesOff;
  // 🔵 ZID (kifma tlab: "el tick el zarka eli tji fel insta ala el
  // pdp") - bch VerifiedBadge (widget) ye39od dima cohérent (mch
  // besoin appel API zeyd bark bch nna7iw hedha).
  final bool isVerified;

  const MyProfileData({
    required this.fullName,
    required this.city,
    required this.phone,
    required this.birthday,
    required this.bio,
    this.photoUrl,
    required this.role,
    this.gender,
    this.locationName,
    this.residenceType,
    this.hasTransportation,
    this.hasPetAtHome,
    this.ownedPetTypes = const [],
    this.services = const [],
    this.acceptedPetCategories = const [],
    this.averageRating,
    this.reviewsCount = 0,
    this.recurringDaysOff = const [],
    this.specificDatesOff = const [],
    this.isVerified = false,
  });

  factory MyProfileData.fromJson(Map<String, dynamic> json) {
    final List<dynamic> recurring = json['recurringDaysOff'] as List<dynamic>? ?? [];
    final List<dynamic> specific = json['specificDatesOff'] as List<dynamic>? ?? [];
    return MyProfileData(
      fullName: json['fullName'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      birthday: json['birthday'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      role: json['role'] as String? ?? '',
      gender: json['gender'] as String?,
      locationName: json['locationName'] as String?,
      residenceType: json['residenceType'] as String?,
      hasTransportation: json['hasTransportation'] as bool?,
      hasPetAtHome: json['hasPetAtHome'] as bool?,
      ownedPetTypes: (json['ownedPetTypes'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      services: (json['services'] as List<dynamic>? ?? [])
          .map((e) => SitterServiceEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      acceptedPetCategories: (json['acceptedPetCategories'] as List<dynamic>? ?? []).map((e) => e as String).toList(),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      reviewsCount: json['reviewsCount'] as int? ?? 0,
      recurringDaysOff: recurring.map((e) => (e as num).toInt()).toList(),
      specificDatesOff: specific.map((e) => DateTime.parse(e as String)).toList(),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}