// ============================================================================
// AnimalModel (Pet)
// ============================================================================
// Kifma fel diagramme: Animal <>-- Proprietaire. Kol AnimalModel yeb3ath
// "ownerId" bch ye3raf chkoun Proprietaire tou3ou.
// ============================================================================
class AnimalModel {
  final String? id; // null lowkan mazel ma tzad lel backend
  final String ownerId;
  final String petType; // 'dog' wala 'cat'
  final String name;
  final int? age;
  final String breed;
  final String size;
  final String? gender; // 'female' wala 'male'
  final List<String> behaviors;
  final Map<String, bool?> careInfo; // microchipped/vaccinated/neutered/medication
  final String vetClinicName;
  final String vetClinicPhone;

  AnimalModel({
    this.id,
    required this.ownerId,
    required this.petType,
    required this.name,
    this.age,
    this.breed = '',
    this.size = '',
    this.gender,
    this.behaviors = const [],
    this.careInfo = const {},
    this.vetClinicName = '',
    this.vetClinicPhone = '',
  });

  factory AnimalModel.fromJson(Map<String, dynamic> json) {
    return AnimalModel(
      id: json['_id'] as String?,
      ownerId: json['owner'] as String,
      petType: json['petType'] as String,
      name: json['name'] as String,
      age: json['age'] as int?,
      breed: json['breed'] as String? ?? '',
      size: json['size'] as String? ?? '',
      gender: json['gender'] as String?,
      behaviors: (json['behaviors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      careInfo: (json['careInfo'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value as bool?),
          ) ??
          {},
      vetClinicName: json['vetClinicName'] as String? ?? '',
      vetClinicPhone: json['vetClinicPhone'] as String? ?? '',
    );
  }

  // toJson: bch nab3thou el data lel backend (POST/PUT)
  Map<String, dynamic> toJson() {
    return {
      'owner': ownerId,
      'petType': petType,
      'name': name,
      'age': age,
      'breed': breed,
      'size': size,
      'gender': gender,
      'behaviors': behaviors,
      'careInfo': careInfo,
      'vetClinicName': vetClinicName,
      'vetClinicPhone': vetClinicPhone,
    };
  }
}