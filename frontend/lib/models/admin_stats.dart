// ============================================================================
// AdminStats
// ============================================================================
// 🔵 ZID: model bch nnajjmou n-parsiw el réponse tel GET /api/admin/stats
// (backend/controllers/adminController.js) - testa3melha fel
// AdminStatsController + AdminStatisticsScreen.
// ============================================================================
class AdminStats {
  final int totalUsers;
  final int totalOwners;
  final int totalSitters;
  final int totalCouriers;
  final int totalAdmins;
  final int totalPets;
  final int totalBookings;
  final Map<String, int> bookingsByStatus;
  // null = mazel mafamech ay questionnaire "completed" b'rating (mch 0 -
  // 0 kan y5alli el user y7es eno el moyenne "0 njoum" 7a9i9i).
  final double? averageRating;
  final int totalReviews;

  const AdminStats({
    required this.totalUsers,
    required this.totalOwners,
    required this.totalSitters,
    required this.totalCouriers,
    required this.totalAdmins,
    required this.totalPets,
    required this.totalBookings,
    required this.bookingsByStatus,
    required this.averageRating,
    required this.totalReviews,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawStatus =
        (json['bookingsByStatus'] as Map<String, dynamic>?) ?? {};

    return AdminStats(
      totalUsers: json['totalUsers'] as int? ?? 0,
      totalOwners: json['totalOwners'] as int? ?? 0,
      totalSitters: json['totalSitters'] as int? ?? 0,
      totalCouriers: json['totalCouriers'] as int? ?? 0,
      totalAdmins: json['totalAdmins'] as int? ?? 0,
      totalPets: json['totalPets'] as int? ?? 0,
      totalBookings: json['totalBookings'] as int? ?? 0,
      bookingsByStatus: rawStatus.map(
        (key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0),
      ),
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: json['totalReviews'] as int? ?? 0,
    );
  }

  // 🔵 helpers - bch el UI ma te7tajch te3raf el esm exact tel key
  // (bookingsByStatus['pending']) fi kol blasa.
  int get pendingBookings => bookingsByStatus['pending'] ?? 0;
  int get acceptedBookings => bookingsByStatus['accepted'] ?? 0;
  int get rejectedBookings => bookingsByStatus['rejected'] ?? 0;
  int get openBookings => bookingsByStatus['open'] ?? 0;
  int get awaitingConfirmationBookings => bookingsByStatus['awaiting_confirmation'] ?? 0;
}

// ============================================================================
// MonthlyRegistrations
// ============================================================================
// 🔵 ZID: parse el réponse tel GET /api/admin/registrations/monthly
// (Tableau de bord - Line Chart) - "months" liste el chhour (format
// "YYYY-MM"), "series" 4 listes b'nefs tarti9 el "months" (total/
// owner/sitter/courier).
// ============================================================================
class MonthlyRegistrations {
  final List<String> months; // "2026-03", "2026-04", ...
  final List<int> total;
  final List<int> owner;
  final List<int> sitter;
  final List<int> courier;

  const MonthlyRegistrations({
    required this.months,
    required this.total,
    required this.owner,
    required this.sitter,
    required this.courier,
  });

  factory MonthlyRegistrations.fromJson(Map<String, dynamic> json) {
    final List<dynamic> monthsRaw = (json['months'] as List<dynamic>?) ?? [];
    final Map<String, dynamic> seriesRaw = (json['series'] as Map<String, dynamic>?) ?? {};

    List<int> _series(String key) {
      final List<dynamic> raw = (seriesRaw[key] as List<dynamic>?) ?? [];
      return raw.map((v) => (v as num?)?.toInt() ?? 0).toList();
    }

    return MonthlyRegistrations(
      months: monthsRaw.map((m) => m.toString()).toList(),
      total: _series('total'),
      owner: _series('owner'),
      sitter: _series('sitter'),
      courier: _series('courier'),
    );
  }
}