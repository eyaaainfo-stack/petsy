// ============================================================================
// VerificationMetrics
// ============================================================================
// 🔵 ZID (kifma tlab: "kol ma conditions tsiir tetaamlelha tick
// automatiquement") - ar9am 7a9i9iyin (kadeh 3andou / kadeh lezmou) -
// bch el UI (écran "Vérification") twarri "progress" (mathalan
// "45/100"), mch ghir ✓/✗ bla contexte. 7ou9oul mo5tلfin 7asb el role
// (owner/sitter) - kolhom nullable, el UI twarri ghir el mawjoudin.
// ============================================================================
class VerificationMetrics {
  final int? servicesCount;
  final int? servicesRequired;
  final int? distinctClients;
  final int? distinctClientsRequired;
  final double? goodReviewPercent;
  final double? goodReviewPercentRequired;
  final int? totalReviews;

  const VerificationMetrics({
    required this.servicesCount,
    required this.servicesRequired,
    required this.distinctClients,
    required this.distinctClientsRequired,
    required this.goodReviewPercent,
    required this.goodReviewPercentRequired,
    required this.totalReviews,
  });

  factory VerificationMetrics.fromJson(Map<String, dynamic> json) {
    return VerificationMetrics(
      servicesCount: json['servicesCount'] as int?,
      servicesRequired: json['servicesRequired'] as int?,
      distinctClients: json['distinctClients'] as int?,
      distinctClientsRequired: json['distinctClientsRequired'] as int?,
      goodReviewPercent: (json['goodReviewPercent'] as num?)?.toDouble(),
      goodReviewPercentRequired: (json['goodReviewPercentRequired'] as num?)?.toDouble(),
      totalReviews: json['totalReviews'] as int?,
    );
  }
}

// ============================================================================
// VerificationStatus
// ============================================================================
// 🔵 ZID: parse el réponse tel GET /api/users/me/verification -
// testa3melha fel VerificationStatusScreen ("Vérification", sidebar
// owner/sitter).
// ============================================================================
class VerificationStatus {
  final Map<String, bool> checklist;
  final VerificationMetrics metrics;
  final bool isComplete;
  final bool isVerified;
  final DateTime? verifiedAt;

  const VerificationStatus({
    required this.checklist,
    required this.metrics,
    required this.isComplete,
    required this.isVerified,
    required this.verifiedAt,
  });

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawChecklist = (json['checklist'] as Map<String, dynamic>?) ?? {};
    return VerificationStatus(
      checklist: rawChecklist.map((key, value) => MapEntry(key, value as bool? ?? false)),
      metrics: VerificationMetrics.fromJson((json['metrics'] as Map<String, dynamic>?) ?? {}),
      isComplete: json['isComplete'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedAt: json['verifiedAt'] != null ? DateTime.tryParse(json['verifiedAt'] as String) : null,
    );
  }
}