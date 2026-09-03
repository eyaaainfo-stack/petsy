import 'admin_user.dart';

// ============================================================================
// OwnerStats / SitterStats
// ============================================================================
// 🔵 ZID: kifma tlab - "kenou owner kdeh andou men pet w kdeh men
// demande tlabha w kdeh men demande tkblt w trafdhet w cancelhaa" /
// "kenou sitter kadeh men service amlou w kdeh men service rofdho w
// kdeh men service sarlo cancel".
//
// 🔴 IMPORTANT: "refusé" w "annulé" (sitter yenni booking déjà
// accepted) mel data model el 7a9i9i tetsajjlou b'NAFS el mécanisme
// (chraht kaملa fel backend, adminController.js/getUserDetail) - fa
// "refusedCount" houni COMBINÉE (Refusées + Annulées f'nefs el
// chiffre), mch 2 chiffres mnfaslin.
// ============================================================================
class OwnerStats {
  final int petsCount;
  final int requestsCount;
  final int acceptedCount;
  final int refusedCount;

  const OwnerStats({
    required this.petsCount,
    required this.requestsCount,
    required this.acceptedCount,
    required this.refusedCount,
  });

  factory OwnerStats.fromJson(Map<String, dynamic> json) {
    return OwnerStats(
      petsCount: json['petsCount'] as int? ?? 0,
      requestsCount: json['requestsCount'] as int? ?? 0,
      acceptedCount: json['acceptedCount'] as int? ?? 0,
      refusedCount: json['refusedCount'] as int? ?? 0,
    );
  }
}

class SitterStats {
  final int completedCount;
  final int refusedCount;

  const SitterStats({required this.completedCount, required this.refusedCount});

  factory SitterStats.fromJson(Map<String, dynamic> json) {
    return SitterStats(
      completedCount: json['completedCount'] as int? ?? 0,
      refusedCount: json['refusedCount'] as int? ?? 0,
    );
  }
}

// ============================================================================
// AdminUserDetail
// ============================================================================
// 🔵 ZID: parse el réponse tel GET /api/admin/users/:id - testa3melha
// fel AdminAccountDetailScreen.
//
// 🔴 FIX: city/birthday twallew fel AdminUser nafsou (toAdminUserJson,
// backend) - ma3adech me7tejin fields mkarrarin houni, ghir user.city/
// user.birthday direct.
// ============================================================================
class AdminUserDetail {
  final AdminUser user;
  final OwnerStats? ownerStats;
  final SitterStats? sitterStats;

  const AdminUserDetail({
    required this.user,
    required this.ownerStats,
    required this.sitterStats,
  });

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    return AdminUserDetail(
      user: AdminUser.fromJson(json['user'] as Map<String, dynamic>),
      ownerStats: json['ownerStats'] != null ? OwnerStats.fromJson(json['ownerStats'] as Map<String, dynamic>) : null,
      sitterStats: json['sitterStats'] != null ? SitterStats.fromJson(json['sitterStats'] as Map<String, dynamic>) : null,
    );
  }
}