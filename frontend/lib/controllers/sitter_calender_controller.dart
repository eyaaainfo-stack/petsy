import 'dart:convert';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// SchedulePet (pet mfassal - esm+photo+gender, sitter_profile.dart
// "Today Patient" te7taj gender, mch bess el esm kifma sitter_calender.dart)
// ============================================================================
class SchedulePet {
  final String name;
  final String? photoUrl;
  final String? gender;

  const SchedulePet({required this.name, this.photoUrl, this.gender});

  factory SchedulePet.fromJson(Map<String, dynamic> json) {
    final String? raw = json['photoUrl'] as String?;
    return SchedulePet(
      name: json['name'] as String? ?? '',
      photoUrl: (raw != null && raw.isNotEmpty) ? '${ApiService.mediaBaseUrl}$raw' : null,
      gender: json['gender'] as String?,
    );
  }
}

// ============================================================================
// ScheduleBooking (sitter_calender.dart)
// ============================================================================
class ScheduleBooking {
  final String id;
  final List<String> serviceIds;
  final DateTime checkIn;
  final DateTime checkOut;
  final String petNames;
  final String? firstPetPhotoUrl;
  final List<SchedulePet> pets;

  const ScheduleBooking({
    required this.id,
    required this.serviceIds,
    required this.checkIn,
    required this.checkOut,
    required this.petNames,
    this.firstPetPhotoUrl,
    required this.pets,
  });

  factory ScheduleBooking.fromJson(Map<String, dynamic> json) {
    final List<dynamic> petsJson = json['pets'] as List<dynamic>? ?? [];
    final List<dynamic> servicesJson = json['services'] as List<dynamic>? ?? [];
    final String? rawFirstPhoto = petsJson.isNotEmpty ? (petsJson.first as Map<String, dynamic>)['photoUrl'] as String? : null;

    return ScheduleBooking(
      id: json['_id'] as String? ?? '',
      serviceIds: servicesJson.map((s) => (s as Map<String, dynamic>)['serviceId'] as String? ?? '').toList(),
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: DateTime.parse(json['checkOut'] as String),
      petNames: petsJson.map((p) => (p as Map<String, dynamic>)['name'] as String? ?? '').join(', '),
      firstPetPhotoUrl: (rawFirstPhoto != null && rawFirstPhoto.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawFirstPhoto' : null,
      pets: petsJson.map((p) => SchedulePet.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}

class SitterCalenderController {
  Future<List<ScheduleBooking>> fetchMySchedule() async {
    try {
      final response = await ApiService.get('/bookings/my-schedule', token: AuthSession.token);
      if (response.statusCode != 200) return [];
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = data['bookings'] as List<dynamic>;
      return list.map((e) => ScheduleBooking.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}