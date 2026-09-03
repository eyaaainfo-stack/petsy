import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/admin_menu_tile.dart';
import '../../../widgets/drawers/sidebar_admin.dart';
import 'admin_statistics.dart';
import 'admin_accounts.dart';
import 'admin_reviews.dart';
import 'admin_validations.dart';

// ============================================================================
// AdminHomeScreen
// ============================================================================
// 🔵 ZID: home page tel Admin (kifma tlab: "el interface mteou el home
// page tjih style boutonet [...] fel widgets"). Nafs l'idée tel
// ProfileOwnerScreen (header: avatar + greeting + menu).
//
// 🔴 FIX (badlt kifma tlab): "kol chy yetnahha, yo93od ken Statistics" -
// na77ina Owners/Sitters/Bookings/Reviews (kanou "coming soon" bark,
// mafamech data 7a9i9iya) - tawa liste el widgets fiha ghir "Statistics"
// (elli tawa temchi l'écran fih 2 boutons: "Les inscriptions" w
// "Tableau de bord" - chouf admin_statistics.dart).
//
// 🔴 FIX (rappel: "ma staamlech el AppSizes eli fi constants") - kanet
// el sizes el kol mel MediaQuery direct (screenSize.width * 0.0X) -
// tawa AppSizes.of(context) (sizes.adminHomeXxx), nafs mant9 el app el
// kol (bdal magic numbers mfarr9in, blasa WA7DA fel constants/app_sizes.dart).
// ============================================================================
class AdminHomeScreen extends StatefulWidget {
  final String adminName;
  final String? adminPhotoUrl;

  const AdminHomeScreen({super.key, required this.adminName, this.adminPhotoUrl});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    return Scaffold(
      key: _scaffoldKey,
      drawer: SidebarAdmin(adminName: widget.adminName, adminPhotoUrl: widget.adminPhotoUrl),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: sizes.adminHomeHorizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: sizes.adminHomeTopGap),

              // ------------------------------------------------------
              // Header: avatar (icon, l'Admin ma3andouch photo bel
              // esm) + greeting + badge "Admin" + menu
              // ------------------------------------------------------
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: sizes.adminHomeAvatarSize,
                      height: sizes.adminHomeAvatarSize,
                      color: AppColors.pinkpetsy.withOpacity(0.15),
                      child: (widget.adminPhotoUrl != null && widget.adminPhotoUrl!.isNotEmpty)
                          ? Image.network(widget.adminPhotoUrl!, fit: BoxFit.cover)
                          : Icon(Icons.admin_panel_settings, color: AppColors.pinkpetsy, size: sizes.adminHomeAvatarIcon),
                    ),
                  ),
                  SizedBox(width: sizes.adminHomeAvatarTextGap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'home_greeting'.tr(namedArgs: {'name': widget.adminName}),
                          style: TextStyle(
                            fontSize: sizes.adminHomeNameFontSize,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          'admin_badge_label'.tr(),
                          style: TextStyle(fontSize: sizes.adminHomeBadgeFontSize, color: mutedTextColor),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: Container(
                      width: sizes.adminHomeMenuButtonSize,
                      height: sizes.adminHomeMenuButtonSize,
                      decoration: BoxDecoration(
                        color: AppColors.pinkpetsy.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(sizes.adminHomeMenuButtonSize * 0.35),
                      ),
                      child: Icon(Icons.menu, color: AppColors.pinkpetsy, size: sizes.adminHomeMenuIconSize),
                    ),
                  ),
                ],
              ),

              SizedBox(height: sizes.adminHomeHeaderSectionGap),

              Text(
                'admin_dashboard_title'.tr(),
                style: TextStyle(
                  fontSize: sizes.adminHomeSectionTitleFontSize,
                  fontWeight: FontWeight.bold,
                  color: AppColors.pinkpetsy,
                ),
              ),
              SizedBox(height: sizes.adminHomeSectionTitleListGap),

              // ------------------------------------------------------
              // Liste el widgets (pilules) - "Statistics" + "Gestion
              // des comptes" (kifma tlab: "m3a bouton statistique
              // zidni bouton... gestion des comptes")
              // ------------------------------------------------------
              AdminMenuTile(
                icon: Icons.bar_chart_rounded,
                label: 'statistics_menu_label'.tr(),
                color: AppColors.vertpetsy,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminStatisticsScreen()),
                  );
                },
              ),
              SizedBox(height: sizes.adminHomeSectionTitleListGap),

              AdminMenuTile(
                icon: Icons.manage_accounts_outlined,
                label: 'accounts_menu_label'.tr(),
                color: AppColors.pinkpetsy,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminAccountsScreen()),
                  );
                },
              ),
              SizedBox(height: sizes.adminHomeSectionTitleListGap),

              AdminMenuTile(
                icon: Icons.rate_review_outlined,
                label: 'reviews_menu_label'.tr(),
                color: AppColors.vertpetsy,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminReviewsScreen()),
                  );
                },
              ),
              SizedBox(height: sizes.adminHomeSectionTitleListGap),

              AdminMenuTile(
                icon: Icons.verified_outlined,
                label: 'validations_menu_label'.tr(),
                color: AppColors.pinkpetsy,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminValidationsScreen()),
                  );
                },
              ),

              SizedBox(height: sizes.adminHomeBottomGap),
            ],
          ),
        ),
      ),
    );
  }
}