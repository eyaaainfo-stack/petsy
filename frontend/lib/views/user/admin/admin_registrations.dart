import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../controllers/admin_stats_controller.dart';
import '../../../models/admin_stats.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/paw_widget.dart';
import '../../../widgets/stat_card.dart';

// ============================================================================
// AdminRegistrationsScreen ("Les inscriptions")
// ============================================================================
// 🔵 ZID: kifma tlab - "total d'inscri fel app meli twejdet lel users
// lkol, w ta7thom les acteurs lokhrin kadeh men inscri 3malou kol
// acteur" - GET /api/admin/stats (déjà mawjouda, fiha totalUsers/
// totalOwners/totalSitters/totalCouriers depuis le début).
//
// 🔴 FIX (rappel AppSizes): sizes.adminRegXxx (mch MediaQuery direct).
// ============================================================================
class AdminRegistrationsScreen extends StatefulWidget {
  const AdminRegistrationsScreen({super.key});

  @override
  State<AdminRegistrationsScreen> createState() => _AdminRegistrationsScreenState();
}

class _AdminRegistrationsScreenState extends State<AdminRegistrationsScreen> {
  final AdminStatsController _controller = AdminStatsController();
  AdminStats? _stats;
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

    final stats = await _controller.fetchStats();
    if (!mounted) return;

    setState(() {
      _stats = stats;
      _hasError = stats == null;
      _isLoading = false;
    });
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
            buildPetPaw(context: context, size: sizes.adminRegPawSize, topPercent: 0.025, leftPercent: 0.85, color: AppColors.vertpetsy.withOpacity(0.5)),

            RefreshIndicator(
              onRefresh: _load,
              color: AppColors.pinkpetsy,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: sizes.adminRegHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: sizes.adminRegTopGap),
                    Text(
                      'registrations_title'.tr(),
                      style: TextStyle(
                        fontSize: sizes.adminRegTitleFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.pinkpetsy,
                      ),
                    ),
                    SizedBox(height: sizes.adminRegSectionGap),

                    if (_isLoading)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.adminRegLoadingVerticalPad),
                        child: Center(child: CircularProgressIndicator(color: AppColors.vertpetsy)),
                      )
                    else if (_hasError)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: sizes.adminRegErrorVerticalPad),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.wifi_off_rounded, color: mutedTextColor.withOpacity(0.6), size: sizes.adminRegErrorIcon),
                              SizedBox(height: sizes.adminRegErrorIconGap),
                              Text('stats_load_error'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                              SizedBox(height: sizes.adminRegErrorButtonGap),
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
                    else if (_stats != null) ...[
                      // --------------------------------------------------
                      // Total (kbira, fou9 el kol) - "total inscri fel
                      // app meli twejdet, lel users lkol"
                      // --------------------------------------------------
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(sizes.adminRegTotalCardPadding),
                        decoration: BoxDecoration(
                          color: AppColors.pinkpetsy.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'stat_total_registrations_label'.tr(),
                              style: TextStyle(fontSize: sizes.adminRegTotalCardLabelFontSize, color: mutedTextColor, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: sizes.adminRegTotalCardLabelValueGap),
                            Text(
                              '${_stats!.totalUsers}',
                              style: TextStyle(fontSize: sizes.adminRegTotalCardValueFontSize, fontWeight: FontWeight.bold, color: AppColors.pinkpetsy),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: sizes.adminRegAfterTotalCardGap),
                      Text(
                        'stats_by_actor_section_label'.tr(),
                        style: TextStyle(
                          fontSize: sizes.adminRegSectionTitleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      SizedBox(height: sizes.adminRegSectionTitleGridGap),

                      // --------------------------------------------------
                      // Breakdown per acteur (owners/sitters/couriers)
                      // --------------------------------------------------
                      Wrap(
                        spacing: sizes.adminRegGridSpacing,
                        runSpacing: sizes.adminRegGridSpacing,
                        children: [
                          SizedBox(width: sizes.adminRegCardWidth, child: StatCard(icon: Icons.people_outline, color: AppColors.vertpetsy, value: '${_stats!.totalOwners}', label: 'stat_total_owners_label'.tr())),
                          SizedBox(width: sizes.adminRegCardWidth, child: StatCard(icon: Icons.volunteer_activism_outlined, color: AppColors.pinkpetsy, value: '${_stats!.totalSitters}', label: 'stat_total_sitters_label'.tr())),
                          SizedBox(width: sizes.adminRegCardWidth, child: StatCard(icon: Icons.local_shipping_outlined, color: AppColors.vertpetsy, value: '${_stats!.totalCouriers}', label: 'stat_total_couriers_label'.tr())),
                          SizedBox(width: sizes.adminRegCardWidth, child: StatCard(icon: Icons.admin_panel_settings_outlined, color: AppColors.pinkpetsy, value: '${_stats!.totalAdmins}', label: 'stat_total_admins_label'.tr())),
                        ],
                      ),
                    ],

                    SizedBox(height: sizes.adminRegBottomGap),
                  ],
                ),
              ),
            ),

            const CustomBackButton(),
          ],
        ),
      ),
    );
  }
}