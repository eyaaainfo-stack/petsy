import 'dart:convert';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// BookingController
// ============================================================================
class BookingResult {
  final bool success;
  final String? errorMessage;

  const BookingResult._(this.success, this.errorMessage);

  factory BookingResult.success() => const BookingResult._(true, null);
  factory BookingResult.failure(String message) => BookingResult._(false, message);
}

class BookingController {
  Future<BookingResult> createBooking({
    required String sitterId,
    required List<String> petIds,
    required List<Map<String, dynamic>> services,
    required DateTime checkIn,
    required DateTime checkOut,
    required double total,
  }) async {
    try {
      final response = await ApiService.post(
        '/bookings',
        {
          'sitterId': sitterId,
          'petIds': petIds,
          'services': services,
          // 🔴 FIX (bug timezone): "checkIn.toIso8601String()" (bla
          // ".toUtc()") kan yeb3ath wa9t LOCAL bla "Z" (mathalan
          // "2026-08-26T13:00:00.000" - 1pm Tunisie) - el backend
          // (Node/Mongo) kan yesta9belha w yeh'zenha KIFHA HIYA (bla
          // ma yconverti) TAKEN kanha UTC direct - fa kol booking
          // kan yet5azzen b'SA3A ZEYDA (1pm Tunisie -> 1pm UTC = 2pm
          // Tunisie 7a9i9i)! ".toUtc()" houni ye7keb el conversion
          // el SA7I7A 9BAL el ib3ath (1pm Tunisie -> 12pm UTC).
          'checkIn': checkIn.toUtc().toIso8601String(),
          'checkOut': checkOut.toUtc().toIso8601String(),
          'total': total,
        },
        token: AuthSession.token,
      );

      if (response.statusCode == 201) return BookingResult.success();

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return BookingResult.failure(data['message'] as String? ?? 'login_generic_error');
    } catch (_) {
      return BookingResult.failure('login_generic_error');
    }
  }
}