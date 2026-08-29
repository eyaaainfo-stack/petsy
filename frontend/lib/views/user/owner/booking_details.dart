import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../controllers/les_reservations_controller.dart';
import '../../../controllers/request_controller.dart';
import '../../../widgets/pet_avatars_stack.dart';
import '../sitter/view_profile_sitter.dart';

// ============================================================================
// BookingDetailsScreen ("Bookings Details") - owner
// ============================================================================
// 🔵 Wsulha mel les_reservations.dart (dass 3al card) WALA mel
// notification "candidate_accepted" (notifications_screen.dart) - el
// OwnerBooking yjini mel constructeur (bla appel API zeyed, nafs mant9
// pet_profile.dart - el data déjà 3andna).
//
// 🔴 FIX (kifma tlab): naحّيna KAMEL el partie "paiement en ligne"
// (carte bancaire "**** 49") - MECH mawjouda el kol houni, w blastha
// n7ottou num tel sitter (phone 7a9i9i mel backend, mch tel owner).
//
// 🔵 rating/reviews tel sitter: MECH mawjoudin houni b'9asd - mafamech
// système reviews 7a9i9i mrakez fel backend l'hin (chrahtha view_
// profile_sitter.dart, "Reviews (0)" dima) - bch ma nwarrouch chiffre
// fake (mathalan "4.8 - 25 Reviews" mel mockup).
//
// 🔴 FIX (kifma tlab): "Rate {sitter}" -> "View sitter's profile"
// (ViewProfileSitterScreen). W lowkan el booking "awaiting_confirmation"
// (candidate sitter jdid 9bel mel "urgent", mestanni confirmation tel
// owner) - "Cancel Booking" yetbeddel b'ZOUJ bottons: "Accepter la
// demande" / "Refuser la demande" (PATCH /bookings/:id/confirm-candidate).
// ============================================================================
class BookingDetailsScreen extends StatefulWidget {
  final OwnerBooking booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  final RequestController _requestController = RequestController();
  bool _isResponding = false;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const Map<String, String> _serviceLabelKeys = {
    'house_sitting': 'sitter_service_house_sitting',
    'dog_walking': 'sitter_service_dog_walking',
    'doggy_day_care': 'sitter_service_doggy_day_care',
    'boarding': 'sitter_service_boarding',
    'overnight_stays': 'sitter_service_overnight_stays',
    'home_visits': 'sitter_service_home_visits',
  };

  static const Map<String, String> _serviceDescKeys = {
    'house_sitting': 'sitter_service_house_sitting_desc',
    'dog_walking': 'sitter_service_dog_walking_desc',
    'doggy_day_care': 'sitter_service_doggy_day_care_desc',
    'boarding': 'sitter_service_boarding_desc',
    'overnight_stays': 'sitter_service_overnight_stays_desc',
    'home_visits': 'sitter_service_home_visits_desc',
  };

  OwnerBooking get booking => widget.booking;

  String _serviceLabel(String serviceId) {
    final key = _serviceLabelKeys[serviceId];
    return key != null ? key.tr() : serviceId;
  }

  String get _title => booking.serviceIds.isEmpty ? '-' : booking.serviceIds.map(_serviceLabel).join(' + ');

  // 🔵 el description: tel service el LOUEL bark (lowkan fama ktar men
  // wa7ed) - kifha kif el mockup (sator wa7ed bark ta7t el 3onwan).
  String get _description {
    if (booking.serviceIds.isEmpty) return '';
    final key = _serviceDescKeys[booking.serviceIds.first];
    return key != null ? key.tr() : '';
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

  // 🔵 ZID (fix timezone): ".toLocal()" 9bal .hour/.minute.
  String _timeLabel(DateTime time) {
    final local = time.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(OwnerBookingStatus status) {
    switch (status) {
      case OwnerBookingStatus.pending:
        return 'booking_status_pending'.tr();
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
        return const Color(0xFFFFA726);
      case OwnerBookingStatus.confirmed:
        return AppColors.vertpetsy;
      case OwnerBookingStatus.completed:
        return AppColors.pinkpetsy;
      case OwnerBookingStatus.rejected:
        return AppColors.error;
    }
  }

  Future<void> _onConfirmCandidate(bool accept) async {
    if (_isResponding) return;
    setState(() => _isResponding = true);
    final success = await _requestController.confirmCandidate(booking.id, accept: accept);
    if (!mounted) return;
    setState(() => _isResponding = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('profile_submit_error'.tr())));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(accept ? 'candidate_confirmed_toast'.tr() : 'candidate_declined_toast'.tr())),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;
    final status = booking.displayStatus;
    final petNames = booking.pets.map((p) => p.name).join(', ');

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sizes.bookingHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: sizes.bookingTopGap),
                  Center(
                    child: Text('booking_details_title'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileNameFontSize)),
                  ),
                  SizedBox(height: sizes.myProfileSectionGap),

                  // ----------------------------------------------------
                  // Card: service + status + description + info rows
                  // ----------------------------------------------------
                  Container(
                    padding: EdgeInsets.all(sizes.bookingCardPadding),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.vertpetsy.withOpacity(0.10) : AppColors.vertpetsy.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(_title, style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
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
                        if (_description.isNotEmpty) ...[
                          SizedBox(height: sizes.screenHeight * 0.006),
                          Text(_description, style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85)),
                        ],
                        SizedBox(height: sizes.screenHeight * 0.02),

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
                        SizedBox(height: sizes.screenHeight * 0.016),

                        _infoRow(sizes: sizes, icon: Icons.calendar_today_outlined, text: _dateRangeLabel(booking.checkIn, booking.checkOut)),
                        SizedBox(height: sizes.screenHeight * 0.012),
                        _infoRow(sizes: sizes, icon: Icons.access_time, text: '${_timeLabel(booking.checkIn)} - ${_timeLabel(booking.checkOut)}'),
                        SizedBox(height: sizes.screenHeight * 0.012),
                        _infoRow(sizes: sizes, icon: Icons.location_on_outlined, text: booking.sitterCity.isNotEmpty ? '${booking.sitterCity} , ${'tunisia_label'.tr()}' : '-'),
                        SizedBox(height: sizes.screenHeight * 0.012),
                        _infoRow(sizes: sizes, icon: Icons.phone_outlined, text: booking.sitterPhone.isNotEmpty ? booking.sitterPhone : '-'),
                        SizedBox(height: sizes.screenHeight * 0.012),
                        _infoRow(sizes: sizes, icon: Icons.attach_money, text: 'total_amount_label'.tr(namedArgs: {'amount': booking.total.toStringAsFixed(0)})),
                      ],
                    ),
                  ),

                  SizedBox(height: sizes.bookingSectionGap * 1.4),

                  // ----------------------------------------------------
                  // Pet Sitter
                  // ----------------------------------------------------
                  Text('pet_sitter_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                  SizedBox(height: sizes.screenHeight * 0.01),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(booking.sitterName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: sizes.myProfileBodyFontSize * 0.95)),
                            if (booking.sitterCity.isNotEmpty) ...[
                              SizedBox(height: sizes.screenHeight * 0.002),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: sizes.myProfileBodyFontSize * 0.7, color: mutedTextColor),
                                  SizedBox(width: sizes.screenWidth * 0.01),
                                  Text('${booking.sitterCity} , ${'tunisia_label'.tr()}', style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.75, color: mutedTextColor)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: sizes.bookingSectionGap * 1.4),

                  // ----------------------------------------------------
                  // Message / View Profile (Message TODO - mafamech
                  // messagerie mrakza l'hin, chrahtha fou9)
                  // ----------------------------------------------------
                  Row(
                    children: [
                      Expanded(child: _actionButton(sizes: sizes, label: 'message_sitter_button'.tr(namedArgs: {'name': booking.sitterName}), color: AppColors.vertpetsy, onTap: () {})),
                      SizedBox(width: sizes.screenWidth * 0.03),
                      Expanded(
                        child: _actionButton(
                          sizes: sizes,
                          label: 'view_sitter_profile_button'.tr(),
                          color: AppColors.vertpetsy,
                          onTap: booking.sitterId.isEmpty
                              ? null
                              : () => Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => ViewProfileSitterScreen(sitterId: booking.sitterId, distanceKm: booking.distanceKm, hideBookingButton: true)),
                                  ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: sizes.screenHeight * 0.016),

                  // 🔵 ZID (kifma tlab): "awaiting_confirmation" (candidate
                  // sitter jdid, mestanni confirmation) -> ZOUJ bottons
                  // (Accepter/Refuser la demande) BDAL "Cancel Booking".
                  if (booking.rawStatus == 'awaiting_confirmation')
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            sizes: sizes,
                            label: _isResponding ? 'loading_label'.tr() : 'accept_request_button'.tr(),
                            color: AppColors.vertpetsy,
                            onTap: _isResponding ? null : () => _onConfirmCandidate(true),
                          ),
                        ),
                        SizedBox(width: sizes.screenWidth * 0.03),
                        Expanded(
                          child: _actionButton(
                            sizes: sizes,
                            label: _isResponding ? 'loading_label'.tr() : 'refuse_request_button'.tr(),
                            color: AppColors.pinkpetsy,
                            onTap: _isResponding ? null : () => _onConfirmCandidate(false),
                          ),
                        ),
                      ],
                    )
                  else
                    _actionButton(sizes: sizes, label: 'cancel_booking_button'.tr(), color: AppColors.pinkpetsy, onTap: () {}),

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

  Widget _infoRow({required AppSizes sizes, required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: sizes.myProfileBodyFontSize * 0.85, color: AppColors.pinkpetsy),
        SizedBox(width: sizes.screenWidth * 0.02),
        Expanded(child: Text(text, style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85))),
      ],
    );
  }

  Widget _actionButton({required AppSizes sizes, required String label, required Color color, required VoidCallback? onTap}) {
    return SizedBox(
      height: sizes.screenHeight * 0.06,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.85), overflow: TextOverflow.ellipsis),
      ),
    );
  }
}