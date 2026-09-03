// ============================================================================
// AdminVerificationSettings
// ============================================================================
// 🔵 ZID (kifma tlab: "khalli les conditions hedhom yodhhrou 3and el
// admin w ynajem yamlelhom modification") - parse/serialize el réponse
// tel GET/PUT /api/admin/verification-settings.
// ============================================================================
class AdminVerificationSettings {
  final int sitterMinServices;
  final int sitterMinDistinctClients;
  final double sitterMinGoodReviewPercent;
  final int ownerMinServices;
  final double ownerMinGoodReviewPercent;

  const AdminVerificationSettings({
    required this.sitterMinServices,
    required this.sitterMinDistinctClients,
    required this.sitterMinGoodReviewPercent,
    required this.ownerMinServices,
    required this.ownerMinGoodReviewPercent,
  });

  factory AdminVerificationSettings.fromJson(Map<String, dynamic> json) {
    return AdminVerificationSettings(
      sitterMinServices: (json['sitterMinServices'] as num?)?.toInt() ?? 100,
      sitterMinDistinctClients: (json['sitterMinDistinctClients'] as num?)?.toInt() ?? 40,
      sitterMinGoodReviewPercent: (json['sitterMinGoodReviewPercent'] as num?)?.toDouble() ?? 90,
      ownerMinServices: (json['ownerMinServices'] as num?)?.toInt() ?? 30,
      ownerMinGoodReviewPercent: (json['ownerMinGoodReviewPercent'] as num?)?.toDouble() ?? 95,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sitterMinServices': sitterMinServices,
      'sitterMinDistinctClients': sitterMinDistinctClients,
      'sitterMinGoodReviewPercent': sitterMinGoodReviewPercent,
      'ownerMinServices': ownerMinServices,
      'ownerMinGoodReviewPercent': ownerMinGoodReviewPercent,
    };
  }
}