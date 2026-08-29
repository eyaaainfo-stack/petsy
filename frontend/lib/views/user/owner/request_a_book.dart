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
  final Set<String> _selectedPetIds = {};
  final Set<String> _selectedServiceIds = {};

  final BookingController _controller = BookingController();
  bool _isSubmitting = false;

  // 🔵 ZID (kifma tlab): "el owner ma yenajjamch ye5tar youm el sitter
  // mch dispo fih" - njiboha mel profile el 3am tel sitter (déjà 3andou
  // les 2 champs, chrahtha sitter_calender.dart/availability_picker.dart).
  final MyProfileController _profileController = MyProfileController();
  List<int> _recurringDaysOff = [];
  List<DateTime> _specificDatesOff = [];

  static const Map<String, String> _serviceLabelKeys = {
    'house_sitting': 'sitter_service_house_sitting',
    'dog_walking': 'sitter_service_dog_walking',
    'doggy_day_care': 'sitter_service_doggy_day_care',
    'boarding': 'sitter_service_boarding',
    'overnight_stays': 'sitter_service_overnight_stays',
    'home_visits': 'sitter_service_home_visits',
  };

  String _serviceLabel(String serviceId) {
    final key = _serviceLabelKeys[serviceId];
    return key != null ? key.tr() : serviceId;
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

  double get _total {
    double sum = 0;
    for (final service in widget.sitterServices) {
      if (_selectedServiceIds.contains(service.serviceId)) sum += service.price;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('select_date_error'.tr())));
      return;
    }
    // 🔵 ZID (filet de sécurité): lowkan el data tel disponibilité
    // weslet METAKHRA (async, ba3d ma el user déjà 5tar el date) - nre-
    // chekkou houni zeda 9bal el ib3ath.
    if (_isDateUnavailable(_selectedDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('sitter_unavailable_this_day_error'.tr())));
      return;
    }
    if (_selectedPetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('select_pet_error'.tr())));
      return;
    }
    if (_selectedServiceIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('select_service_error'.tr())));
      return;
    }
    final checkIn = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _checkInTime.hour, _checkInTime.minute);
    final checkOut = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _checkOutTime.hour, _checkOutTime.minute);

    // 🔴 FIX (kifma tlab): checkout lezmou ykoun BA3D checkin.
    if (!checkOut.isAfter(checkIn)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('checkout_before_checkin_error'.tr())));
      return;
    }
    // 🔴 FIX (kifma tlab): checkin lezmou ykoun 3al a9al SA3A wa7da
    // mel wa9t el 7ali.
    if (checkIn.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('checkin_too_soon_error'.tr())));
      return;
    }

    setState(() => _isSubmitting = true);

    final servicesPayload = [
      for (final s in widget.sitterServices)
        if (_selectedServiceIds.contains(s.serviceId)) {'serviceId': s.serviceId, 'price': s.price},
    ];

    final result = await _controller.createBooking(
      sitterId: widget.sitterId,
      petIds: _selectedPetIds.toList(),
      services: servicesPayload,
      checkIn: checkIn,
      checkOut: checkOut,
      total: _total,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorMessage ?? 'login_generic_error'.tr())));
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
                  // Service for (pets - data 7a9i9iya)
                  // --------------------------------------------------
                  Text('service_for_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                  SizedBox(height: sizes.rabSectionGap * 0.6),
                  _isLoadingPets
                      ? const Center(child: CircularProgressIndicator())
                      : _pets.isEmpty
                          ? Text('no_pets_yet_label'.tr(), style: TextStyle(color: Colors.grey.shade600))
                          : Wrap(
                              spacing: sizes.screenWidth * 0.03,
                              runSpacing: sizes.screenHeight * 0.012,
                              children: [
                                for (final pet in _pets)
                                  if (pet.id != null)
                                    _petChip(
                                      sizes: sizes,
                                      pet: pet,
                                      isSelected: _selectedPetIds.contains(pet.id),
                                      onTap: () => setState(() {
                                        if (!_selectedPetIds.remove(pet.id!)) _selectedPetIds.add(pet.id!);
                                      }),
                                    ),
                              ],
                            ),

                  SizedBox(height: sizes.rabSectionGap),

                  // --------------------------------------------------
                  // 🔴 FIX (kifma tlab): "Service Type" - GHIR el
                  // services el 7a9i9iyin elli el SITTER 3andou (mch
                  // liste thabta) - kol wa7ed m3ah prix, w total.
                  // --------------------------------------------------
                  Text('sitter_services_offered_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                  SizedBox(height: sizes.rabSectionGap * 0.6),
                  if (widget.sitterServices.isEmpty)
                    Text('no_urgent_services_label'.tr(), style: TextStyle(color: Colors.grey.shade600))
                  else
                    for (final service in widget.sitterServices) _serviceCheckRow(sizes: sizes, service: service),

                  SizedBox(height: sizes.rabSectionGap * 0.6),
                  // 🔵 ZID (kifma tlab): total 7ay (yetbeddel automatique
                  // ki tzid/tna77i service).
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
                          ? () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('sitter_unavailable_this_day_error'.tr())))
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

  Widget _petChip({required AppSizes sizes, required PetSummary pet, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.02, vertical: sizes.screenHeight * 0.008),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.vertpetsy.withOpacity(0.2) : Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: isSelected ? AppColors.vertpetsy : Colors.transparent, width: 1.6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipOval(
              child: Container(
                width: sizes.screenWidth * 0.08,
                height: sizes.screenWidth * 0.08,
                color: AppColors.pinkpetsy.withOpacity(0.15),
                child: pet.photoBytes != null
                    ? Image.memory(pet.photoBytes!, fit: BoxFit.cover)
                    : pet.photoUrl != null
                        ? Image.network(pet.photoUrl!, fit: BoxFit.cover)
                        : Icon(pet.icon, color: AppColors.pinkpetsy, size: sizes.screenWidth * 0.04),
              ),
            ),
            SizedBox(width: sizes.screenWidth * 0.02),
            Text(pet.name, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? AppColors.vertpetsy : null)),
          ],
        ),
      ),
    );
  }

  Widget _serviceCheckRow({required AppSizes sizes, required SitterServiceEntry service}) {
    final bool isSelected = _selectedServiceIds.contains(service.serviceId);
    return InkWell(
      onTap: () => setState(() {
        if (!_selectedServiceIds.remove(service.serviceId)) _selectedServiceIds.add(service.serviceId);
      }),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.006),
        child: Row(
          children: [
            Checkbox(
              value: isSelected,
              activeColor: AppColors.pinkpetsy,
              onChanged: (_) => setState(() {
                if (!_selectedServiceIds.remove(service.serviceId)) _selectedServiceIds.add(service.serviceId);
              }),
            ),
            Expanded(child: Text(_serviceLabel(service.serviceId))),
            Text('${service.price.toStringAsFixed(0)} DT', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.pinkpetsy)),
          ],
        ),
      ),
    );
  }
}