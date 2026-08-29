import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/back_button.dart';
import '../../controllers/notification_controller.dart';
import '../../controllers/request_controller.dart';
import '../../models/notification_item.dart';
import '../../controllers/les_reservations_controller.dart';
import '../../controllers/auth_session.dart';
import 'sitter/request.dart';
import 'owner/booking_details.dart';

// ============================================================================
// NotificationsScreen ("Notifications")
// ============================================================================
// 🔵 Wsulha mel sidebar (owner/sitter, item "Notifications") wla mel
// bell icon (fel home) - GET /api/bookings/notifications. Ki tefte7,
// t3amel "mark all as read" automatique (bch el badge/no9ta 7amra
// tzoul mel home mel marra el jaya).
// ============================================================================
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationController _controller = NotificationController();
  final RequestController _requestController = RequestController();
  final LesReservationsController _reservationsController = LesReservationsController();
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  // 🔵 ZID (kifma tlab): bch ne5fiw les bottons "Yes/No" mel notification
  // direct (bla ma nestanniw refetch) ki el user y-taper 3lihom.
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final notifications = await _controller.fetchMyNotifications();
    if (!mounted) return;
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
    // 🔵 mark-as-read GHIR ba3d ma el liste tban (bla ma ne5deroha) -
    // el badge fel home ye5taفi mel marra el jaya elli el user yefte7
    // el app/écran hedha.
    _controller.markAllAsRead();
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'booking_accepted':
        return Icons.check;
      case 'booking_sent':
      case 'booking_received':
        return Icons.help_outline;
      case 'booking_rejected':
        return Icons.close;
      case 'candidate_accepted':
        return Icons.person_add_alt;
      case 'candidate_declined':
        return Icons.info_outline;
      case 'message':
        return Icons.chat_bubble_outline;
      default:
        return Icons.notifications_none;
    }
  }

  // 🔵 el notification "actionable" (bottons Yes/No) MOJOUDA GHIR ken:
  // el type munasib, mafamech relatedBooking, W mazel ma "actioned"ch.
  bool _isActionable(NotificationItem item) {
    return (item.type == 'booking_rejected' || item.type == 'candidate_accepted') && item.relatedBooking != null && !item.isActioned;
  }

  void _markActioned(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final n = _notifications[index];
        _notifications[index] = NotificationItem(
          id: n.id,
          message: n.message,
          type: n.type,
          isRead: n.isRead,
          createdAt: n.createdAt,
          relatedBooking: n.relatedBooking,
          isActioned: true,
        );
      }
      _processingIds.remove(id);
    });
  }

  Future<void> _onBroadcastAnswer(NotificationItem item, bool yes) async {
    if (_processingIds.contains(item.id)) return;
    setState(() => _processingIds.add(item.id));
    final bool ok = yes ? await _requestController.broadcast(item.relatedBooking!) : await _controller.dismissNotification(item.id);
    if (!mounted) return;
    if (!ok) {
      setState(() => _processingIds.remove(item.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_submit_error'.tr())));
      return;
    }
    _markActioned(item.id);
  }

  Future<void> _onCandidateAnswer(NotificationItem item, bool accept) async {
    if (_processingIds.contains(item.id)) return;
    setState(() => _processingIds.add(item.id));
    final bool ok = await _requestController.confirmCandidate(item.relatedBooking!, accept: accept);
    if (!mounted) return;
    if (!ok) {
      setState(() => _processingIds.remove(item.id));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_submit_error'.tr())));
      return;
    }
    _markActioned(item.id);
  }

  // 🔵 ZID (kifma tlab): dass 3al notification "booking_received"
  // (talab jdid, l'sitter) -> yeftah request.dart direct.
  // 🔵 ZID zeda: dass 3al "candidate_accepted" (l'owner - sitter jdid
  // 9bel mel "urgent") -> yeftah booking_details.dart, m3a info el
  // sitter EL JDID (mch el asli elli rafedh) w total m7esseb 3ala
  // 9adou (chrahtha getBookingById/respondToBooking, backend).
  // 🔵 ZID zeda: dass 3al "booking_accepted" - hedha type ynajjam
  // yousel l'ZOUJ (owner: "el sitter 9bel talabek", WALA sitter:
  // "l'offre tou3ek t9eblet") - fa n5tarou el écran 7asb "role" (mch
  // 7asb el type bark): sitter -> request.dart (status déjà "accepted",
  // el bottons Accept/Reject ye5tafou automatique, "mnghir boutonet"
  // kifma tlab), owner -> booking_details.dart.
  Future<void> _onNotificationTap(NotificationItem item) async {
    if (item.relatedBooking == null) return;

    if (item.type == 'booking_received') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RequestScreen(bookingId: item.relatedBooking!)),
      );
      return;
    }

    if (item.type == 'booking_accepted' && AuthSession.userRole == 'sitter') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => RequestScreen(bookingId: item.relatedBooking!)),
      );
      return;
    }

    if (item.type == 'candidate_accepted' || (item.type == 'booking_accepted' && AuthSession.userRole == 'owner')) {
      await _openOwnerBookingDetails(item.relatedBooking!);
    }
  }

  Future<void> _openOwnerBookingDetails(String bookingId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final booking = await _reservationsController.fetchBookingById(bookingId);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // yghaleg el loading dialog

    if (booking == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_submit_error'.tr())));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BookingDetailsScreen(booking: booking)),
    );
  }

  String _relativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'just_now_label'.tr();
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} d';
  }

  String _groupLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diffDays = today.difference(date).inDays;

    if (diffDays == 0) return 'today_label'.tr();
    if (diffDays == 1) return 'yesterday_label'.tr();
    // 🔵 esm el nhar (Monday...) kifma el mockup, lel notifications
    // el a9dam mel yesterday (bla ma nzid package "intl" zeyed).
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[dateTime.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    // 🔵 njamm3ou el notifications 7asb "el nhar" (Today/Yesterday/...)
    // - LinkedHashMap bch el tertib ye5dem (el a9rab awalan, mel backend
    // déjà sorted createdAt: -1).
    final Map<String, List<NotificationItem>> grouped = {};
    for (final notif in _notifications) {
      final label = _groupLabel(notif.createdAt);
      grouped.putIfAbsent(label, () => []).add(notif);
    }

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              color: AppColors.pinkpetsy,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: EdgeInsets.symmetric(horizontal: sizes.notifHorizontalPadding),
                      children: [
                        SizedBox(height: sizes.notifTopGap),
                        Center(
                          child: Text('notifications_label'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileNameFontSize)),
                        ),
                        SizedBox(height: sizes.notifSectionGap),

                        if (_notifications.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.15),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.notifications_none, color: mutedTextColor.withOpacity(0.5), size: sizes.notifEmptyStateIcon),
                                  SizedBox(height: sizes.screenHeight * 0.015),
                                  Text('no_notifications_yet_label'.tr(), style: TextStyle(color: mutedTextColor)),
                                ],
                              ),
                            ),
                          )
                        else
                          for (final entry in grouped.entries) ...[
                            Text(entry.key, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                            SizedBox(height: sizes.notifSectionGap * 0.5),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.pinkpetsy.withOpacity(0.3)),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  for (int i = 0; i < entry.value.length; i++) ...[
                                    _notificationRow(sizes: sizes, item: entry.value[i], mutedTextColor: mutedTextColor),
                                    if (i != entry.value.length - 1) Divider(color: AppColors.pinkpetsy.withOpacity(0.15), height: 1),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(height: sizes.notifSectionGap),
                          ],

                        SizedBox(height: sizes.myProfileBottomGap),
                      ],
                    ),
            ),

            const CustomBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _notificationRow({required AppSizes sizes, required NotificationItem item, required Color mutedTextColor}) {
    final bool isProcessing = _processingIds.contains(item.id);
    final bool actionable = _isActionable(item);
    final bool isBroadcastPrompt = item.type == 'booking_rejected';

    return InkWell(
      onTap: () => _onNotificationTap(item),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.012),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: sizes.notifIconSize,
              height: sizes.notifIconSize,
              decoration: BoxDecoration(color: AppColors.vertpetsy, borderRadius: BorderRadius.circular(10)),
              child: Icon(_iconForType(item.type), color: Colors.white, size: sizes.notifIconSize * 0.55),
            ),
            SizedBox(width: sizes.screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.message, style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.9, height: 1.3)),
                  SizedBox(height: sizes.screenHeight * 0.004),
                  Text(_relativeTime(item.createdAt), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.7, color: mutedTextColor)),

                  // 🔵 ZID (kifma tlab): bottons Yes/No (broadcast) wela
                  // Accept/Decline (candidate) - direct fel notification,
                  // bla écran mnfassel.
                  if (actionable) ...[
                    SizedBox(height: sizes.screenHeight * 0.01),
                    Row(
                      children: [
                        _notifActionButton(
                          sizes: sizes,
                          label: isBroadcastPrompt ? 'yes_label'.tr() : 'accept_button'.tr(),
                          color: AppColors.vertpetsy,
                          isLoading: isProcessing,
                          onTap: () => isBroadcastPrompt ? _onBroadcastAnswer(item, true) : _onCandidateAnswer(item, true),
                        ),
                        SizedBox(width: sizes.screenWidth * 0.02),
                        _notifActionButton(
                          sizes: sizes,
                          label: isBroadcastPrompt ? 'no_label'.tr() : 'reject_button'.tr(),
                          color: AppColors.pinkpetsy,
                          isLoading: isProcessing,
                          onTap: () => isBroadcastPrompt ? _onBroadcastAnswer(item, false) : _onCandidateAnswer(item, false),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notifActionButton({required AppSizes sizes, required String label, required Color color, required bool isLoading, required VoidCallback onTap}) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: isLoading ? 0.5 : 1,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.035, vertical: sizes.screenHeight * 0.008),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
          child: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: sizes.myProfileBodyFontSize * 0.75)),
        ),
      ),
    );
  }
}