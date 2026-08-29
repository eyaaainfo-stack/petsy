import 'dart:convert';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// SitterAvailability
// ============================================================================
// 🔵 ZID (kifma tlab): "disponibilité" - recurringDaysOff (1=Mon..7=Sun,
// nafs convention DateTime.weekday) + specificDatesOff (dates mo7addda -
// a3yed/jours fériés/ayemet zadhom el sitter b'rou7ou).
// ============================================================================
class SitterAvailability {
  final List<int> recurringDaysOff;
  final List<DateTime> specificDatesOff;

  const SitterAvailability({this.recurringDaysOff = const [], this.specificDatesOff = const []});

  factory SitterAvailability.fromJson(Map<String, dynamic> json) {
    final List<dynamic> recurring = json['recurringDaysOff'] as List<dynamic>? ?? [];
    final List<dynamic> specific = json['specificDatesOff'] as List<dynamic>? ?? [];
    return SitterAvailability(
      recurringDaysOff: recurring.map((e) => (e as num).toInt()).toList(),
      specificDatesOff: specific.map((e) => DateTime.parse(e as String)).toList(),
    );
  }
}

class AvailabilityController {
  // 🔵 el data mo5azzna fel "profile" el 3adi (GET /users/profile déjà
  // yerja3ha lel sitters) - bla ha na3mlou endpoint zeyed.
  Future<SitterAvailability?> fetchAvailability() async {
    try {
      final response = await ApiService.get('/users/profile', token: AuthSession.token);
      if (response.statusCode != 200) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return SitterAvailability.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<bool> submitAvailability({required List<int> recurringDaysOff, required List<DateTime> specificDatesOff}) async {
    try {
      final response = await ApiService.patch(
        '/users/sitter-details',
        {
          'recurringDaysOff': recurringDaysOff,
          'specificDatesOff': specificDatesOff.map((d) => d.toUtc().toIso8601String()).toList(),
        },
        token: AuthSession.token,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}