import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../controllers/admin_stats_controller.dart';
import '../../../models/admin_stats.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/paw_widget.dart';
import '../../../widgets/line_chart_widget.dart';

// ============================================================================
// AdminDashboardScreen ("Tableau de bord")
// ============================================================================
// 🔵 ZID: kifma tlab - "Graphique linéaire standard 3ala kol chher, lel
// users lkol bloun, owners bloun, sitters bloun, courier bloun, W el
// forsa nbadel el période mel 1 l'12 mois" - GET
// /api/admin/registrations/monthly?months=N (N mel Slider ta7t).
//
// 🔵 el 4ème loun (couriers) mch mel AppColors el 3adiya (ghir pink/vert
// mawjoudin) - zedneh houni local bark (specific lel chart hedha).
//
// 🔴 FIX (rappel AppSizes): sizes.adminDashXxx (mch MediaQuery direct).
// ============================================================================
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color _totalColor = AppColors.primarySeed;
  static const Color _ownerColor = AppColors.pinkpetsy;
  static const Color _sitterColor = AppColors.vertpetsy;
  static const Color _courierColor = Color(0xFFFFA726); // amber - 4ème loun

  final AdminStatsController _controller = AdminStatsController();

  int _months = 6;
  MonthlyRegistrations? _data;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final data = await _controller.fetchMonthlyRegistrations(_months);
    if (!mounted) return;

    setState(() {
      _data = data;
      _hasError = data == null;
      _isLoading = false;
    });
  }

  // 🔵 "2026-08" -> "08/26" (format court, ma yet3allekch b'lougha
  // el interface - mch me7tejin liste asma2 echhour mtarjma).
  // 🔴 FIX (kifma tlab: "yetkassem ala 10 tranches") - el backend tawa
  // yerja3 date bidaya kol tranche b'jours ("2026-08-14", mch chher
  // kemel "2026-08") - fa el format "MM/YY" (9dim) ma3adech ye5dem/ye3ni
  // 7aja (kol el tranches fi nefs el chher a7yenen ykounou "08/26" kifkif
  // - mch informatif). Tawa "DD/MM" (jour/chher) - dima distinct bin
  // el tranches.
  String _formatMonthLabel(String isoDate) {
    final parts = isoDate.split('-');
    if (parts.length != 3) return isoDate;
    final month = parts[1];
    final day = parts[2];
    return '$day/$month';
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            buildPetPaw(context: context, size: sizes.adminDashPawSize, topPercent: 0.025, leftPercent: 0.85, color: AppColors.pinkpetsy.withOpacity(0.5)),

            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sizes.adminDashHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: sizes.adminDashTopGap),
                  Text(
                    'dashboard_title'.tr(),
                    style: TextStyle(
                      fontSize: sizes.adminDashTitleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pinkpetsy,
                    ),
                  ),
                  SizedBox(height: sizes.adminDashTitleSubtitleGap),
                  Text(
                    'dashboard_subtitle'.tr(),
                    style: TextStyle(fontSize: sizes.adminDashSubtitleFontSize, color: mutedTextColor),
                  ),
                  SizedBox(height: sizes.adminDashSubtitleSelectorGap),

                  // ----------------------------------------------------
                  // Sélecteur el période (1 -> 12 mois)
                  // ----------------------------------------------------
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: sizes.adminDashSelectorPaddingH, vertical: sizes.adminDashSelectorPaddingV),
                    decoration: BoxDecoration(
                      color: AppColors.vertpetsy.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'period_label'.tr(namedArgs: {'months': '$_months'}),
                          style: TextStyle(fontSize: sizes.adminDashSelectorFontSize, fontWeight: FontWeight.w600, color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.vertpetsy,
                              inactiveTrackColor: AppColors.vertpetsy.withOpacity(0.25),
                              thumbColor: AppColors.pinkpetsy,
                              overlayColor: AppColors.pinkpetsy.withOpacity(0.15),
                              valueIndicatorColor: AppColors.pinkpetsy,
                            ),
                            child: Slider(
                              min: 1,
                              max: 12,
                              divisions: 11,
                              value: _months.toDouble(),
                              label: '$_months',
                              // onChanged: bark update visuel (esm/curseur)
                              // - bla ay appel API kol frame (bch ma
                              // n3aya2ouch el backend b'requests kol ma
                              // el user y7arrek el curseur).
                              onChanged: (v) => setState(() => _months = v.round()),
                              // onChangeEnd: appel API 7a9i9i, ghir ki
                              // el user yrelaxi el curseur (wa7da bark).
                              onChangeEnd: (_) => _load(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: sizes.adminDashSelectorChartGap),

                  if (_isLoading)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: sizes.adminDashLoadingVerticalPad),
                      child: Center(child: CircularProgressIndicator(color: AppColors.vertpetsy)),
                    )
                  else if (_hasError)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: sizes.adminDashErrorVerticalPad),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.wifi_off_rounded, color: mutedTextColor.withOpacity(0.6), size: sizes.adminDashErrorIcon),
                            SizedBox(height: sizes.adminDashErrorIconGap),
                            Text('stats_load_error'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                            SizedBox(height: sizes.adminDashErrorButtonGap),
                            TextButton(
                              onPressed: _load,
                              child: Text(
                                'retry_button'.tr(),
                                style: const TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (_data != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(sizes.adminDashChartCardPadding),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: LineChartWidget(
                        height: sizes.adminDashChartHeight,
                        xLabels: _data!.months.map(_formatMonthLabel).toList(),
                        series: [
                          LineChartSeries(
                            label: 'chart_series_total_label'.tr(),
                            color: _totalColor,
                            values: _data!.total.map((v) => v.toDouble()).toList(),
                          ),
                          LineChartSeries(
                            label: 'chart_series_owners_label'.tr(),
                            color: _ownerColor,
                            values: _data!.owner.map((v) => v.toDouble()).toList(),
                          ),
                          LineChartSeries(
                            label: 'chart_series_sitters_label'.tr(),
                            color: _sitterColor,
                            values: _data!.sitter.map((v) => v.toDouble()).toList(),
                          ),
                          LineChartSeries(
                            label: 'chart_series_couriers_label'.tr(),
                            color: _courierColor,
                            values: _data!.courier.map((v) => v.toDouble()).toList(),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: sizes.adminDashBottomGap),
                ],
              ),
            ),

            const CustomBackButton(),
          ],
        ),
      ),
    );
  }
}