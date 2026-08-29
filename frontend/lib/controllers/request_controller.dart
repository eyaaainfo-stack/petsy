import 'dart:convert';
import '../services/api_service.dart';
import 'auth_session.dart';
import '../models/pet_summary.dart';

// ============================================================================
// RequestPersonInfo (owner wla sitter - esm+photo+ville, kifha kif
// yban f'request.dart)
// ============================================================================
class RequestPersonInfo {
  final String id;
  final String fullName;
  final String? photoUrl;
  final String? city;
  final String? phone;

  const RequestPersonInfo({required this.id, required this.fullName, this.photoUrl, this.city, this.phone});

  factory RequestPersonInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RequestPersonInfo(id: '', fullName: '');
    final String? rawPhotoUrl = json['photoUrl'] as String?;
    return RequestPersonInfo(
      id: json['_id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      photoUrl: (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawPhotoUrl' : null,
      city: json['city'] as String?,
      phone: json['phone'] as String?,
    );
  }
}

// ============================================================================
// BookingRequestDetail (request.dart - "Request Details")
// ============================================================================
// 🔵 status: 'pending' / 'accepted' / 'rejected' / 'open' / 'awaiting_confirmation'
// (chrahtha fel backend, models/booking.js).
// ============================================================================
class BookingRequestDetail {
  final String id;
  final String status;
  final List<String> serviceIds;
  final DateTime checkIn;
  final DateTime checkOut;
  final double total;
  final RequestPersonInfo owner;
  final RequestPersonInfo? sitter;
  final List<PetSummary> pets;

  const BookingRequestDetail({
    required this.id,
    required this.status,
    required this.serviceIds,
    required this.checkIn,
    required this.checkOut,
    required this.total,
    required this.owner,
    this.sitter,
    required this.pets,
  });

  factory BookingRequestDetail.fromJson(Map<String, dynamic> json) {
    final List<dynamic> petsJson = json['pets'] as List<dynamic>? ?? [];
    final List<dynamic> servicesJson = json['services'] as List<dynamic>? ?? [];

    return BookingRequestDetail(
      id: json['_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      serviceIds: servicesJson.map((s) => (s as Map<String, dynamic>)['serviceId'] as String? ?? '').toList(),
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: DateTime.parse(json['checkOut'] as String),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      owner: RequestPersonInfo.fromJson(json['owner'] as Map<String, dynamic>?),
      sitter: json['sitter'] != null ? RequestPersonInfo.fromJson(json['sitter'] as Map<String, dynamic>) : null,
      pets: petsJson.map((p) {
        final Map<String, dynamic> m = p as Map<String, dynamic>;
        final String? rawPhotoUrl = m['photoUrl'] as String?;
        return PetSummary(
          id: m['_id'] as String?,
          name: m['name'] as String? ?? '',
          petType: m['petType'] as String? ?? 'dog',
          photoUrl: (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawPhotoUrl' : null,
          age: m['age']?.toString(),
          breed: m['breed'] as String?,
          size: m['size']?.toString(),
          gender: m['gender'] as String?,
          behaviors: (m['behaviors'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          careInfo: (m['careInfo'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v == true)) ?? {},
          vetClinicName: m['vetClinicName'] as String?,
          vetClinicPhone: m['vetClinicPhone'] as String?,
        );
      }).toList(),
    );
  }
}

class RequestController {
  Future<BookingRequestDetail?> fetchBooking(String bookingId) async {
    try {
      final response = await ApiService.get('/bookings/$bookingId', token: AuthSession.token);
      if (response.statusCode != 200) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return BookingRequestDetail.fromJson(data['booking'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // 🔵 sitter: accept/reject - te5dem l'zoùj 7alet (talab direct
  // "pending", wala "open" marketplace kandidature) - el backend
  // yfarra9 (chrahtha bookingController.js).
  Future<bool> respond(String bookingId, {required bool accept}) async {
    try {
      final response = await ApiService.patch(
        '/bookings/$bookingId/respond',
        {'action': accept ? 'accept' : 'reject'},
        token: AuthSession.token,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 🔵 owner: "Yes" fel notification "booking_rejected" - ye5tar
  // y-rebroadcast lel sitters okhrin.
  Future<bool> broadcast(String bookingId) async {
    try {
      final response = await ApiService.patch('/bookings/$bookingId/broadcast', {}, token: AuthSession.token);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 🔵 owner: Accept/Decline fel notification "candidate_accepted".
  Future<bool> confirmCandidate(String bookingId, {required bool accept}) async {
    try {
      final response = await ApiService.patch(
        '/bookings/$bookingId/confirm-candidate',
        {'accept': accept},
        token: AuthSession.token,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // 🔵 ZID (kifma tlab): sitter ye5tar "Cancel Booking" mel calendrier
  // (booking déjà "accepted") - twalli "rejected" + notification
  // actionable l'owner (nafs mant9 el reject el direct, "tebaathha
  // l sitters okhrin?").
  Future<bool> cancelBooking(String bookingId) async {
    try {
      final response = await ApiService.patch('/bookings/$bookingId/cancel', {}, token: AuthSession.token);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}

// ============================================================================
// UrgentBookingSummary (sitter_profile.dart - "Need urgent sitting
// services", card mdhghouta - mch el détails el kamel)
// ============================================================================
class UrgentBookingSummary {
  final String id;
  final List<String> serviceIds;
  final DateTime checkIn;
  final DateTime checkOut;
  final String petNames;
  final String? firstPetPhotoUrl;
  final double? distanceKm;

  const UrgentBookingSummary({
    required this.id,
    required this.serviceIds,
    required this.checkIn,
    required this.checkOut,
    required this.petNames,
    this.firstPetPhotoUrl,
    this.distanceKm,
  });

  factory UrgentBookingSummary.fromJson(Map<String, dynamic> json) {
    final List<dynamic> petsJson = json['pets'] as List<dynamic>? ?? [];
    final List<dynamic> servicesJson = json['services'] as List<dynamic>? ?? [];
    final String? rawFirstPhoto = petsJson.isNotEmpty ? (petsJson.first as Map<String, dynamic>)['photoUrl'] as String? : null;

    return UrgentBookingSummary(
      id: json['_id'] as String? ?? '',
      serviceIds: servicesJson.map((s) => (s as Map<String, dynamic>)['serviceId'] as String? ?? '').toList(),
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: DateTime.parse(json['checkOut'] as String),
      petNames: petsJson.map((p) => (p as Map<String, dynamic>)['name'] as String? ?? '').join(', '),
      firstPetPhotoUrl: (rawFirstPhoto != null && rawFirstPhoto.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawFirstPhoto' : null,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}

class UrgentRequestsController {
  Future<List<UrgentBookingSummary>> fetchUrgentRequests() async {
    try {
      final response = await ApiService.get('/bookings/urgent', token: AuthSession.token);
      if (response.statusCode != 200) return [];
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = data['bookings'] as List<dynamic>;
      return list.map((e) => UrgentBookingSummary.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}