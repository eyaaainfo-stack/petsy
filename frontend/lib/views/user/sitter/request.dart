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
  // 🔴 FIX (kifma tlab: "ma ejbetnich fel mandhar... khalliha wkt
  // nenzel al categorie tethalli tahtha lista mta3 les service
  // selectionnees") - key = icon.codePoint (el category/"+" tel
  // custom) - bch na3rfou anhi category(s) el user 7ell (expand
  // toggle), mch AlertDialog/SnackBar 3ad.
  final Set<int> _expandedServiceGroups = {};

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

  // 🔴 FIX (kifma tlab: "aleh tji custom num... nhb el logo mtaa el
  // categorie... w kif nenzel ala categorie tethalli el service eli
  // khtarou el owner") - "_title()" el 9dima kanet testa3mel GHIR
  // "b.serviceIds" (catalog labels bark) - el "customLabel" (déjà
  // mjabed mel backend, chraht kaملa fel request_controller.dart/
  // BookedServiceEntry) kan mahmel khales, fahetha service custom
  // kan yban raw ("custom_1788576050362000") bدal el esm el 7a9i9i.
  //
  // Tawa: icon (nafs convention "Patients du jour" - sitter_profile.
  // dart/_TodayPatientCard: "+" lel custom, category icon l'el b9iya)
  // + esm 7a9i9i (customLabel ken custom, wla catalog label) - "chip"
  // tappable l'kol wa7ed (SnackBar ywarri el esm el kamel, mch ghir
  // icon bark).
  IconData _serviceIcon(String serviceId) {
    return isCustomServiceId(serviceId) ? Icons.add : (categoryIconForService(serviceId) ?? Icons.pets);
  }

  // 🔴 FIX (kifma tlab: "tethalli fenetre fiha esm el service w
  // kodemou el prix mteou") - zedt el prix (déjà mo5azzan fel booking,
  // models/booking.js/bookingServiceSchema - price required per
  // service) m3a l'esm fel SnackBar.
  String _resolvedServiceLabel(BookedServiceEntry s) {
    if (isCustomServiceId(s.serviceId)) {
      return (s.customLabel != null && s.customLabel!.trim().isNotEmpty)
          ? s.customLabel!
          : 'sitter_custom_service_generic_label'.tr();
    }
    return _serviceLabel(s.serviceId);
  }

  // 🔵 ZID (kifma tlab: "zidni kodem el logo esm el categorie") - esm
  // el category ("Toilettage"/"Garde d'animaux"/... wla "Autre" l'el
  // custom) - categoryTitleKeyForService (sitter_service_catalog.dart,
  // nafs pattern categoryIconForService).
  String _categoryLabel(String serviceId) {
    if (isCustomServiceId(serviceId)) return 'sitter_category_custom'.tr();
    final key = categoryTitleKeyForService(serviceId);
    return key != null ? key.tr() : '';
  }

  // 🔴 FIX (kifma tlab: "ma ejbetnich fel mandhar khalliha wkt nenzel
  // al categorie tethalli tahtha lista mta3 les service selectionnees
  // w kodemhom prix mteehom w kenhom akthar men pet amlha *nb pet") -
  // bدal AlertDialog: chip per CATEGORY (déduplicated, mch per service
  // fardi) - dass 3liha, tet7ell/tet3allef LISTA jowaha (inline, mch
  // popup) - kol service jowa had category m3a el prix (× 3adad el
  // pets, "price" mo5azzan houwa PER PET - chraht kaملa fel backend,
  // bookingController.js/respondToBooking: "newTotal += price * petCount").
  Widget _serviceChips(BookingRequestDetail b, AppSizes sizes) {
    if (b.services.isEmpty) {
      return Text('-', style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize));
    }
    final int petCount = b.pets.isEmpty ? 1 : b.pets.length;

    final Map<int, IconData> iconByKey = {};
    final Map<int, String> labelByKey = {};
    final Map<int, List<BookedServiceEntry>> grouped = {};
    for (final s in b.services) {
      final icon = _serviceIcon(s.serviceId);
      iconByKey[icon.codePoint] = icon;
      labelByKey.putIfAbsent(icon.codePoint, () => _categoryLabel(s.serviceId));
      grouped.putIfAbsent(icon.codePoint, () => []).add(s);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: sizes.screenWidth * 0.02,
          runSpacing: sizes.screenHeight * 0.008,
          children: [
            for (final key in grouped.keys)
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => setState(() {
                  if (_expandedServiceGroups.contains(key)) {
                    _expandedServiceGroups.remove(key);
                  } else {
                    _expandedServiceGroups.add(key);
                  }
                }),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.025, vertical: sizes.screenHeight * 0.006),
                  decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.14), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(iconByKey[key], color: AppColors.pinkpetsy, size: sizes.screenWidth * 0.04),
                      SizedBox(width: sizes.screenWidth * 0.014),
                      Text(labelByKey[key] ?? '', style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                      SizedBox(width: sizes.screenWidth * 0.01),
                      Icon(
                        _expandedServiceGroups.contains(key) ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        color: AppColors.pinkpetsy,
                        size: sizes.screenWidth * 0.04,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        for (final key in grouped.keys)
          if (_expandedServiceGroups.contains(key))
            Padding(
              padding: EdgeInsets.only(top: sizes.screenHeight * 0.008, bottom: sizes.screenHeight * 0.004),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenHeight * 0.008),
                decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.06), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in grouped[key]!)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.004),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(_resolvedServiceLabel(s), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.9)),
                            ),
                            Text(
                              '${(s.price * petCount).toStringAsFixed(0)} DT',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.pinkpetsy, fontSize: sizes.myProfileBodyFontSize * 0.9),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
      ],
    );
  }

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

  // 🔵 ZID (feature "partage de localisation"): ki el sitter y9bel un
  // talab "pending" (direct, mch candidature "open" - ma3andouch me3na
  // temma, el sitter mazel ma confirmech), ne5ou el mouwafa9a mte3ou
  // (bool) 9bal ma nkemlou l'appel - el owner ynajjam ychouf position
  // el sitter (fixe, mel profil) fel bouton "Localisation" (sidebar)
  // tant que el booking active (chrahtha getActiveSitterLocations).
  Future<bool?> _askShareLocation() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('share_location_dialog_title'.tr()),
        content: Text('share_location_dialog_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('share_location_decline_button'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('share_location_accept_button'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _respond(bool accept) async {
    if (_isResponding || _booking == null) return;

    bool? shareLocation;
    if (accept) {
      shareLocation = await _askShareLocation();
      if (shareLocation == null) return; // 🔵 user closed the dialog (back button) - abandon, ma nkemlouch l'accept
    }

    setState(() => _isResponding = true);
    final result = await _controller.respond(_booking!.id, accept: accept, shareLocation: shareLocation);
    if (!mounted) return;

    if (!result.success) {
      setState(() => _isResponding = false);
      // 🔵 ZID (feature "compatibilite entre animaux"): el message
      // el 7a9i9i mel backend (mathalan conflit category/capacite) -
      // MCH el message générique ('profile_submit_error') ken mawjoud.
      showMessageDialog(context, result.errorMessage ?? 'profile_submit_error'.tr());
      return;
    }

    // 🔴 FIX (kifma tlab: "nenzel ala accepter ma yetbadel chy fel
    // interface... ama kif nokhrej w naawed nodkhol tjini confirmer
    // yaani hiya reelement tkoblet men awl clic") - "Navigator.pop"
    // direct ba3d "showMessageDialog" kan race: showDialog ye39ad route
    // JDIDA (el dialog), w el "pop()" el jayya direct wra kanet
    // te9ta3 EL DIALOG (el route el a5ir eli et7atet), mch el
    // RequestScreen nafsou - fahetha el écran kan yeb9a HOWA HOWA (bla
    // ma yetbeddel 7ata 7aja), 7atta ken el backend déjà 3addel el
    // status mel awel clic (chraht kaملa fel adminController.js/
    // updateUser, nafs mant9). Tawa: _load() (re-fetch) bدal el pop -
    // el status yban el jdid EN PLACE, direct.
    await _load();
    if (!mounted) return;
    setState(() => _isResponding = false);
    showMessageDialog(context, accept ? 'request_accepted_toast'.tr() : 'request_rejected_toast'.tr());
  }

  Future<void> _cancel() async {
    if (_isResponding || _booking == null) return;
    setState(() => _isResponding = true);
    final success = await _controller.cancelBooking(_booking!.id);
    if (!mounted) return;

    if (!success) {
      setState(() => _isResponding = false);
      showMessageDialog(context, 'profile_submit_error'.tr());
      return;
    }

    // 🔴 FIX (kifma tlab) - nafs el fix mel fou9 (_respond) - _load()
    // bدal Navigator.pop (race m3a showMessageDialog).
    await _load();
    if (!mounted) return;
    setState(() => _isResponding = false);
    showMessageDialog(context, 'booking_cancelled_toast'.tr());
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
                          _serviceChips(_booking!, sizes),
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