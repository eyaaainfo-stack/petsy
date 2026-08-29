import 'dart:convert';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// UserReview
// ============================================================================
// 🔵 ZID (kifma tlab): "avis" (questionnaire ba3d checkout) ywalli VRAI
// review, yban 3al profile (view_profile_sitter.dart) - satisfied +
// review (text) + 4 catégories (Trust/Service/Communication/Knowledge)
// + averageRating (mo7esseb, chrahtha el backend).
// ============================================================================
class UserReview {
  final String id;
  final String reviewerName;
  final String? reviewerPhotoUrl;
  final bool? satisfied;
  final int? ratingTrust;
  final int? ratingService;
  final int? ratingCommunication;
  final int? ratingKnowledge;
  final double averageRating;
  final String review;
  final DateTime createdAt;

  const UserReview({
    required this.id,
    required this.reviewerName,
    this.reviewerPhotoUrl,
    this.satisfied,
    this.ratingTrust,
    this.ratingService,
    this.ratingCommunication,
    this.ratingKnowledge,
    required this.averageRating,
    required this.review,
    required this.createdAt,
  });

  factory UserReview.fromJson(Map<String, dynamic> json) {
    final String? rawPhoto = json['reviewerPhotoUrl'] as String?;
    return UserReview(
      id: json['id'] as String? ?? '',
      reviewerName: json['reviewerName'] as String? ?? '',
      reviewerPhotoUrl: (rawPhoto != null && rawPhoto.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawPhoto' : null,
      satisfied: json['satisfied'] as bool?,
      ratingTrust: json['ratingTrust'] as int?,
      ratingService: json['ratingService'] as int?,
      ratingCommunication: json['ratingCommunication'] as int?,
      ratingKnowledge: json['ratingKnowledge'] as int?,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      review: json['review'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class UserReviewsResult {
  final List<UserReview> reviews;
  final double? totalAverage;
  final int totalCount;

  const UserReviewsResult({required this.reviews, this.totalAverage, required this.totalCount});
}

class ReviewsController {
  Future<UserReviewsResult> fetchReviews(String userId) async {
    try {
      final response = await ApiService.get('/users/$userId/reviews', token: AuthSession.token);
      if (response.statusCode != 200) return const UserReviewsResult(reviews: [], totalCount: 0);
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = data['reviews'] as List<dynamic>;
      return UserReviewsResult(
        reviews: list.map((e) => UserReview.fromJson(e as Map<String, dynamic>)).toList(),
        totalAverage: (data['totalAverage'] as num?)?.toDouble(),
        totalCount: data['totalCount'] as int? ?? 0,
      );
    } catch (_) {
      return const UserReviewsResult(reviews: [], totalCount: 0);
    }
  }
}