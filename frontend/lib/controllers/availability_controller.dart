import 'dart:convert';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// RecurringHoursOff / SpecificHoursOffEntry
// ============================================================================
// 🔵 ZID (kifma tlab: "el disponibilité tzid horaire zeda - mel 22h
// hatta l 7h ma ye5demch, wla 1h/wa9t mo7addad fi nhar mo7addad") -
// "startMinutes"/"endMinutes" = d9ay9 mel nos el lil (0-1439, mathalan
// 22h=1320, 7h=420) - "end < start" ye3ni el blocage y3adi nos el lil
// (mafamech 7a9el "wraps" mنفصل, el logique tel checking - backend w
// AvailabilityPicker - te3ref t9ass el 2 7alat).
class RecurringHoursOff {
  final int? startMinutes;
  final int? endMinutes;

  const RecurringHoursOff({this.startMinutes, this.endMinutes});

  bool get isSet => startMinutes != null && endMinutes != null;

  factory RecurringHoursOff.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RecurringHoursOff();
    return RecurringHoursOff(
      startMinutes: (json['startMinutes'] as num?)?.toInt(),
      endMinutes: (json['endMinutes'] as num?)?.toInt(),
    );
  }
}

class SpecificHoursOffEntry {
  final DateTime date;
  final int startMinutes;
  final int endMinutes;

  const SpecificHoursOffEntry({required this.date, required this.startMinutes, required this.endMinutes});

  factory SpecificHoursOffEntry.fromJson(Map<String, dynamic> json) {
    return SpecificHoursOffEntry(
      date: DateTime.parse(json['date'] as String),
      startMinutes: (json['startMinutes'] as num).toInt(),
      endMinutes: (json['endMinutes'] as num).toInt(),
    );
  }
}

// ============================================================================
// SitterAvailability
// ============================================================================
// 🔵 ZID (kifma tlab): "disponibilité" - recurringDaysOff (1=Mon..7=Sun,
// nafs convention DateTime.weekday) + specificDatesOff (dates mo7addda -
// a3yed/jours fériés/ayemet zadhom el sitter b'rou7ou) + (ZID) horaire:
// recurringHoursOff (sa3at fixa kol youm) + specificHoursOff (blocages
// ponctuels, youm+sa3a mo7addda).
// ============================================================================
class SitterAvailability {
  final List<int> recurringDaysOff;
  final List<DateTime> specificDatesOff;
  final RecurringHoursOff recurringHoursOff;
  final List<SpecificHoursOffEntry> specificHoursOff;

  const SitterAvailability({
    this.recurringDaysOff = const [],
    this.specificDatesOff = const [],
    this.recurringHoursOff = const RecurringHoursOff(),
    this.specificHoursOff = const [],
  });

  factory SitterAvailability.fromJson(Map<String, dynamic> json) {
    final List<dynamic> recurring = json['recurringDaysOff'] as List<dynamic>? ?? [];
    final List<dynamic> specific = json['specificDatesOff'] as List<dynamic>? ?? [];
    final List<dynamic> specificHours = json['specificHoursOff'] as List<dynamic>? ?? [];
    return SitterAvailability(
      recurringDaysOff: recurring.map((e) => (e as num).toInt()).toList(),
      specificDatesOff: specific.map((e) => DateTime.parse(e as String)).toList(),
      recurringHoursOff: RecurringHoursOff.fromJson(json['recurringHoursOff'] as Map<String, dynamic>?),
      specificHoursOff: specificHours.map((e) => SpecificHoursOffEntry.fromJson(e as Map<String, dynamic>)).toList(),
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

  Future<bool> submitAvailability({
    required List<int> recurringDaysOff,
    required List<DateTime> specificDatesOff,
    RecurringHoursOff? recurringHoursOff,
    List<SpecificHoursOffEntry>? specificHoursOff,
  }) async {
    try {
      final response = await ApiService.patch(
        '/users/sitter-details',
        {
          'recurringDaysOff': recurringDaysOff,
          'specificDatesOff': specificDatesOff.map((d) => d.toUtc().toIso8601String()).toList(),
          // 🔵 ZID (kifma tlab): "horaire zeda" - GHIR lowkan mzoud
          // (optionnel, partiel kifma el ba9i).
          if (recurringHoursOff != null)
            'recurringHoursOff': {'startMinutes': recurringHoursOff.startMinutes, 'endMinutes': recurringHoursOff.endMinutes},
          if (specificHoursOff != null)
            'specificHoursOff': specificHoursOff
                .map((h) => {'date': h.date.toUtc().toIso8601String(), 'startMinutes': h.startMinutes, 'endMinutes': h.endMinutes})
                .toList(),
        },
        token: AuthSession.token,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}