import 'dart:convert';
import '../models/notification_item.dart';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// NotificationController
// ============================================================================
class NotificationController {
  Future<List<NotificationItem>> fetchMyNotifications() async {
    try {
      final response = await ApiService.get('/bookings/notifications', token: AuthSession.token);
      if (response.statusCode != 200) return [];

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> list = data['notifications'] as List<dynamic>;
      return list.map((e) => NotificationItem.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> fetchUnreadCount() async {
    try {
      final response = await ApiService.get('/bookings/notifications/unread-count', token: AuthSession.token);
      if (response.statusCode != 200) return 0;

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.patch('/bookings/notifications/mark-read', {}, token: AuthSession.token);
    } catch (_) {
      // silent - mch critique, badge bark ynajjam ma yetmasso7ch
    }
  }

  // 🔵 ZID (kifma tlab): bouton "No" (booking_rejected) - el notification
  // ma tban-ch mrra thenya b'el bottons, bla ma nbeddlou 7ata 7aja
  // fel booking.
  Future<bool> dismissNotification(String notificationId) async {
    try {
      final response = await ApiService.patch('/bookings/notifications/$notificationId/dismiss', {}, token: AuthSession.token);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}