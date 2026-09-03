import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
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
// ============================================================================
class AvailabilityPicker extends StatefulWidget {
  final Set<int> initialRecurringDaysOff; // 1=Mon..7=Sun
  final Set<DateTime> initialSpecificDatesOff;
  final ValueChanged<({Set<int> recurringDaysOff, Set<DateTime> specificDatesOff})> onChanged;

  const AvailabilityPicker({
    super.key,
    this.initialRecurringDaysOff = const {},
    this.initialSpecificDatesOff = const {},
    required this.onChanged,
  });

  @override
  State<AvailabilityPicker> createState() => _AvailabilityPickerState();
}

class _AvailabilityPickerState extends State<AvailabilityPicker> {
  late Set<int> _recurringDaysOff;
  late Set<DateTime> _specificDatesOff;
  late DateTime _displayedMonth;

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
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  void _notify() => widget.onChanged((recurringDaysOff: _recurringDaysOff, specificDatesOff: _specificDatesOff));

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