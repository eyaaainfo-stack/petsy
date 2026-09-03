import 'dart:convert';
import '../models/admin_stats.dart';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// AdminStatsController
// ============================================================================
// 🔵 ZID: appel 7a9i9i lel GET /api/admin/stats (protégée, protect+isAdmin
// fel backend - el token lezemhou role admin, wala 403).
// ============================================================================
class AdminStatsController {
  Future<AdminStats?> fetchStats() async {
    try {
      final response = await ApiService.get('/admin/stats', token: AuthSession.token);
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return AdminStats.fromJson(data);
    } catch (_) {
      // mfamech connexion, server twaqqaf, timeout... - null bch el
      // écran ywarri état "erreur" (mch loading l'infini).
      return null;
    }
  }

  // 🔵 ZID: GET /api/admin/registrations/monthly?months=N - lel
  // "Tableau de bord" (Line Chart). months bin 1 w 12 (el backend
  // ye-clamp zeda, houni ghir sécurité zeyda mch fel front bark).
  Future<MonthlyRegistrations?> fetchMonthlyRegistrations(int months) async {
    final int clamped = months.clamp(1, 12);
    try {
      final response = await ApiService.get(
        '/admin/registrations/monthly?months=$clamped',
        token: AuthSession.token,
      );
      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return MonthlyRegistrations.fromJson(data);
    } catch (_) {
      return null;
    }
  }
}