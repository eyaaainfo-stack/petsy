import '../services/api_service.dart';

// ============================================================================
// NotificationItem
// ============================================================================
class NotificationItem {
  final String id;
  final String message;
  final String type; // 'booking_sent' / 'booking_received' / 'booking_accepted' / 'booking_rejected' / 'candidate_accepted' / 'candidate_declined' / 'message' / 'location_shared' / 'other'
  final bool isRead;
  final DateTime createdAt;
  // 🔵 ZID (kifma tlab: request.dart, workflow reject/broadcast/candidate)
  final String? relatedBooking;
  final bool isActioned;
  // 🔵 ZID (feature "notification -> conversation direct"): type
  // "message" - bch nnajmou nefta7ou ChatScreen DIRECT (bla recherche).
  final String? relatedConversation;
  final String? relatedSenderId;
  final String? relatedSenderName;
  final String? relatedSenderPhotoUrl;

  const NotificationItem({
    required this.id,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedBooking,
    this.isActioned = false,
    this.relatedConversation,
    this.relatedSenderId,
    this.relatedSenderName,
    this.relatedSenderPhotoUrl,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    // 🔵 "relatedSender" populé (backend: .populate('relatedSender', ...))
    // -> jeya kifma Map ({_id, fullName, photoUrl}), MAHOUCH bark ID
    // (string) - lowkan null wla mch populé, nkhalliw kolchay null.
    final dynamic rawSender = json['relatedSender'];
    final Map<String, dynamic>? sender = rawSender is Map<String, dynamic> ? rawSender : null;
    final String? senderPhotoRaw = sender?['photoUrl'] as String?;

    return NotificationItem(
      id: json['_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'other',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      relatedBooking: json['relatedBooking'] as String?,
      isActioned: json['isActioned'] as bool? ?? false,
      relatedConversation: json['relatedConversation'] as String?,
      relatedSenderId: sender?['_id'] as String?,
      relatedSenderName: sender?['fullName'] as String?,
      relatedSenderPhotoUrl: (senderPhotoRaw != null && senderPhotoRaw.isNotEmpty) ? '${ApiService.mediaBaseUrl}$senderPhotoRaw' : null,
    );
  }
}