import 'dart:convert';
import '../models/admin_review.dart';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// AdminReviewsController
// ============================================================================
// 🔵 ZID: appel 7a9i9i lel GET /api/admin/reviews (protégée, admin bark).
// ============================================================================
class AdminReviewsController {
  Future<List<AdminReview>?> fetchReviews({String? search}) async {
    try {
      final query = (search != null && search.trim().isNotEmpty)
          ? '?search=${Uri.encodeQueryComponent(search.trim())}'
          : '';

      final response = await ApiService.get('/admin/reviews$query', token: AuthSession.token);
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> raw = (data['reviews'] as List<dynamic>?) ?? [];
      return raw.map((r) => AdminReview.fromJson(r as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }
}