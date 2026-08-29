import 'dart:convert';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// BookedPet (pet sghir - esm+photo bark, kifma yban fel card)
// ============================================================================
class BookedPet {
  final String name;
  final String? photoUrl;

  const BookedPet({required this.name, this.photoUrl});

  factory BookedPet.fromJson(Map<String, dynamic> json) {
    final String? rawPhotoUrl = json['photoUrl'] as String?;
    return BookedPet(
      name: json['name'] as String? ?? '',
      photoUrl: (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawPhotoUrl' : null,
    );
  }
}

// ============================================================================
// OwnerBooking (booking kifma yban fel owner side - les_reservations.dart)
// ============================================================================
// 🔵 status mel backend: 'pending' / 'accepted' / 'rejected' bark
// (chrahtha models/booking.js). "Confirmed" vs "Completed" (mockup)
// mch 2 statuses mnfaslin fel database - houma NAFS "accepted", el
// farq bark: checkOut 3adda (fel me'di) wla le. Fa n7esbouha houni
// (derived), mch el backend (bla ma nzidou status jdid l'ghir data).
// ============================================================================
enum OwnerBookingStatus { pending, confirmed, completed, rejected }

class OwnerBooking {
  final String id;
  final List<String> serviceIds;
  final DateTime checkIn;
  final DateTime checkOut;
  final double total;
  final String rawStatus;
  final String sitterId;
  final String sitterName;
  final String? sitterPhotoUrl;
  final String sitterCity;
  final String sitterPhone;
  final List<BookedPet> pets;
  final double? distanceKm;

  const OwnerBooking({
    required this.id,
    required this.serviceIds,
    required this.checkIn,
    required this.checkOut,
    required this.total,
    required this.rawStatus,
    required this.sitterId,
    required this.sitterName,
    this.sitterPhotoUrl,
    required this.sitterCity,
    required this.sitterPhone,
    required this.pets,
    this.distanceKm,
  });

  // 🔵 el status "affiché" (4 etats, kifma el mockup) - derived mel
  // rawStatus + checkOut (chrahtha fou9).
  OwnerBookingStatus get displayStatus {
    switch (rawStatus) {
      case 'rejected':
        return OwnerBookingStatus.rejected;
      case 'accepted':
        return DateTime.now().isAfter(checkOut) ? OwnerBookingStatus.completed : OwnerBookingStatus.confirmed;
      case 'pending':
      default:
        return OwnerBookingStatus.pending;
    }
  }

  factory OwnerBooking.fromJson(Map<String, dynamic> json) {
    final String rawStatus = json['status'] as String? ?? 'pending';
    // 🔵 ZID (kifma tlab): ki el booking "awaiting_confirmation" (candidate
    // sitter jdid 9bel mel "urgent" marketplace) - "sitter" mazel null
    // (mch mfassal 7atta l'hin), el info el 7a9i9iya elli el owner
    // lezmou ychoufha (esm/photo/ville/phone) mawjouda fel
    // "pendingCandidateSitter". Fa n5tarou mnin njibou el info: candidate
    // lowkan "awaiting_confirmation", wela "sitter" el 3adi (el ba9i el
    // 7alet).
    final bool useCandidate = rawStatus == 'awaiting_confirmation';
    final Map<String, dynamic>? effectiveSitterJson =
        useCandidate ? (json['pendingCandidateSitter'] as Map<String, dynamic>?) : (json['sitter'] as Map<String, dynamic>?);
    final String? rawSitterPhotoUrl = effectiveSitterJson?['photoUrl'] as String?;
    final List<dynamic> servicesJson = json['services'] as List<dynamic>? ?? [];
    final List<dynamic> petsJson = json['pets'] as List<dynamic>? ?? [];

    return OwnerBooking(
      id: json['_id'] as String? ?? '',
      serviceIds: servicesJson.map((s) => (s as Map<String, dynamic>)['serviceId'] as String? ?? '').toList(),
      checkIn: DateTime.parse(json['checkIn'] as String),
      checkOut: DateTime.parse(json['checkOut'] as String),
      total: (json['total'] as num?)?.toDouble() ?? 0,
      rawStatus: rawStatus,
      sitterId: effectiveSitterJson?['_id'] as String? ?? '',
      sitterName: effectiveSitterJson?['fullName'] as String? ?? '',
      sitterPhotoUrl: (rawSitterPhotoUrl != null && rawSitterPhotoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawSitterPhotoUrl' : null,
      sitterCity: effectiveSitterJson?['city'] as String? ?? '',
      sitterPhone: effectiveSitterJson?['phone'] as String? ?? '',
      pets: petsJson.map((p) => BookedPet.fromJson(p as Map<String, dynamic>)).toList(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}

class LesReservationsController {
  Future<List<OwnerBooking>> fetchMyBookings() async {
    try {
      final response = await ApiService.get('/bookings/mine', token: AuthSession.token);
      if (response.statusCode != 200) return [];
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = data['bookings'] as List<dynamic>;
      return list.map((e) => OwnerBooking.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // 🔵 ZID (kifma tlab): dass 3al notification "candidate_accepted" ->
  // booking_details.dart direct (bla ma nestannew el liste el kaملha,
  // GET /bookings/:id bark - nafs endpoint elli request.dart testa3melha,
  // el owner ynajjam ychoufha zeda, chrahtha getBookingById).
  Future<OwnerBooking?> fetchBookingById(String bookingId) async {
    try {
      final response = await ApiService.get('/bookings/$bookingId', token: AuthSession.token);
      if (response.statusCode != 200) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return OwnerBooking.fromJson(data['booking'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}