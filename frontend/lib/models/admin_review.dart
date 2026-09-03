// ============================================================================
// SiblingReview
// ============================================================================
// 🔵 ZID (kifma tlab: "kif nenzel ala 1 yjini les réponses ala el
// questionnaire de les deux, kifkif ou kan") - el avis tel "l'autre
// partie" (owner<->sitter) 3ala NEFS el booking - testa3melha fel
// détail (bottom sheet) bch ywarri el 2 réponses mjem3in.
//
// 🔴 FIX (kifma tlab: "nhb les réponses ala el questionnaire lkol, mch
// ken l avis") - zedna el 3 étapes el oula (service/checkout/paiement)
// - mch ghir l'étape 4 (satisfaction+rating, elli kanet ghir wa7da
// mawjouda).
// ============================================================================
class SiblingReview {
  final String reviewerName;
  final String reviewerPhotoUrl;
  final String reviewerRole;
  final String status; // pending / awaiting_new_checkout / stopped_service_not_done / completed
  final bool? serviceDone;
  final String serviceDoneReason;
  final bool? checkoutDone;
  final bool? paymentDone;
  final String paymentNotDoneReason;
  final bool? satisfied;
  final int? ratingTrust;
  final int? ratingService;
  final int? ratingCommunication;
  final int? ratingKnowledge;
  final double averageRating;
  final String review;
  final DateTime? createdAt;

  const SiblingReview({
    required this.reviewerName,
    required this.reviewerPhotoUrl,
    required this.reviewerRole,
    required this.status,
    required this.serviceDone,
    required this.serviceDoneReason,
    required this.checkoutDone,
    required this.paymentDone,
    required this.paymentNotDoneReason,
    required this.satisfied,
    required this.ratingTrust,
    required this.ratingService,
    required this.ratingCommunication,
    required this.ratingKnowledge,
    required this.averageRating,
    required this.review,
    required this.createdAt,
  });

  factory SiblingReview.fromJson(Map<String, dynamic> json) {
    return SiblingReview(
      reviewerName: json['reviewerName'] as String? ?? '',
      reviewerPhotoUrl: json['reviewerPhotoUrl'] as String? ?? '',
      reviewerRole: json['reviewerRole'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      serviceDone: json['serviceDone'] as bool?,
      serviceDoneReason: json['serviceDoneReason'] as String? ?? '',
      checkoutDone: json['checkoutDone'] as bool?,
      paymentDone: json['paymentDone'] as bool?,
      paymentNotDoneReason: json['paymentNotDoneReason'] as String? ?? '',
      satisfied: json['satisfied'] as bool?,
      ratingTrust: (json['ratingTrust'] as num?)?.toInt(),
      ratingService: (json['ratingService'] as num?)?.toInt(),
      ratingCommunication: (json['ratingCommunication'] as num?)?.toInt(),
      ratingKnowledge: (json['ratingKnowledge'] as num?)?.toInt(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      review: json['review'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

// ============================================================================
// AdminReview
// ============================================================================
// 🔵 ZID: parse el réponse tel GET /api/admin/reviews - testa3melha
// fel AdminReviewsScreen ("Avis").
// ============================================================================
class AdminReview {
  final String id;
  final String reviewerName;
  final String reviewerPhotoUrl;
  final String reviewerRole;
  final String revieweeName;
  final String revieweePhotoUrl;
  final String revieweeRole;
  // 🔴 FIX (kifma tlab): el 3 étapes el oula (service/checkout/paiement) -
  // el questionnaire yenja7 el 4 étapes b'tarti9, w mumkin ye39od "coincé"
  // (status != 'completed') 9bal ma yousel l'étape satisfaction/rating.
  final String status;
  final bool? serviceDone;
  final String serviceDoneReason;
  final bool? checkoutDone;
  final bool? paymentDone;
  final String paymentNotDoneReason;
  final bool? satisfied;
  final int? ratingTrust;
  final int? ratingService;
  final int? ratingCommunication;
  final int? ratingKnowledge;
  final double averageRating;
  final String review;
  final DateTime? createdAt;
  // 🔵 ZID (kifma tlab: "ken les acteurs jewbou aks ba3dhom fel oui w
  // non tjini en rouge, w ken el total mtaa etoiles a9al men 2 zeda
  // tjini en rouge") - el backend ye7sabhom (adminController.js/
  // listReviews) - houni ghir n-parsihom, bla ay logique zeyda (kifma
  // tlab: "haja sehla, mahiech complique fel code").
  final bool hasConflict;
  final bool isLowRating;
  final SiblingReview? siblingReview;

  const AdminReview({
    required this.id,
    required this.reviewerName,
    required this.reviewerPhotoUrl,
    required this.reviewerRole,
    required this.revieweeName,
    required this.revieweePhotoUrl,
    required this.revieweeRole,
    required this.status,
    required this.serviceDone,
    required this.serviceDoneReason,
    required this.checkoutDone,
    required this.paymentDone,
    required this.paymentNotDoneReason,
    required this.satisfied,
    required this.ratingTrust,
    required this.ratingService,
    required this.ratingCommunication,
    required this.ratingKnowledge,
    required this.averageRating,
    required this.review,
    required this.createdAt,
    required this.hasConflict,
    required this.isLowRating,
    required this.siblingReview,
  });

  // 🔵 helper: "kammel el 4 étapes" - bch el UI ye5tar kifeh ywarri el
  // card (rating/stars ken true, badge status wla9ed ken false).
  bool get isFullyCompleted => status == 'completed';

  factory AdminReview.fromJson(Map<String, dynamic> json) {
    return AdminReview(
      id: json['id'] as String? ?? '',
      reviewerName: json['reviewerName'] as String? ?? '',
      reviewerPhotoUrl: json['reviewerPhotoUrl'] as String? ?? '',
      reviewerRole: json['reviewerRole'] as String? ?? '',
      revieweeName: json['revieweeName'] as String? ?? '',
      revieweePhotoUrl: json['revieweePhotoUrl'] as String? ?? '',
      revieweeRole: json['revieweeRole'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      serviceDone: json['serviceDone'] as bool?,
      serviceDoneReason: json['serviceDoneReason'] as String? ?? '',
      checkoutDone: json['checkoutDone'] as bool?,
      paymentDone: json['paymentDone'] as bool?,
      paymentNotDoneReason: json['paymentNotDoneReason'] as String? ?? '',
      satisfied: json['satisfied'] as bool?,
      ratingTrust: (json['ratingTrust'] as num?)?.toInt(),
      ratingService: (json['ratingService'] as num?)?.toInt(),
      ratingCommunication: (json['ratingCommunication'] as num?)?.toInt(),
      ratingKnowledge: (json['ratingKnowledge'] as num?)?.toInt(),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      review: json['review'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      hasConflict: json['hasConflict'] as bool? ?? false,
      isLowRating: json['isLowRating'] as bool? ?? false,
      siblingReview: json['siblingReview'] != null ? SiblingReview.fromJson(json['siblingReview'] as Map<String, dynamic>) : null,
    );
  }
}