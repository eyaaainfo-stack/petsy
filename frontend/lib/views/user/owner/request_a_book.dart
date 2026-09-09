import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/paw_widget.dart';
import '../../../widgets/success_confirmation_dialog.dart';
import '../../../controllers/booking_controller.dart';
import '../../../controllers/my_profile_controller.dart';
import '../../../models/pet_summary.dart';
import '../../../models/my_profile_data.dart';
import '../../../repositories/pet_repository.dart';
import '../../../widgets/message_dialog.dart';
import '../../../models/sitter_service_catalog.dart';
import '../../../widgets/booking_alternatives_dialog.dart';
import '../sitter/view_profile_sitter.dart';

// ============================================================================
// RequestABookScreen ("Request a Book")
// ============================================================================
// 🔵 Wsulha mel bouton "Request a book" (view_profile_sitter.dart) -
// "sitterServices" tousel mennha (el services el 7a9i9iyin elli el
// SITTER 3andou, mch liste ثابتة - kifma tlab).
//
// 🔴 FIX (kifma tlab): "el pets lkol b tsawerhom" - data 7a9i9iya
// (PetRepository.fetchOwnerPets()), mch mock. "el Accommodation"
// tna77at tamaman. "kol service tenzel 3lih ywarri prix + total".
//
// 🔵 ZID (kifma tlab el a5ir): "Service for" (pets, global lel booking
// kollou) tna77a - TAWA kol SERVICE 3andou el pets mte3ou HOWA (mathalan
// Grooming l'Pet A bark, Walking l'Pet A + Pet B fi NEFS el booking).
// El total ye7seb PER-SERVICE (prix * 3adad el pets el mkhtarin fi
// HAD el service, mch global).
// ============================================================================
class RequestABookScreen extends StatefulWidget {
  final String sitterId;
  final String sitterName;
  final List<SitterServiceEntry> sitterServices;

  const RequestABookScreen({
    super.key,
    required this.sitterId,
    required this.sitterName,
    required this.sitterServices,
  });

  @override
  State<RequestABookScreen> createState() => _RequestABookScreenState();
}

class _RequestABookScreenState extends State<RequestABookScreen> {
  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDate;
  // 🔴 FIX: "hour: 12" ye3ni 12:00 PM (mid-journée) fel format 24h tel
  // Flutter (TimeOfDay.period: hour<12 -> AM, hour>=12 -> PM) - MCH
  // 12:00 AM (nos el lil) kifma el mockup. Hedhi el sebba elli "AM ma
  // kanch ye5dem/yban" - kanet dima tبda PM. Tawa "hour: 0" = 12:00 AM
  // 7a9i9i.
  TimeOfDay _checkInTime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _checkOutTime = const TimeOfDay(hour: 0, minute: 0);

  List<PetSummary> _pets = [];
  bool _isLoadingPets = true;
  // 🔵 ZID (kifma tlab): serviceId -> pets el mkhtarin l'HAD service
  // bark (mch selection global lel booking kollou).
  final Map<String, Set<String>> _servicePetIds = {};

  final BookingController _controller = BookingController();
  bool _isSubmitting = false;

  // 🔵 ZID (kifma tlab): "el owner ma yenajjamch ye5tar youm el sitter
  // mch dispo fih" - njiboha mel profile el 3am tel sitter (déjà 3andou
  // les 2 champs, chrahtha sitter_calender.dart/availability_picker.dart).
  final MyProfileController _profileController = MyProfileController();
  List<int> _recurringDaysOff = [];
  List<DateTime> _specificDatesOff = [];

  // 🔴 FIX (kifma tlab: "les services nhbhom fi des titre... ken yhb
  // yzid service ekher") - sitterServiceLabelKeys mel catalogue partagé
  // - "custom" (Autre, el sitter zad service b ydik) yesta3mel "customLabel"
  // (mawjouda houni, 3andna el entry el KAMLA - mch ghir el id).
  String _serviceLabel(SitterServiceEntry service) {
    if (isCustomServiceId(service.serviceId)) {
      return (service.customLabel != null && service.customLabel!.isNotEmpty) ? service.customLabel! : service.serviceId;
    }
    final key = sitterServiceLabelKeys[service.serviceId];
    return key != null ? key.tr() : service.serviceId;
  }

  @override
  void initState() {
    super.initState();
    _loadPets();
    _loadSitterAvailability();
  }

  Future<void> _loadSitterAvailability() async {
    final profile = await _profileController.fetchSitterPublicProfile(widget.sitterId);
    if (!mounted || profile == null) return;
    setState(() {
      _recurringDaysOff = profile.recurringDaysOff;
      _specificDatesOff = profile.specificDatesOff.map((d) => DateTime(d.year, d.month, d.day)).toList();
    });
  }

  // 🔵 ZID: youm mo7addad mch dispo (recurring WALA date mo7addda).
  bool _isDateUnavailable(DateTime date) {
    if (_recurringDaysOff.contains(date.weekday)) return true;
    return _specificDatesOff.any((d) => d.year == date.year && d.month == date.month && d.day == date.day);
  }

  Future<void> _loadPets() async {
    final pets = await PetRepository.fetchOwnerPets();
    if (!mounted) return;
    setState(() {
      _pets = pets;
      _isLoadingPets = false;
    });
  }

  // 🔵 ZID (kifma tlab): UNION tel kol pets el mkhtarin fi AY service
  // (booking-level) - esta3mlnah lel category tel booking el kaملa +
  // lel payload el general (petIds, backend, resolveBookingPetsCategory).
  Set<String> get _allSelectedPetIds => _servicePetIds.values.expand((s) => s).toSet();

  // 🔵 ZID (feature "compatibilite entre animaux"): kol pets fi NEFS
  // booking (fi AY service) lezem ykounou nefs el category (chraht fel
  // backend, resolveBookingPetsCategory). Terja3 el category el
  // mchtarka lowkan kol el pets el mkhtarin (fi AY service) NEFS el
  // category, wala null (mafamech 7atta pet mkhtar l'hin).
  String? get _bookingCategory {
    final categories = _pets
        .where((p) => p.id != null && _allSelectedPetIds.contains(p.id))
        .map((p) => p.category)
        .whereType<String>()
        .toSet();
    return categories.length == 1 ? categories.first : null;
  }

  // 🔵 ZID (feature "compatibilite entre animaux"): el prix PER-
  // CATEGORY (service.prices) - null lowkan mafamech category m7addda
  // l'hin (mafamech 7atta pet mkhtar), wala had service ma yban-lich
  // l'category hedhi (kifma tlab: "mch chart enou nwafrou lel 3 types").
  double? _priceForService(SitterServiceEntry service) {
    final category = _bookingCategory;
    if (category == null) return null;
    for (final p in service.prices) {
      if (p.category == category) return p.price;
    }
    return null;
  }

  // 🔵 ZID (kifma tlab): toggle pet l'HAD service bark (mch global).
  void _onServicePetTap(SitterServiceEntry service, PetSummary pet) {
    if (pet.id == null) return;
    final assigned = _servicePetIds.putIfAbsent(service.serviceId, () => {});
    if (assigned.contains(pet.id)) {
      setState(() {
        assigned.remove(pet.id);
        if (assigned.isEmpty) _servicePetIds.remove(service.serviceId);
      });
      return;
    }
    // 🔵 ZID (feature "compatibilite entre animaux"): manna3 mzij
    // categories (small_dog + guard_dog mathalan) fi NEFS el booking
    // (7ata bin services mختلفين) - el backend yerfudhha barra, ahsen
    // ن3allmou el owner FORAN houni.
    final String? currentCategory = _bookingCategory;
    if (currentCategory != null && pet.category != null && pet.category != currentCategory) {
      showMessageDialog(context, 'booking_pets_category_mismatch_error'.tr());
      return;
    }
    setState(() => assigned.add(pet.id!));
  }

  // 🔴 FIX (kifma tlab: "el totale des service yethseb nb pets * service
  // selectionnees") -> tawa (kifma tlab el a5ir): PER-SERVICE, mch
  // global - kol service: prix (category) * 3adad el pets el mkhtarin
  // FI HAD el service bark.
  double get _total {
    double sum = 0;
    for (final service in widget.sitterServices) {
      final petIds = _servicePetIds[service.serviceId];
      if (petIds == null || petIds.isEmpty) continue;
      final price = _priceForService(service);
      if (price == null) continue;
      sum += price * petIds.length;
    }
    return sum;
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  // 🔴 FIX (kifma tlab): "mnghir ma nenzel 3liha w tethalli mونجلة" -
  // el zoùj (_pickCheckInTime/_pickCheckOutTime, showTimePicker) tna77aw
  // - tawa spinner INLINE (up/down arrows) direct, chrahtha ta7t
  // (_timeSpinnerField).

  Future<void> _onSendRequestPressed() async {
    if (_isSubmitting) return;

    if (_selectedDate == null) {
      showMessageDialog(context, 'select_date_error'.tr());
      return;
    }
    // 🔵 ZID (filet de sécurité): lowkan el data tel disponibilité
    // weslet METAKHRA (async, ba3d ma el user déjà 5tar el date) - nre-
    // chekkou houni zeda 9bal el ib3ath.
    if (_isDateUnavailable(_selectedDate!)) {
      showMessageDialog(context, 'sitter_unavailable_this_day_error'.tr());
      return;
    }
    if (_allSelectedPetIds.isEmpty) {
      showMessageDialog(context, 'select_pet_error'.tr());
      return;
    }
    // 🔵 ZID (kifma tlab): "service selectionnee" tawa ye3ni "3andou
    // l'a9al pet wa7ed mrakez bih" (mch checkbox mnfassel).
    final bool hasAnyActiveService = widget.sitterServices.any((s) => (_servicePetIds[s.serviceId]?.isNotEmpty ?? false));
    if (!hasAnyActiveService) {
      showMessageDialog(context, 'select_service_error'.tr());
      return;
    }
    final checkIn = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _checkInTime.hour, _checkInTime.minute);
    final checkOut = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _checkOutTime.hour, _checkOutTime.minute);

    // 🔴 FIX (kifma tlab): checkout lezmou ykoun BA3D checkin.
    if (!checkOut.isAfter(checkIn)) {
      showMessageDialog(context, 'checkout_before_checkin_error'.tr());
      return;
    }
    // 🔴 FIX (kifma tlab): checkin lezmou ykoun 3al a9al SA3A wa7da
    // mel wa9t el 7ali.
    if (checkIn.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
      showMessageDialog(context, 'checkin_too_soon_error'.tr());
      return;
    }

    setState(() => _isSubmitting = true);

    // 🔵 ZID (kifma tlab): kol service, "petIds" mte3ou HOWA (mch
    // global) - Booking.services (bookingServiceSchema, backend) tawa
    // fiha "petIds" per-entry.
    final servicesPayload = [
      for (final s in widget.sitterServices)
        if (_servicePetIds[s.serviceId]?.isNotEmpty ?? false)
          {
            'serviceId': s.serviceId,
            'price': _priceForService(s) ?? 0,
            'petIds': _servicePetIds[s.serviceId]!.toList(),
          },
    ];

    final result = await _controller.createBooking(
      sitterId: widget.sitterId,
      petIds: _allSelectedPetIds.toList(),
      services: servicesPayload,
      checkIn: checkIn,
      checkOut: checkOut,
      total: _total,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      // 🔵 ZID (feature "compatibilite entre animaux"): 409 - conflit
      // category/capacite - nfahsou les alternatives (Khyar A/B) 9bal
      // ma nwarriw erreur 3adiya bark.
      const conflictReasons = {'category_mismatch', 'capacity_full'};
      if (result.reason != null && conflictReasons.contains(result.reason)) {
        final alternatives = await _controller.getAlternatives(
          sitterId: widget.sitterId,
          petIds: _allSelectedPetIds.toList(),
          checkIn: checkIn,
          checkOut: checkOut,
        );
        if (!mounted) return;
        if (alternatives != null && !alternatives.isEmpty) {
          await showBookingAlternativesDialog(
            context,
            alternatives: alternatives,
            onPickSlot: (newCheckIn, newCheckOut) {
              setState(() {
                _visibleMonth = DateTime(newCheckIn.year, newCheckIn.month);
                _selectedDate = DateTime(newCheckIn.year, newCheckIn.month, newCheckIn.day);
                _checkInTime = TimeOfDay(hour: newCheckIn.hour, minute: newCheckIn.minute);
                _checkOutTime = TimeOfDay(hour: newCheckOut.hour, minute: newCheckOut.minute);
              });
              showMessageDialog(context, 'booking_alternatives_slot_applied_label'.tr());
            },
            onPickSitter: (otherSitterId) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ViewProfileSitterScreen(sitterId: otherSitterId)),
              );
            },
          );
          return;
        }
      }
      showMessageDialog(context, result.errorMessage ?? 'login_generic_error'.tr());
      return;
    }

    // 🔵 ZID (kifma tlab): popup confirmation (tick) - widget mchtarek
    // (widgets/success_confirmation_dialog.dart).
    await showSuccessConfirmationDialog(context, message: 'booking_sent_success_message'.tr());
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sizes.rabHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: sizes.rabTopGap),

                  Row(
                    children: [
                      SizedBox(width: sizes.screenWidth * 0.12), // blasa lel back button (overlay)
                      Expanded(
                        child: Text(
                          'request_a_book_title'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileNameFontSize * 0.9),
                        ),
                      ),
                      buildPetPaw(context: context, size: sizes.screenWidth * 0.06, topPercent: 0, leftPercent: 0, color: AppColors.pinkpetsy.withOpacity(0.5)),
                    ],
                  ),

                  SizedBox(height: sizes.rabSectionGap),

                  // --------------------------------------------------
                  // Calendrier
                  // --------------------------------------------------
                  _buildCalendar(sizes),

                  SizedBox(height: sizes.rabSectionGap),

                  // --------------------------------------------------
                  // Check In / Check Out
                  // --------------------------------------------------
                  _timeSpinnerField(
                    sizes: sizes,
                    label: 'check_in_label'.tr(),
                    time: _checkInTime,
                    onChanged: (t) => setState(() => _checkInTime = t),
                  ),
                  SizedBox(height: sizes.rabSectionGap * 0.6),
                  _timeSpinnerField(
                    sizes: sizes,
                    label: 'check_out_label'.tr(),
                    time: _checkOutTime,
                    onChanged: (t) => setState(() => _checkOutTime = t),
                  ),

                  SizedBox(height: sizes.rabSectionGap),

                  // --------------------------------------------------
                  // 🔵 ZID (kifma tlab el a5ir): "Service for" (global)
                  // tna77a - kol service (ta7t) 3andou el pets mte3ou HOWA.
                  // 🔴 FIX (kifma tlab): "Service Type" - GHIR el
                  // services el 7a9i9iyin elli el SITTER 3andou (mch
                  // liste thabta) - kol wa7ed m3ah prix, w el pets
                  // mte3ou (selection mnfassla).
                  // --------------------------------------------------
                  Text('sitter_services_offered_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                  SizedBox(height: sizes.rabSectionGap * 0.6),
                  if (_isLoadingPets)
                    const Center(child: CircularProgressIndicator())
                  else if (widget.sitterServices.isEmpty)
                    Text('no_urgent_services_label'.tr(), style: TextStyle(color: Colors.grey.shade600))
                  else if (_pets.isEmpty)
                    Text('no_pets_yet_label'.tr(), style: TextStyle(color: Colors.grey.shade600))
                  else
                    for (final service in widget.sitterServices) _serviceCheckRow(sizes: sizes, service: service),

                  SizedBox(height: sizes.rabSectionGap * 0.6),
                  // 🔵 ZID (kifma tlab): total 7ay (yetbeddel automatique
                  // ki tzid/tna77i pet mel service).
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('total_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                      Text('${_total.toStringAsFixed(0)} DT', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.pinkpetsy, fontSize: sizes.myProfileNameFontSize * 0.7)),
                    ],
                  ),

                  // 🔴 FIX (kifma tlab): "el fazet el accommodation"
                  // tna77at KAMLA (mafamech Apartment/House/Country
                  // House houni).

                  SizedBox(height: sizes.rabSectionGap * 1.3),

                  SizedBox(
                    width: double.infinity,
                    height: sizes.screenHeight * 0.065,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _onSendRequestPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.pinkpetsy,
                        disabledBackgroundColor: AppColors.pinkpetsy.withOpacity(0.6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text(_isSubmitting ? 'loading_label'.tr() : 'send_request_button'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
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

  // --------------------------------------------------------------------
  // Calendrier - month grid sghira, hand-rolled (bla package zeyed,
  // esm el chher mel liste _monthNames bch ma nzidouch dépendance
  // "intl" zeyda ghir l'hedhi).
  // --------------------------------------------------------------------
  Widget _buildCalendar(AppSizes sizes) {
    final firstDayOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    // 🔵 Dart: DateTime.weekday -> 1=Monday...7=Sunday. Nbeddlouha bch
    // "Sunday" ykoun 0 (el mockup yebda bel Sunday).
    final startOffset = firstDayOfMonth.weekday % 7;
    final today = DateTime.now();

    return Container(
      padding: EdgeInsets.all(sizes.screenWidth * 0.03),
      decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.06), borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left, color: AppColors.pinkpetsy)),
              Text('${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
              IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right, color: AppColors.pinkpetsy)),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemBuilder: (context, index) {
              const dayLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
              return Center(child: Text(dayLabels[index], style: TextStyle(fontSize: sizes.screenWidth * 0.024, color: Colors.grey, fontWeight: FontWeight.bold)));
            },
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startOffset + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
            itemBuilder: (context, index) {
              if (index < startOffset) return const SizedBox();
              final day = index - startOffset + 1;
              final date = DateTime(_visibleMonth.year, _visibleMonth.month, day);
              final bool isSelected = _selectedDate != null && _selectedDate!.year == date.year && _selectedDate!.month == date.month && _selectedDate!.day == date.day;
              final bool isPast = date.isBefore(DateTime(today.year, today.month, today.day));
              // 🔴 FIX (kifma tlab): "el owner ma yenajjamch ye5tar youm
              // el sitter mch dispo fih" - youm mo7addad (recurring wela
              // date mo7addda) ye5faf lounou, w ki tos8ot 3lih yban message
              // bdal ma ykhtar.
              final bool isUnavailable = !isPast && _isDateUnavailable(date);

              return Padding(
                padding: const EdgeInsets.all(2),
                child: InkWell(
                  onTap: isPast
                      ? null
                      : isUnavailable
                          ? () => showMessageDialog(context, 'sitter_unavailable_this_day_error'.tr())
                          : () => setState(() => _selectedDate = date),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.pinkpetsy : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : (isPast
                                ? Colors.grey.shade400
                                : (isUnavailable ? Colors.grey.shade400 : null)),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        decoration: isUnavailable ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 🔴 FIX (kifma tlab): "spinner INLINE" - up/down arrows ye3malou
  // increment/decrement DIRECT (mnghir dialog/popup, "mnghir ma nenzel
  // 3liha w tethalli mونجلة") - kifha kif el mockup bالضبط.
  Widget _timeSpinnerField({
    required AppSizes sizes,
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onChanged,
  }) {
    // 🔵 ZID (kifma tlab): format 24h direct (0-23), na77ina el AM/PM.
    void setHour(int newHour) {
      final int normalized = ((newHour % 24) + 24) % 24; // 0..23 (wrap)
      onChanged(TimeOfDay(hour: normalized, minute: time.minute));
    }

    void setMinute(int newMinute) {
      final int normalized = ((newMinute % 60) + 60) % 60; // 0..59 (wrap)
      onChanged(TimeOfDay(hour: time.hour, minute: normalized));
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenHeight * 0.012),
      decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.10), borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Icon(Icons.access_time, color: AppColors.pinkpetsy.withOpacity(0.7), size: sizes.screenWidth * 0.045),
          SizedBox(width: sizes.screenWidth * 0.02),
          Text(label, style: TextStyle(color: AppColors.pinkpetsy.withOpacity(0.8), fontSize: sizes.myProfileBodyFontSize * 0.85)),
          const Spacer(),
          _spinnerDigit(sizes: sizes, value: time.hour.toString().padLeft(2, '0'), onUp: () => setHour(time.hour + 1), onDown: () => setHour(time.hour - 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.01),
            child: Text(':', style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
          ),
          _spinnerDigit(sizes: sizes, value: time.minute.toString().padLeft(2, '0'), onUp: () => setMinute(time.minute + 1), onDown: () => setMinute(time.minute - 1)),
        ],
      ),
    );
  }

  // 🔵 raqma wa7da (sa3a wla d9i9a) + sهم fou9/ta7t - tap direct ye3mel
  // increment/decrement (bla dialog).
  Widget _spinnerDigit({required AppSizes sizes, required String value, required VoidCallback onUp, required VoidCallback onDown}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onUp,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(Icons.keyboard_arrow_up, color: AppColors.pinkpetsy, size: sizes.screenWidth * 0.05),
          ),
        ),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
        InkWell(
          onTap: onDown,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Icon(Icons.keyboard_arrow_down, color: AppColors.pinkpetsy, size: sizes.screenWidth * 0.05),
          ),
        ),
      ],
    );
  }

  // 🔵 ZID (kifma tlab: "el prix kodem el esm el pet") - el prix mte3
  // HAD el pet (7asb el category mte3ha HIYA, mch el "booking category"
  // el 3am) - hakka kol chip ywarri prix tou3ha mba3rech, 7atta 9bal
  // ma tختار 7atta pet fi service okhor.
  double? _priceForPetInService(SitterServiceEntry service, PetSummary pet) {
    if (pet.category == null) return null;
    for (final p in service.prices) {
      if (p.category == pet.category) return p.price;
    }
    return null;
  }

  // 🔵 ZID (kifma tlab): chip SGHIRA (bla photo) - bch tab9a compacte
  // ki tban TA7T KOL service (mch chip kbira kifma "_petChip" el 9dima
  // elli kanet fel section globale "Service for" - tna77at).
  Widget _miniPetChip({
    required AppSizes sizes,
    required PetSummary pet,
    required bool isSelected,
    required VoidCallback onTap,
    double? price,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.025, vertical: sizes.screenHeight * 0.006),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.vertpetsy.withOpacity(0.18) : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.vertpetsy : Colors.transparent, width: 1.4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              size: sizes.screenWidth * 0.032,
              color: isSelected ? AppColors.vertpetsy : Colors.grey,
            ),
            SizedBox(width: sizes.screenWidth * 0.012),
            // 🔵 ZID (kifma tlab): el prix KODEM el esm (mch ba3dou).
            if (price != null)
              Text(
                '${price.toStringAsFixed(0)} DT  ',
                style: TextStyle(
                  fontSize: sizes.myProfileBodyFontSize * 0.78,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.vertpetsy : AppColors.pinkpetsy,
                ),
              ),
            Text(
              pet.name,
              style: TextStyle(
                fontSize: sizes.myProfileBodyFontSize * 0.78,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                color: isSelected ? AppColors.vertpetsy : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔵 ZID (kifma tlab el a5ir): kol service tawa 3andou selection tel
  // pets mte3ou HOWA (mnghir "Service for" global) - esm+prix fou9,
  // w ta7tou chips tel pets (tap = zid/na77i mel service hedha bark).
  Widget _serviceCheckRow({required AppSizes sizes, required SitterServiceEntry service}) {
    final Set<String> assignedPetIds = _servicePetIds[service.serviceId] ?? {};
    // 🔴 FIX (bug "deadlock": kol service yban 'Non propose pour cet
    // animal', 7atta chips el pets ma yebanouch, fa el owner ma
    // ynajjamch ye5tar 7atta pet mel bidaya!) - el mochkla kanet:
    // "isUnavailable = price == null", ama "price" ye7taj category, w
    // "category" ye7taj pet mkhtar - fa 9bal ma tkhtar 7atta pet (category
    // null), KOL service kan yban "unavailable" -> chips ma yebanouch
    // -> ma tنجمch tkhtar 7atta pet -> DEADLOCK.
    // Tawa: "unavailable" ye3ni 7aja OKHRA - "el category MA3ROUFA
    // (mel pets el mkhtarin fi services OKHRIN) W had service specifiquement
    // ma yesnedhech biha" - MCH "mafamech 7atta pet mkhtar l'hin".
    final String? category = _bookingCategory;
    final double? price = category != null ? _priceForService(service) : null;
    final bool isUnavailable = category != null && price == null;

    String priceText;
    if (price != null) {
      priceText = '${price.toStringAsFixed(0)} DT';
    } else if (isUnavailable) {
      priceText = 'service_not_offered_label'.tr();
    } else {
      // 🔵 category mazel ma t7addedetch (mafamech 7atta pet mkhtar
      // l'hin, fi AY service) - placeholder neutre, MCH "not offered".
      priceText = '—';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.01),
      child: Opacity(
        opacity: isUnavailable ? 0.45 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_serviceLabel(service), style: TextStyle(fontWeight: FontWeight.w600, fontSize: sizes.myProfileBodyFontSize)),
                ),
                Text(
                  priceText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isUnavailable ? Colors.grey : AppColors.pinkpetsy,
                    fontStyle: isUnavailable ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
            // 🔴 FIX: "!isUnavailable" tawa sa7i7 (chips yebanou dima
            // GHIR ken el category ma3roufa 7a9i9atan w had service
            // ma yesnedhech biha - mch bark ken price mazel null 7it
            // mafamech pet mkhtar l'hin).
            if (!isUnavailable) ...[
              SizedBox(height: sizes.screenHeight * 0.008),
              Wrap(
                spacing: sizes.screenWidth * 0.02,
                runSpacing: sizes.screenHeight * 0.006,
                children: [
                  for (final pet in _pets)
                    if (pet.id != null)
                      _miniPetChip(
                        sizes: sizes,
                        pet: pet,
                        isSelected: assignedPetIds.contains(pet.id),
                        onTap: () => _onServicePetTap(service, pet),
                        price: _priceForPetInService(service, pet),
                      ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}