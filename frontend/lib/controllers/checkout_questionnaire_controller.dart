import 'dart:convert';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// PendingQuestionnaireItem (home screen - "3andi questionnaire n7eb n'jaweb 3lih")
// ============================================================================
class PendingQuestionnaireItem {
  final String bookingId;
  final String role; // 'owner' / 'sitter'

  const PendingQuestionnaireItem({required this.bookingId, required this.role});

  factory PendingQuestionnaireItem.fromJson(Map<String, dynamic> json) {
    return PendingQuestionnaireItem(
      bookingId: json['bookingId'] as String? ?? '',
      role: json['role'] as String? ?? '',
    );
  }
}

// ============================================================================
// CheckoutDelay (l'historique tel "checkout mte2akhar")
// ============================================================================
class CheckoutDelay {
  final String blamedParty; // 'owner' / 'sitter'
  final DateTime newCheckoutTime;

  const CheckoutDelay({required this.blamedParty, required this.newCheckoutTime});

  factory CheckoutDelay.fromJson(Map<String, dynamic> json) {
    return CheckoutDelay(
      blamedParty: json['blamedParty'] as String? ?? '',
      newCheckoutTime: DateTime.parse(json['newCheckoutTime'] as String),
    );
  }
}

// ============================================================================
// QuestionnaireState (l'état kaملou tel questionnaire - bch el wizard
// ynajjam "yresumi" mnin we9af)
// ============================================================================
class QuestionnaireState {
  final String id;
  final String bookingId;
  final String respondentRole; // 'owner' / 'sitter' (chkoun ana f'had booking)
  final String revieweeName;
  final String? revieweePhotoUrl;

  final bool? serviceDone;
  final String serviceDoneReason;

  final bool? checkoutDone;
  final List<CheckoutDelay> checkoutDelays;

  final bool? paymentDone;
  final String paymentNotDoneReason;

  final bool? satisfied;
  final int? ratingTrust;
  final int? ratingService;
  final int? ratingCommunication;
  final int? ratingKnowledge;
  final double? averageRating;
  final String review;

  final String status; // pending / awaiting_new_checkout / stopped_service_not_done / completed
  final DateTime? nextPromptAt;

  const QuestionnaireState({
    required this.id,
    required this.bookingId,
    required this.respondentRole,
    required this.revieweeName,
    this.revieweePhotoUrl,
    this.serviceDone,
    this.serviceDoneReason = '',
    this.checkoutDone,
    this.checkoutDelays = const [],
    this.paymentDone,
    this.paymentNotDoneReason = '',
    this.satisfied,
    this.ratingTrust,
    this.ratingService,
    this.ratingCommunication,
    this.ratingKnowledge,
    this.averageRating,
    this.review = '',
    required this.status,
    this.nextPromptAt,
  });

  factory QuestionnaireState.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? revieweeJson = json['reviewee'] as Map<String, dynamic>?;
    final String? rawPhoto = revieweeJson?['photoUrl'] as String?;
    final List<dynamic> delaysJson = json['checkoutDelays'] as List<dynamic>? ?? [];

    return QuestionnaireState(
      id: json['_id'] as String? ?? '',
      bookingId: json['booking'] as String? ?? '',
      respondentRole: json['respondentRole'] as String? ?? '',
      revieweeName: revieweeJson?['fullName'] as String? ?? '',
      revieweePhotoUrl: (rawPhoto != null && rawPhoto.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawPhoto' : null,
      serviceDone: json['serviceDone'] as bool?,
      serviceDoneReason: json['serviceDoneReason'] as String? ?? '',
      checkoutDone: json['checkoutDone'] as bool?,
      checkoutDelays: delaysJson.map((d) => CheckoutDelay.fromJson(d as Map<String, dynamic>)).toList(),
      paymentDone: json['paymentDone'] as bool?,
      paymentNotDoneReason: json['paymentNotDoneReason'] as String? ?? '',
      satisfied: json['satisfied'] as bool?,
      ratingTrust: json['ratingTrust'] as int?,
      ratingService: json['ratingService'] as int?,
      ratingCommunication: json['ratingCommunication'] as int?,
      ratingKnowledge: json['ratingKnowledge'] as int?,
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      review: json['review'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      nextPromptAt: json['nextPromptAt'] != null ? DateTime.tryParse(json['nextPromptAt'] as String) : null,
    );
  }
}

class CheckoutQuestionnaireController {
  Future<List<PendingQuestionnaireItem>> fetchPending() async {
    try {
      final response = await ApiService.get('/bookings/pending-questionnaires', token: AuthSession.token);
      if (response.statusCode != 200) return [];
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = data['pending'] as List<dynamic>;
      return list.map((e) => PendingQuestionnaireItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<QuestionnaireState?> fetchQuestionnaire(String bookingId) async {
    try {
      final response = await ApiService.get('/bookings/$bookingId/questionnaire', token: AuthSession.token);
      if (response.statusCode != 200) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return QuestionnaireState.fromJson(data['questionnaire'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<QuestionnaireState?> answerServiceDone(String bookingId, {required bool done, String? reason}) async {
    return _answer('/bookings/$bookingId/questionnaire/service-done', {'done': done, if (reason != null) 'reason': reason});
  }

  Future<QuestionnaireState?> answerCheckoutDone(String bookingId, {required bool done, String? blamedParty, DateTime? newCheckoutTime}) async {
    return _answer('/bookings/$bookingId/questionnaire/checkout-done', {
      'done': done,
      if (blamedParty != null) 'blamedParty': blamedParty,
      if (newCheckoutTime != null) 'newCheckoutTime': newCheckoutTime.toUtc().toIso8601String(),
    });
  }

  Future<QuestionnaireState?> answerPaymentDone(String bookingId, {required bool done, String? reason}) async {
    return _answer('/bookings/$bookingId/questionnaire/payment-done', {'done': done, if (reason != null) 'reason': reason});
  }

  Future<QuestionnaireState?> answerSatisfaction(
    String bookingId, {
    required bool satisfied,
    String? review,
    required int ratingTrust,
    required int ratingService,
    required int ratingCommunication,
    required int ratingKnowledge,
  }) async {
    return _answer('/bookings/$bookingId/questionnaire/satisfaction', {
      'satisfied': satisfied,
      if (review != null) 'review': review,
      'ratingTrust': ratingTrust,
      'ratingService': ratingService,
      'ratingCommunication': ratingCommunication,
      'ratingKnowledge': ratingKnowledge,
    });
  }

  Future<QuestionnaireState?> _answer(String path, Map<String, dynamic> body) async {
    try {
      final response = await ApiService.patch(path, body, token: AuthSession.token);
      if (response.statusCode != 200) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return QuestionnaireState.fromJson(data['questionnaire'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}