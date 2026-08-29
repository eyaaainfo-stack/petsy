import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../controllers/sitter_calender_controller.dart';
import '../../../controllers/availability_controller.dart';
import '../../../widgets/availability_picker.dart';
import 'request.dart';

// ============================================================================
// SitterCalenderScreen ("Calender") - sitter
// ============================================================================
// 🔵 Wsulha mel sidebar (sitter, item "Calendar") - GET /api/bookings/
// my-schedule (bookings "accepted" tel sitter el 7ali). El grid ywarri
// no9ta ta7t kol youm fih service (checkIn -> checkOut, el youmayn el
// 2 minhom), w "Upcoming events" twarri el liste el kaملha (wela GHIR
// el youm el mkhtar, lowkan el sitter dass 3al date fel grid).
// ============================================================================
class SitterCalenderScreen extends StatefulWidget {
  const SitterCalenderScreen({super.key});

  @override
  State<SitterCalenderScreen> createState() => _SitterCalenderScreenState();
}

class _SitterCalenderScreenState extends State<SitterCalenderScreen> {
  final SitterCalenderController _controller = SitterCalenderController();
  List<ScheduleBooking> _schedule = [];
  bool _isLoading = true;

  late DateTime _displayedMonth; // youm 1 tel choir el mban (grid)
  DateTime? _selectedDate; // null = "Upcoming events" ywarri EL KOL

  // 🔵 ZID (kifma tlab): mode "Availability" (jamb "Bookings") - ayemet
  // el sitter MA yekhdemch fihom (nafs widget AvailabilityPicker tel signup).
  bool _isAvailabilityMode = false;
  bool _isLoadingAvailability = false;
  bool _hasLoadedAvailability = false;
  bool _isSavingAvailability = false;
  Set<int> _recurringDaysOff = {};
  Set<DateTime> _specificDatesOff = {};
  final AvailabilityController _availabilityController = AvailabilityController();

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> _weekdayKeys = ['weekday_mon', 'weekday_tue', 'weekday_wed', 'weekday_thu', 'weekday_fri', 'weekday_sat', 'weekday_sun'];

  static const Map<String, String> _serviceLabelKeys = {
    'house_sitting': 'sitter_service_house_sitting',
    'dog_walking': 'sitter_service_dog_walking',
    'doggy_day_care': 'sitter_service_doggy_day_care',
    'boarding': 'sitter_service_boarding',
    'overnight_stays': 'sitter_service_overnight_stays',
    'home_visits': 'sitter_service_home_visits',
  };

  static const Map<String, IconData> _serviceIcons = {
    'house_sitting': Icons.house_outlined,
    'dog_walking': Icons.directions_walk,
    'doggy_day_care': Icons.wb_sunny_outlined,
    'boarding': Icons.hotel_outlined,
    'overnight_stays': Icons.nightlight_outlined,
    'home_visits': Icons.home_outlined,
  };

  // ==========================================================================
  // Mode "Availability"
  // ==========================================================================
  Future<void> _toggleAvailabilityMode() async {
    setState(() => _isAvailabilityMode = !_isAvailabilityMode);
    if (_isAvailabilityMode && !_hasLoadedAvailability) {
      setState(() => _isLoadingAvailability = true);
      final availability = await _availabilityController.fetchAvailability();
      if (!mounted) return;
      setState(() {
        if (availability != null) {
          _recurringDaysOff = availability.recurringDaysOff.toSet();
          _specificDatesOff = availability.specificDatesOff.map((d) => DateTime(d.year, d.month, d.day)).toSet();
        }
        _hasLoadedAvailability = true;
        _isLoadingAvailability = false;
      });
    }
  }

  Future<void> _onSaveAvailability() async {
    if (_isSavingAvailability) return;
    setState(() => _isSavingAvailability = true);
    final success = await _availabilityController.submitAvailability(
      recurringDaysOff: _recurringDaysOff.toList(),
      specificDatesOff: _specificDatesOff.toList(),
    );
    if (!mounted) return;
    setState(() => _isSavingAvailability = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'availability_saved_toast'.tr() : 'profile_submit_error'.tr())),
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final schedule = await _controller.fetchMySchedule();
    if (!mounted) return;
    setState(() {
      _schedule = schedule;
      _isLoading = false;
    });
  }

  // 🔵 ZID (fix timezone): ".toLocal()" 9bal ma ne5dou .year/.month/.day -
  // "d" ynajjam ykoun UTC-flagged (mel backend, checkIn/checkOut) - bla
  // ".toLocal()" el "youm" (calendar day) ynajjam ykoun DIFFERENT 3an
  // el youm el 7a9i9i tel user (mathalan booking f 00:30 Tunisie =
  // 23:30 UTC youm 9bal - bla conversion tban "youm 9bal" bel ghalat).
  DateTime _dateOnly(DateTime d) {
    final local = d.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  // 🔵 kol el youmet mel checkIn l'el checkOut (be9raîna) - bch el
  // no9ta tban fel grid l'kol el youmet elli el sitter "occupé" fihom.
  bool _hasEventOn(DateTime day) {
    final d = _dateOnly(day);
    for (final b in _schedule) {
      if (!d.isBefore(_dateOnly(b.checkIn)) && !d.isAfter(_dateOnly(b.checkOut))) return true;
    }
    return false;
  }

  // 🔵 ZID (kifma tlab): "yjiw bel mnadham 7asb el wa9t" - sort explicite
  // (defensive - mch mou3tamdin ghir 3al backend, el liste tab9a mrattba
  // dima 7ata ba3d filtrage b date mo7addad).
  List<ScheduleBooking> get _visibleEvents {
    final List<ScheduleBooking> base;
    if (_selectedDate == null) {
      base = _schedule;
    } else {
      final d = _dateOnly(_selectedDate!);
      base = _schedule.where((b) => !d.isBefore(_dateOnly(b.checkIn)) && !d.isAfter(_dateOnly(b.checkOut))).toList();
    }
    final sorted = [...base]..sort((a, b) => a.checkIn.compareTo(b.checkIn));
    return sorted;
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + delta, 1);
      _selectedDate = null; // 🔵 choir jdid -> na9sou el filtre (bla ha "date" mel choir el9dim ye5tafi el liste)
    });
  }

  void _onDateTap(DateTime day) {
    setState(() {
      // 🔵 dass 3ala NAFS el date el mkhtara -> ye5ta3ha (n3awdou lel "Upcoming events" el kol).
      _selectedDate = (_selectedDate != null && _dateOnly(_selectedDate!) == _dateOnly(day)) ? null : day;
    });
  }

  String _serviceLabel(String id) => _serviceLabelKeys[id] != null ? _serviceLabelKeys[id]!.tr() : id;

  IconData _serviceIcon(List<String> serviceIds) => serviceIds.isNotEmpty ? (_serviceIcons[serviceIds.first] ?? Icons.pets) : Icons.pets;

  String _dateLabel(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  // 🔵 ZID (fix timezone): ".toLocal()" 9bal .hour/.minute - mnghirha,
  // el wa9t elli yban fel écran ynajjam ykoun UTC (mch Tunisie).
  String _timeLabel(DateTime t) {
    final local = t.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    final DateTime today = _dateOnly(DateTime.now());
    final int firstWeekday = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday; // 1=Mon..7=Sun
    final int daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final DateTime prevMonthLast = DateTime(_displayedMonth.year, _displayedMonth.month, 0);
    final int leadingDays = firstWeekday - 1; // 0..6
    final int totalCells = ((leadingDays + daysInMonth) / 7).ceil() * 7;

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
                      padding: EdgeInsets.symmetric(horizontal: sizes.calendarHorizontalPadding),
                      children: [
                        SizedBox(height: sizes.calendarTopGap),
                        Center(
                          child: Text('sitter_calendar_title'.tr(), style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileNameFontSize)),
                        ),
                        SizedBox(height: sizes.calendarSectionGap),

                        // ---------------------------------------------
                        // Toggle "Bookings" / "Availability" (kifma tlab)
                        // ---------------------------------------------
                        Row(
                          children: [
                            Expanded(child: _modeTab(sizes, label: 'bookings_label'.tr(), selected: !_isAvailabilityMode, onTap: () { if (_isAvailabilityMode) _toggleAvailabilityMode(); })),
                            SizedBox(width: sizes.screenWidth * 0.02),
                            Expanded(child: _modeTab(sizes, label: 'availability_label'.tr(), selected: _isAvailabilityMode, onTap: () { if (!_isAvailabilityMode) _toggleAvailabilityMode(); })),
                          ],
                        ),
                        SizedBox(height: sizes.calendarSectionGap),

                        if (_isAvailabilityMode) ..._availabilityModeChildren(sizes) else ..._bookingsModeChildren(sizes, isDark, mutedTextColor, today, firstWeekday, daysInMonth, prevMonthLast, leadingDays, totalCells),
                      ],
                    ),
            ),

            const CustomBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(AppSizes sizes, {required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.01),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.pinkpetsy : AppColors.pinkpetsy.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.85)),
      ),
    );
  }

  List<Widget> _availabilityModeChildren(AppSizes sizes) {
    if (_isLoadingAvailability) {
      return [Padding(padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.08), child: const Center(child: CircularProgressIndicator()))];
    }
    return [
      AvailabilityPicker(
        initialRecurringDaysOff: _recurringDaysOff,
        initialSpecificDatesOff: _specificDatesOff,
        onChanged: (value) {
          _recurringDaysOff = value.recurringDaysOff;
          _specificDatesOff = value.specificDatesOff;
        },
      ),
      SizedBox(height: sizes.calendarSectionGap * 1.4),
      SizedBox(
        height: sizes.screenHeight * 0.06,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.vertpetsy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)), elevation: 0),
          onPressed: _isSavingAvailability ? null : _onSaveAvailability,
          child: Text(
            _isSavingAvailability ? 'loading_label'.tr() : 'save_button'.tr(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9),
          ),
        ),
      ),
      SizedBox(height: sizes.myProfileBottomGap),
    ];
  }

  List<Widget> _bookingsModeChildren(
    AppSizes sizes,
    bool isDark,
    Color mutedTextColor,
    DateTime today,
    int firstWeekday,
    int daysInMonth,
    DateTime prevMonthLast,
    int leadingDays,
    int totalCells,
  ) {
    return [
                        // ---------------------------------------------
                        // Mois + fleches
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(icon: const Icon(Icons.chevron_left), color: AppColors.pinkpetsy, onPressed: () => _changeMonth(-1)),
                            Text('${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                            IconButton(icon: const Icon(Icons.chevron_right), color: AppColors.pinkpetsy, onPressed: () => _changeMonth(1)),
                          ],
                        ),

                        SizedBox(height: sizes.calendarSectionGap * 0.5),

                        // ---------------------------------------------
                        // Esmeh el ayem (Mon..Sun)
                        // ---------------------------------------------
                        Row(
                          children: [
                            for (final w in _weekdayKeys)
                              Expanded(child: Center(child: Text(w.tr(), style: TextStyle(fontSize: sizes.calendarCellFont * 0.85, fontWeight: FontWeight.w600, color: mutedTextColor)))),
                          ],
                        ),
                        SizedBox(height: sizes.calendarSectionGap * 0.4),

                        // ---------------------------------------------
                        // Grid tel ayem
                        // ---------------------------------------------
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: totalCells,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
                          itemBuilder: (context, index) {
                            final int dayOffset = index - leadingDays;
                            late final DateTime cellDate;
                            late final bool inCurrentMonth;
                            if (dayOffset < 0) {
                              cellDate = DateTime(prevMonthLast.year, prevMonthLast.month, prevMonthLast.day + dayOffset + 1);
                              inCurrentMonth = false;
                            } else if (dayOffset >= daysInMonth) {
                              cellDate = DateTime(_displayedMonth.year, _displayedMonth.month + 1, dayOffset - daysInMonth + 1);
                              inCurrentMonth = false;
                            } else {
                              cellDate = DateTime(_displayedMonth.year, _displayedMonth.month, dayOffset + 1);
                              inCurrentMonth = true;
                            }

                            final bool isToday = _dateOnly(cellDate) == today;
                            final bool isSelected = _selectedDate != null && _dateOnly(_selectedDate!) == _dateOnly(cellDate);
                            final bool hasEvent = inCurrentMonth && _hasEventOn(cellDate);

                            return InkWell(
                              onTap: inCurrentMonth ? () => _onDateTap(cellDate) : null,
                              borderRadius: BorderRadius.circular(30),
                              child: Padding(
                                padding: EdgeInsets.all(sizes.screenWidth * 0.006),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? AppColors.pinkpetsy : (isToday ? AppColors.vertpetsy.withOpacity(0.18) : Colors.transparent),
                                    border: isToday && !isSelected ? Border.all(color: AppColors.vertpetsy, width: 1.4) : null,
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.01),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${cellDate.day}',
                                        style: TextStyle(
                                          fontSize: sizes.calendarCellFont,
                                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                          color: isSelected ? Colors.white : (!inCurrentMonth ? mutedTextColor.withOpacity(0.4) : null),
                                        ),
                                      ),
                                      SizedBox(height: sizes.screenHeight * 0.003),
                                      SizedBox(
                                        width: sizes.calendarDotSize,
                                        height: sizes.calendarDotSize,
                                        child: hasEvent
                                            ? DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: isSelected ? Colors.white : AppColors.pinkpetsy))
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: sizes.calendarSectionGap * 1.4),

                        Text('upcoming_events_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize)),
                        SizedBox(height: sizes.calendarSectionGap * 0.6),

                        if (_visibleEvents.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.06),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.event_note_outlined, color: mutedTextColor.withOpacity(0.5), size: sizes.bookingEmptyStateIcon),
                                  SizedBox(height: sizes.screenHeight * 0.012),
                                  Text('no_scheduled_events_label'.tr(), style: TextStyle(color: mutedTextColor)),
                                ],
                              ),
                            ),
                          )
                        else
                          for (final booking in _visibleEvents) ...[
                            _eventCard(sizes: sizes, booking: booking, isDark: isDark, mutedTextColor: mutedTextColor),
                            SizedBox(height: sizes.calendarSectionGap * 0.6),
                          ],

                        SizedBox(height: sizes.myProfileBottomGap),
    ];
  }

  Widget _eventCard({required AppSizes sizes, required ScheduleBooking booking, required bool isDark, required Color mutedTextColor}) {
    // 🔵 ZID (kifma tlab): "eli deja fait w terminee ywalli b loun ekher" -
    // el service khlas wa9tou (checkOut 3adda) -> card mkhaffta (loun
    // rassed, mch abraz kifma el eli mazel jayya/9a3da).
    final bool isFinished = DateTime.now().isAfter(booking.checkOut);

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => RequestScreen(bookingId: booking.id, fromCalendar: true)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Opacity(
        opacity: isFinished ? 0.55 : 1,
        child: Container(
          padding: EdgeInsets.all(sizes.screenWidth * 0.03),
          decoration: BoxDecoration(
            color: isFinished
                ? (isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade200)
                : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('${_dateLabel(booking.checkIn)} | ${_timeLabel(booking.checkIn)}', style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.72, color: mutedTextColor))),
                  if (isFinished)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.02, vertical: sizes.screenHeight * 0.003),
                      decoration: BoxDecoration(color: mutedTextColor.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: Text('booking_status_completed'.tr(), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.65, color: mutedTextColor, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              SizedBox(height: sizes.screenHeight * 0.006),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(sizes.screenWidth * 0.018),
                    decoration: BoxDecoration(color: (isFinished ? mutedTextColor : AppColors.vertpetsy).withOpacity(0.15), shape: BoxShape.circle),
                    child: Icon(_serviceIcon(booking.serviceIds), color: isFinished ? mutedTextColor : AppColors.vertpetsy, size: sizes.calendarEventIconSize * 0.5),
                  ),
                  SizedBox(width: sizes.screenWidth * 0.025),
                  Expanded(
                    child: Text(
                      booking.serviceIds.isEmpty ? '-' : booking.serviceIds.map(_serviceLabel).join(' + '),
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: sizes.myProfileBodyFontSize * 0.85),
                    ),
                  ),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(sizes.calendarEventIconSize / 2),
                    child: Container(
                      width: sizes.calendarEventIconSize,
                      height: sizes.calendarEventIconSize,
                      color: AppColors.pinkpetsy.withOpacity(0.15),
                      child: booking.firstPetPhotoUrl != null
                          ? Image.network(booking.firstPetPhotoUrl!, fit: BoxFit.cover)
                          : Icon(Icons.pets, color: AppColors.pinkpetsy, size: sizes.calendarEventIconSize * 0.55),
                    ),
                  ),
                  SizedBox(width: sizes.screenWidth * 0.015),
                  Text(booking.petNames, style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.78, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}