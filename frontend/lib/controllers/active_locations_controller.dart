import 'dart:convert';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// ActiveSitterLocation (feature "partage de localisation")
// ============================================================================
// 🔵 ZID: un item par booking actif ou el sitter 9bel ychourek sa
// position (fixe, mel profil - "location" fel User) - jaya mel
// endpoint GET /bookings/active-locations (bookingController.js).
// Query DYNAMIQUE côté backend (mch snapshot mahfoudh) - kol item
// houni ye5tafi wa7dou (backend ma yrajja3hach) ken el booking
// yetsakker (checkout confirmé men zouz el jihat, wla "service pas
// fait") - ma tsayer ay "suppression" manuelle houni.
// ============================================================================
class ActiveSitterLocation {
  final String bookingId;
  final String sitterId;
  final String sitterName;
  final String? sitterPhotoUrl;
  final String sitterLocationName;
  final double lat;
  final double lng;
  final DateTime checkIn;
  final DateTime checkOut;

  const ActiveSitterLocation({
    required this.bookingId,
    required this.sitterId,
    required this.sitterName,
    this.sitterPhotoUrl,
    required this.sitterLocationName,
    required this.lat,
    required this.lng,
    required this.checkIn,
    required this.checkOut,
  });

  factory ActiveSitterLocation.fromJson(Map<String, dynamic> json) {
    final String? rawPhotoUrl = json['sitterPhotoUrl'] as String?;
    final Map<String, dynamic> loc = json['location'] as Map<String, dynamic>? ?? const {};
    return ActiveSitterLocation(
      bookingId: json['bookingId'] as String? ?? '',
      sitterId: json['sitterId'] as String? ?? '',
      sitterName: json['sitterName'] as String? ?? '',
      sitterPhotoUrl: (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawPhotoUrl' : null,
      sitterLocationName: json['sitterLocationName'] as String? ?? '',
      lat: (loc['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (loc['lng'] as num?)?.toDouble() ?? 0.0,
      checkIn: DateTime.tryParse(json['checkIn'] as String? ?? '') ?? DateTime.now(),
      checkOut: DateTime.tryParse(json['checkOut'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class ActiveLocationsController {
  Future<List<ActiveSitterLocation>> fetchActiveLocations() async {
    try {
      final response = await ApiService.get('/bookings/active-locations', token: AuthSession.token);
      if (response.statusCode != 200) return [];
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> raw = data['locations'] as List<dynamic>? ?? [];
      return raw.map((e) => ActiveSitterLocation.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}