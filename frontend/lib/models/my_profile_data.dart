// ============================================================================
// SitterServiceEntry / MyProfileData
// ============================================================================
// 🔵 el "shape" el kamel tel profile (esm/blasa/photo/birthday/bio +
// el 7ou9oul el 5assa bel sitter: services+prix, residence, transport,
// pets) - GET /api/users/profile (backend, userController.js
// getProfile) yrajja3 el kol f nefs el appel.
// ============================================================================
class SitterServiceEntry {
  final String serviceId; // 'house_sitting' / 'dog_walking' / ...
  final double price;
  final String petType; // 'cat' / 'dog' / 'both'

  const SitterServiceEntry({
    required this.serviceId,
    required this.price,
    required this.petType,
  });

  factory SitterServiceEntry.fromJson(Map<String, dynamic> json) {
    return SitterServiceEntry(
      serviceId: json['serviceId'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      petType: json['petType'] as String? ?? '',
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
  });

  factory MyProfileData.fromJson(Map<String, dynamic> json) {
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
    );
  }
}