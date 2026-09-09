import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../controllers/availability_controller.dart';
import 'message_dialog.dart';

// ============================================================================
// AvailabilityPicker
// ============================================================================
// 🔵 ZID (kifma tlab): widget mchtarek (yesta3mlouh el signup - étape
// jdida - W sitter_calender.dart - mode "Availability") - 3 tri9at
// bch el sitter y3allem el ayemet elli MA yekhdemch fihom:
//   1) chips el ayem fel jom3a (recurring - mathalan "kol el a7ad")
//   2) bouton "Mark public holidays" (a3yed tounsiya, dates fixa)
//   3) dass direct 3al calendrier (youm b'youm, mo7addad)
// 🔵 ZID (kifma tlab: "el disponibilité tzid horaire zeda") - zdt 2
// tri9at (heures, mch bark youmet kaملin):
//   4) plage horaire récurrente (mathalan "kol lil mel 22h l 7h")
//   5) créneaux ponctuels (youm mo7addad + heure mo7addda bark)
// ============================================================================
class AvailabilityPicker extends StatefulWidget {
  final Set<int> initialRecurringDaysOff; // 1=Mon..7=Sun
  final Set<DateTime> initialSpecificDatesOff;
  final RecurringHoursOff initialRecurringHoursOff;
  final List<SpecificHoursOffEntry> initialSpecificHoursOff;
  final ValueChanged<
      ({
        Set<int> recurringDaysOff,
        Set<DateTime> specificDatesOff,
        RecurringHoursOff recurringHoursOff,
        List<SpecificHoursOffEntry> specificHoursOff,
      })> onChanged;

  const AvailabilityPicker({
    super.key,
    this.initialRecurringDaysOff = const {},
    this.initialSpecificDatesOff = const {},
    this.initialRecurringHoursOff = const RecurringHoursOff(),
    this.initialSpecificHoursOff = const [],
    required this.onChanged,
  });

  @override
  State<AvailabilityPicker> createState() => _AvailabilityPickerState();
}

class _AvailabilityPickerState extends State<AvailabilityPicker> {
  late Set<int> _recurringDaysOff;
  late Set<DateTime> _specificDatesOff;
  late DateTime _displayedMonth;
  // 🔵 ZID (kifma tlab): "horaire zeda" - plage récurrente (nullable
  // l'kol zouj bounds - "mafamech blocage") + liste tel blocages
  // ponctuels (youm+heure).
  int? _recurringStartMinutes;
  int? _recurringEndMinutes;
  late List<SpecificHoursOffEntry> _specificHoursOff;

  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> _weekdayKeys = ['weekday_mon', 'weekday_tue', 'weekday_wed', 'weekday_thu', 'weekday_fri', 'weekday_sat', 'weekday_sun'];

  // 🔵 ZID: a3yed tounsiya (dates FIXA bark, mch el a3yed eddiniya -
  // hedhomen ye5telfou kol 3am bel calendrier el hijri, ye7taj esba7
  // ma tetzabtch bla librairie mkhassa) - el sitter ynajjam yzid/yenni
  // el ba9i b'rou7ou mel calendrier.
  static const List<({int month, int day})> _fixedHolidays = [
    (month: 1, day: 1), // Ras El Am
    (month: 1, day: 14), // Aid Ethawra
    (month: 3, day: 20), // Aid El Istiklal
    (month: 4, day: 9), // Aid Echouhada
    (month: 5, day: 1), // Aid Echoughl
    (month: 7, day: 25), // Aid El Joumhouria
    (month: 8, day: 13), // Aid El Mar2a
    (month: 10, day: 15), // Aid El Jala2
  ];

  @override
  void initState() {
    super.initState();
    _recurringDaysOff = {...widget.initialRecurringDaysOff};
    _specificDatesOff = {...widget.initialSpecificDatesOff.map(_dateOnly)};
    _recurringStartMinutes = widget.initialRecurringHoursOff.startMinutes;
    _recurringEndMinutes = widget.initialRecurringHoursOff.endMinutes;
    _specificHoursOff = [...widget.initialSpecificHoursOff];
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _notify() => widget.onChanged((
        recurringDaysOff: _recurringDaysOff,
        specificDatesOff: _specificDatesOff,
        recurringHoursOff: RecurringHoursOff(startMinutes: _recurringStartMinutes, endMinutes: _recurringEndMinutes),
        specificHoursOff: _specificHoursOff,
      ));

  void _toggleRecurringDay(int weekday) {
    setState(() {
      if (_recurringDaysOff.contains(weekday)) {
        _recurringDaysOff.remove(weekday);
      } else {
        _recurringDaysOff.add(weekday);
      }
    });
    _notify();
  }

  void _toggleSpecificDate(DateTime day) {
    final d = _dateOnly(day);
    // 🔵 youm déjà "off" b'recurring - ma nenajjmouch nbeddlouh houni
    // (chrahtha fou9, mch exception system - "off" kifma kif).
    if (_recurringDaysOff.contains(d.weekday)) return;

    setState(() {
      if (_specificDatesOff.contains(d)) {
        _specificDatesOff.remove(d);
      } else {
        _specificDatesOff.add(d);
      }
    });
    _notify();
  }

  // 🔵 ZID (kifma tlab: "el disponibilité tzid horaire zeda") - "HH:mm"
  // mel d9ay9 (0-1439) - esta3malha l'el résumé w l'el initialTime tel
  // showTimePicker.
  String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickRecurringTime({required bool isStart}) async {
    final int initialMinutes = (isStart ? _recurringStartMinutes : _recurringEndMinutes) ?? (isStart ? 22 * 60 : 7 * 60);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialMinutes ~/ 60, minute: initialMinutes % 60),
    );
    if (picked == null) return;
    setState(() {
      final minutes = picked.hour * 60 + picked.minute;
      if (isStart) {
        _recurringStartMinutes = minutes;
      } else {
        _recurringEndMinutes = minutes;
      }
    });
    _notify();
  }

  void _clearRecurringHours() {
    setState(() {
      _recurringStartMinutes = null;
      _recurringEndMinutes = null;
    });
    _notify();
  }

  // 🔵 ZID (kifma tlab: "wla 1h/wa9t mo7addad fi nhar mo7addad") -
  // dialog sghira: date + heure debut + heure fin -> tzid fel liste.
  Future<void> _addSpecificHoursEntry() async {
    DateTime? tempDate;
    int? tempStartMinutes;
    int? tempEndMinutes;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            final sizes = AppSizes.of(dialogContext);
            return AlertDialog(
              title: Text('specific_hours_off_dialog_title'.tr()),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(context: dialogContext, initialDate: tempDate ?? now, firstDate: now, lastDate: now.add(const Duration(days: 365)));
                      if (picked != null) setDialogState(() => tempDate = picked);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.01),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: sizes.myProfileBodyFontSize * 0.85, color: AppColors.pinkpetsy),
                          SizedBox(width: sizes.screenWidth * 0.025),
                          Text(tempDate != null ? '${tempDate!.day}/${tempDate!.month}/${tempDate!.year}' : 'availability_pick_date_placeholder'.tr()),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: dialogContext, initialTime: const TimeOfDay(hour: 14, minute: 0));
                      if (picked != null) setDialogState(() => tempStartMinutes = picked.hour * 60 + picked.minute);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.01),
                      child: Row(
                        children: [
                          Icon(Icons.access_time, size: sizes.myProfileBodyFontSize * 0.85, color: AppColors.pinkpetsy),
                          SizedBox(width: sizes.screenWidth * 0.025),
                          Text('${'specific_hours_off_from_label'.tr()}: ${tempStartMinutes != null ? _formatMinutes(tempStartMinutes!) : 'availability_pick_time_placeholder'.tr()}'),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(context: dialogContext, initialTime: const TimeOfDay(hour: 15, minute: 0));
                      if (picked != null) setDialogState(() => tempEndMinutes = picked.hour * 60 + picked.minute);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.01),
                      child: Row(
                        children: [
                          Icon(Icons.access_time_filled, size: sizes.myProfileBodyFontSize * 0.85, color: AppColors.pinkpetsy),
                          SizedBox(width: sizes.screenWidth * 0.025),
                          Text('${'specific_hours_off_to_label'.tr()}: ${tempEndMinutes != null ? _formatMinutes(tempEndMinutes!) : 'availability_pick_time_placeholder'.tr()}'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('cancel_button'.tr())),
                TextButton(
                  onPressed: () {
                    if (tempDate == null || tempStartMinutes == null || tempEndMinutes == null || tempStartMinutes == tempEndMinutes) {
                      showMessageDialog(dialogContext, 'specific_hours_off_invalid_error'.tr());
                      return;
                    }
                    setState(() {
                      _specificHoursOff.add(SpecificHoursOffEntry(date: _dateOnly(tempDate!), startMinutes: tempStartMinutes!, endMinutes: tempEndMinutes!));
                    });
                    _notify();
                    Navigator.pop(dialogContext);
                  },
                  child: Text('apply_button'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeSpecificHoursEntry(int index) {
    setState(() => _specificHoursOff.removeAt(index));
    _notify();
  }

  void _markPublicHolidays() {
    setState(() {
      final int currentYear = DateTime.now().year;
      for (final year in [currentYear, currentYear + 1]) {
        for (final h in _fixedHolidays) {
          _specificDatesOff.add(DateTime(year, h.month, h.day));
        }
      }
    });
    _notify();
    showMessageDialog(context, 'public_holidays_marked_toast'.tr());
  }

  void _changeMonth(int delta) {
    setState(() => _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + delta, 1));
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    final int firstWeekday = DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday;
    final int daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final DateTime prevMonthLast = DateTime(_displayedMonth.year, _displayedMonth.month, 0);
    final int leadingDays = firstWeekday - 1;
    final int totalCells = ((leadingDays + daysInMonth) / 7).ceil() * 7;
    final DateTime today = _dateOnly(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --------------------------------------------------------
        // 1) Chips: ayemet fixa fel jom3a
        // --------------------------------------------------------
        Text('recurring_days_off_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9)),
        SizedBox(height: sizes.screenHeight * 0.01),
        Wrap(
          spacing: sizes.screenWidth * 0.02,
          runSpacing: sizes.screenHeight * 0.01,
          children: [
            for (int weekday = 1; weekday <= 7; weekday++)
              _dayChip(sizes, label: _weekdayKeys[weekday - 1].tr(), selected: _recurringDaysOff.contains(weekday), onTap: () => _toggleRecurringDay(weekday)),
          ],
        ),

        SizedBox(height: sizes.screenHeight * 0.02),

        // --------------------------------------------------------
        // 2) Bouton "Mark public holidays"
        // --------------------------------------------------------
        InkWell(
          onTap: _markPublicHolidays,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.013),
            decoration: BoxDecoration(color: AppColors.vertpetsy.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.celebration_outlined, color: AppColors.vertpetsy, size: sizes.myProfileBodyFontSize),
                SizedBox(width: sizes.screenWidth * 0.02),
                Text('mark_public_holidays_button'.tr(), style: TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.85)),
              ],
            ),
          ),
        ),

        SizedBox(height: sizes.screenHeight * 0.024),

        // --------------------------------------------------------
        // 3) Calendrier - dass direct 3al youm
        // --------------------------------------------------------
        Text('specific_days_off_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9)),
        SizedBox(height: sizes.screenHeight * 0.012),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left), color: AppColors.pinkpetsy, onPressed: () => _changeMonth(-1)),
            Text('${_monthNames[_displayedMonth.month - 1]} ${_displayedMonth.year}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9)),
            IconButton(icon: const Icon(Icons.chevron_right), color: AppColors.pinkpetsy, onPressed: () => _changeMonth(1)),
          ],
        ),
        Row(
          children: [
            for (final key in _weekdayKeys)
              Expanded(child: Center(child: Text(key.tr(), style: TextStyle(fontSize: sizes.calendarCellFont * 0.8, fontWeight: FontWeight.w600, color: mutedTextColor)))),
          ],
        ),
        SizedBox(height: sizes.screenHeight * 0.006),
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

            final bool isRecurringOff = inCurrentMonth && _recurringDaysOff.contains(cellDate.weekday);
            final bool isSpecificOff = inCurrentMonth && _specificDatesOff.contains(_dateOnly(cellDate));
            final bool isOff = isRecurringOff || isSpecificOff;
            final bool isToday = _dateOnly(cellDate) == today;

            return InkWell(
              onTap: (inCurrentMonth && !isRecurringOff) ? () => _toggleSpecificDate(cellDate) : null,
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: EdgeInsets.all(sizes.screenWidth * 0.006),
                child: Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.01),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOff ? AppColors.error.withOpacity(0.15) : Colors.transparent,
                    border: isToday && !isOff ? Border.all(color: AppColors.vertpetsy, width: 1.4) : null,
                  ),
                  child: Text(
                    '${cellDate.day}',
                    style: TextStyle(
                      fontSize: sizes.calendarCellFont,
                      fontWeight: isOff ? FontWeight.bold : FontWeight.normal,
                      color: !inCurrentMonth ? mutedTextColor.withOpacity(0.35) : (isOff ? AppColors.error : null),
                      decoration: isOff ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: sizes.screenHeight * 0.01),
        Row(
          children: [
            Icon(Icons.circle, size: sizes.screenWidth * 0.025, color: AppColors.error.withOpacity(0.5)),
            SizedBox(width: sizes.screenWidth * 0.015),
            Text('day_off_legend_label'.tr(), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.7, color: mutedTextColor)),
          ],
        ),

        SizedBox(height: sizes.screenHeight * 0.024),

        // --------------------------------------------------------
        // 4) Plage horaire récurrente (kifma tlab: "mel 22h hatta
        // l 7h ma ye5demch")
        // --------------------------------------------------------
        Text('recurring_hours_off_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9)),
        SizedBox(height: sizes.screenHeight * 0.004),
        Text('recurring_hours_off_hint'.tr(), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.72, color: mutedTextColor)),
        SizedBox(height: sizes.screenHeight * 0.01),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickRecurringTime(isStart: true),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenHeight * 0.012),
                  decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: sizes.myProfileBodyFontSize * 0.8, color: AppColors.pinkpetsy),
                      SizedBox(width: sizes.screenWidth * 0.02),
                      Text(
                        _recurringStartMinutes != null ? _formatMinutes(_recurringStartMinutes!) : 'availability_pick_time_placeholder'.tr(),
                        style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.82),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: sizes.screenWidth * 0.03),
            Icon(Icons.arrow_forward, size: sizes.myProfileBodyFontSize * 0.8, color: mutedTextColor),
            SizedBox(width: sizes.screenWidth * 0.03),
            Expanded(
              child: InkWell(
                onTap: () => _pickRecurringTime(isStart: false),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenHeight * 0.012),
                  decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time_filled, size: sizes.myProfileBodyFontSize * 0.8, color: AppColors.pinkpetsy),
                      SizedBox(width: sizes.screenWidth * 0.02),
                      Text(
                        _recurringEndMinutes != null ? _formatMinutes(_recurringEndMinutes!) : 'availability_pick_time_placeholder'.tr(),
                        style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.82),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_recurringStartMinutes != null || _recurringEndMinutes != null) ...[
              SizedBox(width: sizes.screenWidth * 0.02),
              IconButton(
                onPressed: _clearRecurringHours,
                icon: Icon(Icons.close, color: AppColors.error, size: sizes.myProfileBodyFontSize * 0.9),
                tooltip: 'availability_clear_button'.tr(),
              ),
            ],
          ],
        ),

        SizedBox(height: sizes.screenHeight * 0.024),

        // --------------------------------------------------------
        // 5) Créneaux ponctuels (kifma tlab: "wla 1h/wa9t mo7addad
        // fi nhar mo7addad")
        // --------------------------------------------------------
        Text('specific_hours_off_label'.tr(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.9)),
        SizedBox(height: sizes.screenHeight * 0.01),
        if (_specificHoursOff.isEmpty)
          Text('no_specific_hours_off_label'.tr(), style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.78, color: mutedTextColor))
        else
          for (int i = 0; i < _specificHoursOff.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: sizes.screenHeight * 0.008),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenHeight * 0.01),
                decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.event_busy, size: sizes.myProfileBodyFontSize * 0.85, color: AppColors.error),
                    SizedBox(width: sizes.screenWidth * 0.025),
                    Expanded(
                      child: Text(
                        '${_specificHoursOff[i].date.day}/${_specificHoursOff[i].date.month}: ${_formatMinutes(_specificHoursOff[i].startMinutes)} - ${_formatMinutes(_specificHoursOff[i].endMinutes)}',
                        style: TextStyle(fontSize: sizes.myProfileBodyFontSize * 0.8),
                      ),
                    ),
                    InkWell(
                      onTap: () => _removeSpecificHoursEntry(i),
                      child: Icon(Icons.close, size: sizes.myProfileBodyFontSize * 0.85, color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ),
        SizedBox(height: sizes.screenHeight * 0.008),
        InkWell(
          onTap: _addSpecificHoursEntry,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.013),
            decoration: BoxDecoration(color: AppColors.vertpetsy.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, color: AppColors.vertpetsy, size: sizes.myProfileBodyFontSize),
                SizedBox(width: sizes.screenWidth * 0.02),
                Text('add_specific_hours_off_button'.tr(), style: TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.85)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _dayChip(AppSizes sizes, {required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.035, vertical: sizes.screenHeight * 0.009),
        decoration: BoxDecoration(
          color: selected ? AppColors.error.withOpacity(0.85) : AppColors.pinkpetsy.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : null, fontWeight: FontWeight.w600, fontSize: sizes.myProfileBodyFontSize * 0.78)),
      ),
    );
  }
}