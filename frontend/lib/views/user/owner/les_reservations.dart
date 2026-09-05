import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../controllers/les_reservations_controller.dart';
import '../../../widgets/pet_avatars_stack.dart';
import 'booking_details.dart';
import '../../../models/sitter_service_catalog.dart';

// ============================================================================
// LesReservationsScreen ("Bookings") - owner
// ============================================================================
// 🔵 Wsulha mel sidebar (owner, item "Bookings") - GET /api/bookings/mine
// (data 7a9i9iya, mch mock). Twarri kol el bookings mte3 el owner: elli
// mazelin "en attente" (pending), elli "accepted" (mfarr9in l'2: confirmed
// lowkan checkOut mazel jaya, completed lowkan 3addat), w elli "refusée"
// (rejected) - chrahtha fel controller (les_reservations_controller.dart,
// OwnerBooking.displayStatus).
// ============================================================================
class LesReservationsScreen extends StatefulWidget {
  const LesReservationsScreen({super.key});

  @override
  State<LesReservationsScreen> createState() => _LesReservationsScreenState();
}

class _LesReservationsScreenState extends State<LesReservationsScreen> {
  final LesReservationsController _controller = LesReservationsController();
  List<OwnerBooking> _bookings = [];
  bool _isLoading = true;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  // 🔴 FIX (kifma tlab: "les services nhbhom fi des titre...") -
  // sitterServiceLabelKeys mel catalogue partagé (bدal liste mkarrra).
  static Map<String, String> get _serviceLabelKeys => sitterServiceLabelKeys;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final bookings = await _controller.fetchMyBookings();
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _isLoading = false;
    });
  }

  String _serviceLabel(String serviceId) {
    final key = _serviceLabelKeys[serviceId];
    return key != null ? key.tr() : serviceId;
  }

  // 🔵 lowkan fama service wa7ed wla ktar (el owner ynajjam ye5tar
  // ktar mel booking wa7ed, chrahtha request_a_book.dart) - njam3ouhom
  // b " + " (mathalan "Dog Walking + Boarding").
  String _titleFor(OwnerBooking booking) {
    if (booking.serviceIds.isEmpty) return '-';
    return booking.serviceIds.map(_serviceLabel).join(' + ');
  }

  // 🔵 ZID (fix timezone): ".toLocal()" 9bal .day/.month/.year.
  String _dateRangeLabel(DateTime checkInRaw, DateTime checkOutRaw) {
    final checkIn = checkInRaw.toLocal();
    final checkOut = checkOutRaw.toLocal();
    final bool sameDay = checkIn.year == checkOut.year && checkIn.month == checkOut.month && checkIn.day == checkOut.day;
    if (sameDay) return '${checkIn.day} ${_monthNames[checkIn.month - 1]}';

    final bool sameMonth = checkIn.year == checkOut.year && checkIn.month == checkOut.month;
    if (sameMonth) return '${checkIn.day} - ${checkOut.day} ${_monthNames[checkIn.month - 1]}';

    return '${checkIn.day} ${_monthNames[checkIn.month - 1]} - ${checkOut.day} ${_monthNames[checkOut.month - 1]}';
  }

  // 🔵 format 24h (kifma tlab fel request_a_book.dart) - bla AM/PM.
  // 🔵 ZID (fix timezone): ".toLocal()" 9bal .hour/.minute.
  String _timeLabel(DateTime time) {
    final local = time.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(OwnerBookingStatus status) {
    switch (status) {
      case OwnerBookingStatus.pending:
        return 'booking_status_pending'.tr();
      // 🔴 FIX (bug: sitter details "yetfeskho" - kanet mkhaltha m3a
      // "pending", tawa 3andha badge 5ass, mch mkhalltin m3a "pending").
      case OwnerBookingStatus.searching:
        return 'booking_status_searching'.tr();
      case OwnerBookingStatus.awaitingConfirmation:
        return 'booking_status_awaiting_confirmation'.tr();
      case OwnerBookingStatus.confirmed:
        return 'booking_status_confirmed'.tr();
      case OwnerBookingStatus.completed:
        return 'booking_status_completed'.tr();
      case OwnerBookingStatus.rejected:
        return 'booking_status_rejected'.tr();
    }
  }

  Color _statusColor(OwnerBookingStatus status) {
    switch (status) {
      case OwnerBookingStatus.pending:
        return const Color(0xFFFFA726); // orange
      case OwnerBookingStatus.searching:
        return const Color(0xFF29B6F6); // bleu (recherche en cours)
      case OwnerBookingStatus.awaitingConfirmation:
        return const Color(0xFF9575CD); // violet (action requise)
      case OwnerBookingStatus.confirmed:
        return AppColors.vertpetsy; // vert
      case OwnerBookingStatus.completed:
        return AppColors.pinkpetsy; // rose
      case OwnerBookingStatus.rejected:
        return AppColors.error; // rouge
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

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
                      padding: EdgeInsets.symmetric(horizontal: sizes.bookingHorizontalPadding),
                      children: [
                        SizedBox(height: sizes.bookingTopGap),
                        Center(
                          child: Text('my_bookings_title'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileNameFontSize)),
                        ),
                        SizedBox(height: sizes.myProfileSectionGap),

                        if (_bookings.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.15),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.event_note_outlined, color: mutedTextColor.withOpacity(0.5), size: sizes.bookingEmptyStateIcon),
                                  SizedBox(height: sizes.screenHeight * 0.015),
                                  Text('no_bookings_yet_label'.tr(), style: TextStyle(color: mutedTextColor)),
                                ],
                              ),
                            ),
                          )
                        else
                          for (final booking in _bookings) ...[
                            _bookingCard(sizes: sizes, booking: booking, mutedTextColor: mutedTextColor),
                            SizedBox(height: sizes.bookingSectionGap),
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

  Widget _bookingCard({required AppSizes sizes, required OwnerBooking booking, required Color mutedTextColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final status = booking.displayStatus;
    final petNames = booking.pets.map((p) => p.name).join(', ');

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => BookingDetailsScreen(booking: booking)),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
      padding: EdgeInsets.all(sizes.bookingCardPadding),
      decoration: BoxDecoration(
        color: isDark ? AppColors.vertpetsy.withOpacity(0.10) : AppColors.vertpetsy.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // el 3onwan (service(s)) + status pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  _titleFor(booking),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.028, vertical: sizes.screenHeight * 0.006),
                decoration: BoxDecoration(color: _statusColor(status), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: sizes.bookingPillFont),
                ),
              ),
            ],
          ),
          SizedBox(height: sizes.screenHeight * 0.01),

          // dates + wa9t
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: sizes.myProfileBodyFontSize * 0.75, color: mutedTextColor),
              SizedBox(width: sizes.screenWidth * 0.015),
              Text(_dateRangeLabel(booking.checkIn, booking.checkOut), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.8, color: mutedTextColor)),
              SizedBox(width: sizes.screenWidth * 0.035),
              Icon(Icons.access_time, size: sizes.myProfileBodyFontSize * 0.75, color: mutedTextColor),
              SizedBox(width: sizes.screenWidth * 0.015),
              Text('${_timeLabel(booking.checkIn)} - ${_timeLabel(booking.checkOut)}', style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.8, color: mutedTextColor)),
            ],
          ),
          SizedBox(height: sizes.screenHeight * 0.014),

          // pet(s)
          Row(
            children: [
              PetAvatarsStack(photoUrls: booking.pets.map((p) => p.photoUrl).toList(), avatarSize: sizes.bookingAvatarSize),
              SizedBox(width: sizes.screenWidth * 0.03),
              Expanded(
                child: Text(petNames.isEmpty ? '-' : petNames, style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.9, fontWeight: FontWeight.w600)),
              ),
            ],
          ),

          SizedBox(height: sizes.screenHeight * 0.014),
          Divider(color: mutedTextColor.withOpacity(0.2), height: 1),
          SizedBox(height: sizes.screenHeight * 0.014),

          // sitter + total
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(sizes.bookingAvatarSize / 2),
                child: Container(
                  width: sizes.bookingAvatarSize,
                  height: sizes.bookingAvatarSize,
                  color: AppColors.pinkpetsy.withOpacity(0.18),
                  child: booking.sitterPhotoUrl != null
                      ? Image.network(booking.sitterPhotoUrl!, fit: BoxFit.cover)
                      : Icon(Icons.person, color: AppColors.pinkpetsy, size: sizes.bookingAvatarSize * 0.55),
                ),
              ),
              SizedBox(width: sizes.screenWidth * 0.03),
              Expanded(
                child: Text(booking.sitterName, style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.9, fontWeight: FontWeight.w600)),
              ),
              Text('${booking.total.toStringAsFixed(0)} DT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9)),
            ],
          ),
        ],
      ),
      ),
    );
  }
}