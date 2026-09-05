import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../controllers/request_controller.dart';
import '../../../controllers/auth_session.dart';
import '../owner/pet_profile.dart';
import '../../../widgets/message_dialog.dart';
import '../../../models/sitter_service_catalog.dart';

// ============================================================================
// RequestScreen ("Bookings Details") - sitter
// ============================================================================
// 🔵 Wsulha mel: (1) notification "booking_received"/"booking_accepted"
// (talab jdid, wla confirmation) - status déjà "resolved", ghir status
// pill (2) card "Need urgent sitting services" (marketplace "open")
// (3) sitter_calender.dart (booking déjà "accepted", "fromCalendar: true"
// - twarri "Cancel Booking" bdal el status pill, chrahtha _canCancel).
//
// 🔴 FIX (kifma tlab, design jdid): nafs template "booking_details.dart"
// (el owner) - "Informations" (icon rows) + "Pet(s)" (cards mnfasslin,
// kol wa7ed tappable -> profile tou3ou, read-only) - bla photo/esm tel
// owner fou9 (design el jdid ma yestal9ihach).
// ============================================================================
class RequestScreen extends StatefulWidget {
  final String bookingId;
  // 🔵 ZID (kifma tlab): "ken nhelha mel calendrier yjini bouton cancel
  // booking" - true GHIR ki tji mel sitter_calender.dart.
  final bool fromCalendar;

  const RequestScreen({super.key, required this.bookingId, this.fromCalendar = false});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> {
  final RequestController _controller = RequestController();
  BookingRequestDetail? _booking;
  bool _isLoading = true;
  bool _isResponding = false;

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
    final booking = await _controller.fetchBooking(widget.bookingId);
    if (!mounted) return;
    setState(() {
      _booking = booking;
      _isLoading = false;
    });
  }

  String _serviceLabel(String id) => _serviceLabelKeys[id] != null ? _serviceLabelKeys[id]!.tr() : id;

  String _title(BookingRequestDetail b) => b.serviceIds.isEmpty ? '-' : b.serviceIds.map(_serviceLabel).join(' + ');

  String _description(BookingRequestDetail b) {
    // 🔴 FIX (kifma tlab: "les services nhbhom fi des titre...") - el
    // 14 services jodad esmehom déjà wadh7in brachou (mathalan "Bain
    // complet et séchage") - mafamech me3na "desc" mnfassla zeyda (kifha
    // kif el 6 services el 9dima, "Le sitter reste chez vous...").
    return '';
  }

  // 🔵 ZID (fix timezone): ".toLocal()" 9bal .day/.month/.year -
  // mnghirha, el "youm" elli yban (mathalan booking 9rib mel nos el
  // lil) ynajjam ykoun DIFFERENT 3an el youm el 7a9i9i tel user.
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
  String _timeLabel(DateTime t) {
    final local = t.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  bool _isExpired(BookingRequestDetail b) => DateTime.now().isAfter(b.checkIn);

  bool _canRespond(BookingRequestDetail b) {
    if (_isExpired(b)) return false;
    final String? uid = AuthSession.userId;
    if (uid == null) return false;
    if (b.status == 'pending') return b.sitter?.id == uid;
    if (b.status == 'open') return true;
    return false;
  }

  // 🔵 ZID (kifma tlab): "Cancel Booking" GHIR ki mjiya mel calendrier
  // W el booking déjà "accepted" (el sitter el 7ali houwa el mfassal)
  // W el service MAZEL ma 5elsetch wa9tou (checkOut mazel ma 3addach -
  // "khtar deja terminee el service" -> ma3andouch me3na yenni service
  // déjà sar).
  bool _canCancel(BookingRequestDetail b) {
    if (!widget.fromCalendar) return false;
    if (b.status != 'accepted') return false;
    if (DateTime.now().isAfter(b.checkOut)) return false;
    return b.sitter?.id == AuthSession.userId;
  }

  String _statusLabel(BookingRequestDetail b) {
    if (_isExpired(b) && (b.status == 'pending' || b.status == 'open')) {
      return 'request_expired_label'.tr();
    }
    switch (b.status) {
      case 'accepted':
        // 🔵 ZID: "eli deja fait" - checkOut 3adda -> "Completed" (mch
        // "Confirmed" - el service déjà khlas, mch mazel jayy).
        return DateTime.now().isAfter(b.checkOut) ? 'booking_status_completed'.tr() : 'booking_status_confirmed'.tr();
      case 'rejected':
        return 'booking_status_rejected'.tr();
      case 'awaiting_confirmation':
        return 'request_awaiting_owner_label'.tr();
      default:
        return 'booking_status_pending'.tr();
    }
  }

  Future<void> _respond(bool accept) async {
    if (_isResponding || _booking == null) return;
    setState(() => _isResponding = true);
    final success = await _controller.respond(_booking!.id, accept: accept);
    if (!mounted) return;
    setState(() => _isResponding = false);

    if (!success) {
      showMessageDialog(context, 'profile_submit_error'.tr());
      return;
    }

    showMessageDialog(context, accept ? 'request_accepted_toast'.tr() : 'request_rejected_toast'.tr());
    Navigator.of(context).pop(true);
  }

  Future<void> _cancel() async {
    if (_isResponding || _booking == null) return;
    setState(() => _isResponding = true);
    final success = await _controller.cancelBooking(_booking!.id);
    if (!mounted) return;
    setState(() => _isResponding = false);

    if (!success) {
      showMessageDialog(context, 'profile_submit_error'.tr());
      return;
    }

    showMessageDialog(context, 'booking_cancelled_toast'.tr());
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_booking == null)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: sizes.bookingHorizontalPadding),
                  child: Text('no_profile_data_error'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                ),
              )
            else
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

                    // ------------------------------------------------
                    // Card: service (title + description) - kifha kif
                    // el mockup (card wa7da, mint, bla pill nested)
                    // ------------------------------------------------
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(sizes.bookingCardPadding),
                      decoration: BoxDecoration(
                        color: AppColors.vertpetsy.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_title(_booking!), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                          if (_description(_booking!).isNotEmpty) ...[
                            SizedBox(height: sizes.screenHeight * 0.004),
                            Text(_description(_booking!), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.85)),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: sizes.bookingSectionGap * 1.4),

                    // ------------------------------------------------
                    // Informations
                    // ------------------------------------------------
                    Text('informations_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                    SizedBox(height: sizes.screenHeight * 0.008),
                    Container(height: 2, color: AppColors.pinkpetsy),
                    SizedBox(height: sizes.screenHeight * 0.016),

                    Row(
                      children: [
                        for (final pet in _booking!.pets.take(2)) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(sizes.bookingAvatarSize / 2),
                            child: Container(
                              width: sizes.bookingAvatarSize,
                              height: sizes.bookingAvatarSize,
                              margin: EdgeInsets.only(right: sizes.screenWidth * 0.015),
                              color: AppColors.vertpetsy.withOpacity(0.25),
                              child: pet.photoUrl != null
                                  ? Image.network(pet.photoUrl!, fit: BoxFit.cover)
                                  : Icon(Icons.pets, color: AppColors.vertpetsy, size: sizes.bookingAvatarSize * 0.55),
                            ),
                          ),
                        ],
                        SizedBox(width: sizes.screenWidth * 0.02),
                        Expanded(
                          child: Text(_booking!.pets.map((p) => p.name).join(', '), style: TextStyle(fontWeight: FontWeight.w600, fontSize: sizes.myProfileBodyFontSize * 0.9)),
                        ),
                      ],
                    ),
                    SizedBox(height: sizes.screenHeight * 0.014),

                    _infoRow(sizes: sizes, icon: Icons.calendar_today_outlined, text: _dateRangeLabel(_booking!.checkIn, _booking!.checkOut)),
                    SizedBox(height: sizes.screenHeight * 0.012),
                    _infoRow(sizes: sizes, icon: Icons.access_time, text: '${_timeLabel(_booking!.checkIn)} - ${_timeLabel(_booking!.checkOut)}'),
                    SizedBox(height: sizes.screenHeight * 0.012),
                    _infoRow(sizes: sizes, icon: Icons.location_on_outlined, text: _booking!.owner.city != null ? '${_booking!.owner.city} , ${'tunisia_label'.tr()}' : '-'),
                    SizedBox(height: sizes.screenHeight * 0.012),
                    _infoRow(sizes: sizes, icon: Icons.phone_outlined, text: (_booking!.owner.phone != null && _booking!.owner.phone!.isNotEmpty) ? _booking!.owner.phone! : '-'),
                    SizedBox(height: sizes.screenHeight * 0.012),
                    _infoRow(sizes: sizes, icon: Icons.attach_money, text: 'total_amount_label'.tr(namedArgs: {'amount': _booking!.total.toStringAsFixed(0)})),

                    SizedBox(height: sizes.bookingSectionGap * 1.4),

                    // ------------------------------------------------
                    // Pet(s) - kol wa7ed card mnfassel, tappable
                    // (-> profile tou3ou, read-only)
                    // ------------------------------------------------
                    Text('pets_section_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                    SizedBox(height: sizes.screenHeight * 0.008),
                    Container(height: 2, color: AppColors.pinkpetsy),
                    SizedBox(height: sizes.screenHeight * 0.016),

                    for (final pet in _booking!.pets) ...[
                      InkWell(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => PetProfileScreen(pet: pet, readOnly: true)),
                        ),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenHeight * 0.012),
                          decoration: BoxDecoration(
                            color: AppColors.vertpetsy.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(sizes.bookingAvatarSize / 2),
                                child: Container(
                                  width: sizes.bookingAvatarSize,
                                  height: sizes.bookingAvatarSize,
                                  color: AppColors.vertpetsy.withOpacity(0.25),
                                  child: pet.photoUrl != null
                                      ? Image.network(pet.photoUrl!, fit: BoxFit.cover)
                                      : Icon(Icons.pets, color: AppColors.vertpetsy, size: sizes.bookingAvatarSize * 0.55),
                                ),
                              ),
                              SizedBox(width: sizes.screenWidth * 0.03),
                              Expanded(
                                child: Text(pet.name, style: TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9)),
                              ),
                              Icon(Icons.chevron_right, color: AppColors.vertpetsy),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: sizes.screenHeight * 0.012),
                    ],

                    SizedBox(height: sizes.bookingSectionGap),

                    // ------------------------------------------------
                    // Action(s): Accept/Reject, WALA "Cancel Booking"
                    // (mel calendrier), WALA status pill bark.
                    // ------------------------------------------------
                    if (_canRespond(_booking!))
                      Row(
                        children: [
                          Expanded(
                            child: _actionButton(
                              sizes: sizes,
                              label: _isResponding ? 'loading_label'.tr() : 'accept_button'.tr(),
                              color: AppColors.vertpetsy,
                              onTap: _isResponding ? null : () => _respond(true),
                            ),
                          ),
                          SizedBox(width: sizes.screenWidth * 0.03),
                          Expanded(
                            child: _actionButton(
                              sizes: sizes,
                              label: _isResponding ? 'loading_label'.tr() : 'reject_button'.tr(),
                              color: AppColors.pinkpetsy,
                              onTap: _isResponding ? null : () => _respond(false),
                            ),
                          ),
                        ],
                      )
                    else if (_canCancel(_booking!))
                      _actionButton(
                        sizes: sizes,
                        label: _isResponding ? 'loading_label'.tr() : 'cancel_booking_button'.tr(),
                        color: AppColors.pinkpetsy,
                        onTap: _isResponding ? null : _cancel,
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.014),
                        decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.15), borderRadius: BorderRadius.circular(25)),
                        alignment: Alignment.center,
                        child: Text(_statusLabel(_booking!), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.85)),
                      ),

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
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), elevation: 0),
        onPressed: onTap,
        child: Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9)),
      ),
    );
  }
}