// ============================================================================
// AdminUser
// ============================================================================
// 🔵 ZID: parse el réponse tel GET /api/admin/users (w POST/PUT tou3ha
// zeda, "user" object nafsou) - testa3melha fel AdminAccountsScreen +
// AdminAccountFormScreen.
// ============================================================================
class AdminUser {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  // 🔴 FIX (kifma tlab: "el modification eli ynajem yaamlha el admin
  // nhbha hiya bidha eli todhhor fel données mtaa el user") - city/
  // birthday tawa fel AdminUser (mch ghir AdminUserDetail) - bch
  // AdminAccountFormScreen ynajjam ye3addelhom (déjà mawjoudin fel
  // JSON tel /admin/users - toAdminUserJson, backend).
  final String city;
  final String birthday;
  final String role; // owner / sitter / courier / admin
  final String photoUrl;
  final DateTime? createdAt;
  // 🔵 ZID (kifma tlab: "el admin principale nhbou y39od fixe") - true
  // ghir lel compte admin el A9DAM (createdAt) - el front ye5fi
  // Modifier/Supprimer 3lih (badalhom b "Ajouter un autre admin") -
  // el backend ye-enforce zeda (mch ghir cosmétique).
  final bool isPrincipalAdmin;
  // 🔵 ZID (kifma tlab: "acteur vérifié") - badge + upload CIN.
  final bool isVerified;
  // 🔴 FIX (kifma tlab: "fazet el cin... el USER nafsou") - tawa
  // RECTO+VERSO (mch photo wa7da) - READ-ONLY houni (l'admin yechouf
  // bark, mch ynajjam yeb3ath - houwa el user elli yeb3ath, chraht fel
  // verification_status_screen.dart).
  final String cinFrontPhotoUrl;
  final String cinBackPhotoUrl;

  const AdminUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.city,
    required this.birthday,
    required this.role,
    required this.photoUrl,
    required this.createdAt,
    required this.isPrincipalAdmin,
    required this.isVerified,
    required this.cinFrontPhotoUrl,
    required this.cinBackPhotoUrl,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      city: json['city'] as String? ?? '',
      birthday: json['birthday'] as String? ?? '',
      role: json['role'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      isPrincipalAdmin: json['isPrincipalAdmin'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      cinFrontPhotoUrl: json['cinFrontPhotoUrl'] as String? ?? '',
      cinBackPhotoUrl: json['cinBackPhotoUrl'] as String? ?? '',
    );
  }

  // 🔵 helper: "FC" (initiales, kifma el screenshot el référence) - ken
  // fullName fadhi (compte 3omrou ma 3adda UserCreateProfileScreen),
  // ne5dou awel 7arf mel email.
  String get initials {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}