// ============================================================================
// NotificationItem
// ============================================================================
class NotificationItem {
  final String id;
  final String message;
  final String type; // 'booking_sent' / 'booking_received' / 'booking_accepted' / 'booking_rejected' / 'candidate_accepted' / 'candidate_declined' / 'message' / 'other'
  final bool isRead;
  final DateTime createdAt;
  // 🔵 ZID (kifma tlab: request.dart, workflow reject/broadcast/candidate)
  final String? relatedBooking;
  final bool isActioned;

  const NotificationItem({
    required this.id,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.relatedBooking,
    this.isActioned = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['_id'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'other',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      relatedBooking: json['relatedBooking'] as String?,
      isActioned: json['isActioned'] as bool? ?? false,
    );
  }
}