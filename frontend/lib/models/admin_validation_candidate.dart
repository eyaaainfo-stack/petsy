import 'admin_user.dart';

// ============================================================================
// AdminValidationCandidate
// ============================================================================
// 🔵 ZID (kifma tlab: "wkt el checklist tekmel tjii lel admin
// proposition bch ywalli valider") - parse el réponse tel GET
// /api/admin/validations - user + checklist (kol el critères True,
// 7it el backend déjà ye-filtri ghir el comptes elli el checklist
// tou3hom KAMLA - chraht fel adminController.js/computeChecklist).
// ============================================================================
class AdminValidationCandidate {
  final AdminUser user;
  // 🔵 esm el critère (mathalan "fullName", "hasPet"...) -> True/False.
  // Kifma el backend ye-filtri ghir el comptes 100% kamlin, el 7ou9oul
  // el kol houni el mafroudh ykounou True - twarrihom bark bch el admin
  // yechouf b'3ainou 9bal ma ye5tar "Valider".
  final Map<String, bool> checklist;

  const AdminValidationCandidate({required this.user, required this.checklist});

  factory AdminValidationCandidate.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawChecklist = (json['checklist'] as Map<String, dynamic>?) ?? {};
    return AdminValidationCandidate(
      user: AdminUser.fromJson(json['user'] as Map<String, dynamic>),
      checklist: rawChecklist.map((key, value) => MapEntry(key, value as bool? ?? false)),
    );
  }
}