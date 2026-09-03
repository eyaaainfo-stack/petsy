import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/admin_menu_tile.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/paw_widget.dart';
import 'admin_registrations.dart';
import 'admin_dashboard.dart';

// ============================================================================
// AdminStatisticsScreen ("Statistics") - "hub" b 2 boutons
// ============================================================================
// 🔵 ZID: kifma tlab - "kif nenzel 3aliha [Statistics] nelka bouton
// 'les inscriptions' w bouton 'tableau de bord'" - hedha el écran mch
// fih data direct, ghir 2 AdminMenuTile (nafs style el pilule) - kol
// wa7da temchi l'écran mte3ha (AdminRegistrationsScreen /
// AdminDashboardScreen).
//
// 🔴 FIX (rappel AppSizes): sizes.adminStatsXxx (mch MediaQuery direct).
// ============================================================================
class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            buildPetPaw(context: context, size: sizes.adminStatsPawSize, topPercent: 0.025, leftPercent: 0.85, color: AppColors.vertpetsy.withOpacity(0.5)),

            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: sizes.adminStatsHorizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: sizes.adminStatsTopGap),
                  Text(
                    'statistics_title'.tr(),
                    style: TextStyle(
                      fontSize: sizes.adminStatsTitleFontSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pinkpetsy,
                    ),
                  ),
                  SizedBox(height: sizes.adminStatsSectionGap),

                  AdminMenuTile(
                    icon: Icons.how_to_reg_outlined,
                    label: 'registrations_menu_label'.tr(),
                    color: AppColors.vertpetsy,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminRegistrationsScreen()),
                      );
                    },
                  ),
                  SizedBox(height: sizes.adminStatsTileGap),

                  AdminMenuTile(
                    icon: Icons.show_chart_rounded,
                    label: 'dashboard_menu_label'.tr(),
                    color: AppColors.pinkpetsy,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                      );
                    },
                  ),

                  SizedBox(height: sizes.adminStatsBottomGap),
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