// ============================================================================
// UserModel (abstract) + AdminModel / OwnerModel / SitterModel / CourierModel
// ============================================================================
// Nafs el hierarchie tel diagramme UML w tel backend (Mongoose
// discriminators): kol el roles yerthou mel UserModel, w CourierModel
// yerith mel SitterModel (mch mel UserModel direct) - bالضبط kifha kif
// "Petsy courrier -|> Gardien d'animau" fel diagramme.
// ============================================================================
abstract class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final String role;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
  });
}

// ----------------------------------------------------------------------
// AdminModel
// ----------------------------------------------------------------------
class AdminModel extends UserModel {
  AdminModel({
    required String id,
    required String email,
    required String fullName,
    required String phone,
  }) : super(id: id, email: email, fullName: fullName, phone: phone, role: 'admin');

  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

// ----------------------------------------------------------------------
// OwnerModel (Proprietaire)
// ----------------------------------------------------------------------
class OwnerModel extends UserModel {
  final String address;

  OwnerModel({
    required String id,
    required String email,
    required String fullName,
    required String phone,
    this.address = '',
  }) : super(id: id, email: email, fullName: fullName, phone: phone, role: 'owner');

  factory OwnerModel.fromJson(Map<String, dynamic> json) {
    return OwnerModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
    );
  }
}

// ----------------------------------------------------------------------
// SitterModel (Gardien d'animau)
// ----------------------------------------------------------------------
class SitterModel extends UserModel {
  final String bio;
  final double hourlyRate;
  final bool isAvailable;

  SitterModel({
    required String id,
    required String email,
    required String fullName,
    required String phone,
    this.bio = '',
    this.hourlyRate = 0,
    this.isAvailable = true,
  }) : super(id: id, email: email, fullName: fullName, phone: phone, role: 'sitter');

  factory SitterModel.fromJson(Map<String, dynamic> json) {
    return SitterModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}

// ----------------------------------------------------------------------
// CourierModel (Petsy courrier) - 🔵 yerith mel UserModel direct (mch
// mel SitterModel) - el courier khadmtou (na9el el 7ayawan) mo5tlfa
// 3an el sitter (yer3aa el 7ayawan), fa ma3andouch ma3na ye5dhou nafs
// el 7ou9oul (bio, hourlyRate...).
// ----------------------------------------------------------------------
class CourierModel extends UserModel {
  final String vehicleType;

  CourierModel({
    required String id,
    required String email,
    required String fullName,
    required String phone,
    this.vehicleType = '',
  }) : super(id: id, email: email, fullName: fullName, phone: phone, role: 'courier');

  factory CourierModel.fromJson(Map<String, dynamic> json) {
    return CourierModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      vehicleType: json['vehicleType'] as String? ?? '',
    );
  }
}

// ----------------------------------------------------------------------
// userModelFromJson: function "dispatcher" - t9ra el "role" mel JSON
// w traja3 el class el sa7i7a (mch UserModel 3ama, class mfassla).
// ----------------------------------------------------------------------
UserModel userModelFromJson(Map<String, dynamic> json) {
  final String role = json['role'] as String;
  switch (role) {
    case 'admin':
      return AdminModel.fromJson(json);
    case 'owner':
      return OwnerModel.fromJson(json);
    case 'courier':
      return CourierModel.fromJson(json);
    case 'sitter':
      return SitterModel.fromJson(json);
    default:
      throw Exception('Unknown role: $role');
  }
}