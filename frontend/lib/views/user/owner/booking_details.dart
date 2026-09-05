import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../controllers/les_reservations_controller.dart';
import '../../../controllers/request_controller.dart';
import '../../../widgets/pet_avatars_stack.dart';
import '../sitter/view_profile_sitter.dart';
import '../../../widgets/message_dialog.dart';
// 🔴 FIX (bug: bouton "Message à" mayyet, TODO 9dim - tawa el
// messagerie mawjouda 7a9i9i) - MessagesController.startConversation()
// + ChatScreen (kifha kif messages_list_screen.dart).
import '../../../controllers/messages_controller.dart';
import '../chat_screen.dart';
import '../../../models/sitter_service_catalog.dart';

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
  final MessagesController _messagesController = MessagesController();
  bool _isResponding = false;
  // 🔴 FIX (bug: bouton "Message à" mayyet) - loading state ki
  // n7awlou nefta7ou/n5al9ou el conversation m3a el sitter.
  bool _isOpeningChat = false;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  // 🔴 FIX (kifma tlab: "les services nhbhom fi des titre...") -
  // sitterServiceLabelKeys mel catalogue partagé (bدal liste mkarrra).
  static Map<String, String> get _serviceLabelKeys => sitterServiceLabelKeys;

  OwnerBooking get booking => widget.booking;

  String _serviceLabel(String serviceId) {
    final key = _serviceLabelKeys[serviceId];
    return key != null ? key.tr() : serviceId;
  }

  String get _title => booking.serviceIds.isEmpty ? '-' : booking.serviceIds.map(_serviceLabel).join(' + ');

  // 🔴 FIX (kifma tlab: "les services nhbhom fi des titre...") - el 14
  // services jodad esmehom déjà wadh7in brachou - mafamech me3na "desc"
  // mnfassla zeyda (kifha kif el 6 services el 9dima).
  String get _description => '';

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
      // 🔴 FIX (bug: "el detais mtaa el sitter yetfeskho") - "searching"/
      // "awaitingConfirmation" kanou mkhalltin m3a "pending" (default).
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
        return const Color(0xFFFFA726);
      case OwnerBookingStatus.searching:
        return const Color(0xFF29B6F6);
      case OwnerBookingStatus.awaitingConfirmation:
        return const Color(0xFF9575CD);
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
      showMessageDialog(context, 'profile_submit_error'.tr());
      return;
    }

    showMessageDialog(context, accept ? 'candidate_confirmed_toast'.tr() : 'candidate_declined_toast'.tr());
    Navigator.of(context).pop(true);
  }

  // 🔴 FIX (bug: bouton "Message à" mayyet - onTap: () {} TODO 9dim,
  // "mafamech messagerie mrakza l'hin") - tawa el messagerie mawjouda:
  // nefta7ou/n5al9ou el conversation m3a el sitter (nafs endpoint elli
  // messages_list_screen.dart testa3mel 3al bulles), w nemchiw l'ChatScreen.
  // 🔴 FIX (kifma tlab: "nhb el demande ma tkoun envoyee ella ma ykoun
  // fama message tebaath") - MAFAMECH creation houni khaless (appel
  // "read-only" bark, getExistingConversationWith) - ChatScreen tefte7
  // b conversationId=null lowkan mafamech conversation mazel (twalled
  // ghir ki l'AWWEL message 7a9i9i metba3eth).
  Future<void> _onMessageSitterPressed() async {
    if (_isOpeningChat || booking.sitterId.isEmpty) return;
    setState(() => _isOpeningChat = true);

    final existing = await _messagesController.getExistingConversationWith(booking.sitterId);
    if (!mounted) return;
    setState(() => _isOpeningChat = false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: existing?['conversationId'] as String?,
          otherUserId: booking.sitterId,
          otherUserName: booking.sitterName,
          otherUserPhotoUrl: booking.sitterPhotoUrl,
          status: existing?['status'] as String? ?? 'accepted',
          isInitiator: existing?['isInitiator'] as bool? ?? true,
        ),
      ),
    );
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
                  // 🔴 FIX (bug: "el detais mtaa el sitter... mch mawjoudin,
                  // yetfeskho ki naml operation") - el root cause 7a9i9i:
                  // status "open" (el sitter el asli RAFEDH, w el owner
                  // rebroadcasta - "booking.sitter" ywalli null 3ala 9asd,
                  // marketplace jdid, chraht fel backend broadcastBooking)
                  // kan yet7esseb "pending" (bug fel displayStatus - sa77e7
                  // fel les_reservations_controller.dart) - fa el badge
                  // yban "En attente" (kifha kif fama sitter mestanni ywajeb)
                  // lakin fel 7a9i9a MAFAMECH sitter mo3ayan khaless -
                  // "Pet Sitter" section kan ywarri esm fadhi + avatar
                  // generic + 2 boutons MAYYTIN (bla ma nchekkou
                  // sitterId.isEmpty 9bal el card el kaملha). Tawa: lowkan
                  // mafamech sitter 7a9i9i l'hin, twarri "recherche en
                  // cours" wadh7a (bla boutons fadhyin).
                  Text('pet_sitter_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                  SizedBox(height: sizes.screenHeight * 0.01),
                  if (booking.sitterId.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(sizes.bookingCardPadding * 0.7),
                      decoration: BoxDecoration(color: const Color(0xFF29B6F6).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: const Color(0xFF29B6F6), size: sizes.bookingAvatarSize * 0.55),
                          SizedBox(width: sizes.screenWidth * 0.03),
                          Expanded(
                            child: Text('booking_searching_sitter_label'.tr(), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85)),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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

                        // ----------------------------------------------
                        // Message / View Profile.
                        // 🔴 FIX: "Message à" kan onTap: () {} (dead - "mch
                        // mawjouda messagerie mrakza l'hin", TODO 9dim) -
                        // tawa el messagerie mawjouda (MessagesController/
                        // ChatScreen), fa nrabbtouh 7a9i9i.
                        // ----------------------------------------------
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                sizes: sizes,
                                label: _isOpeningChat ? 'loading_label'.tr() : 'message_sitter_button'.tr(namedArgs: {'name': booking.sitterName}),
                                color: AppColors.vertpetsy,
                                onTap: _isOpeningChat ? null : _onMessageSitterPressed,
                              ),
                            ),
                            SizedBox(width: sizes.screenWidth * 0.03),
                            Expanded(
                              child: _actionButton(
                                sizes: sizes,
                                label: 'view_sitter_profile_button'.tr(),
                                color: AppColors.vertpetsy,
                                onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(builder: (_) => ViewProfileSitterScreen(sitterId: booking.sitterId, distanceKm: booking.distanceKm, hideBookingButton: true)),
                                    ),
                              ),
                            ),
                          ],
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