import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/auth_session.dart';
import '../../views/user/account_type.dart';
import '../../views/user/admin/admin_home.dart';
import '../../views/user/admin/admin_statistics.dart';
import '../../views/user/settings_screen.dart';
import 'sidebar_pill_item.dart';

// ============================================================================
// SidebarAdmin (Drawer tel Admin) - redesign "moderne"
// ============================================================================
// 🔴 FIX (kifma tlab: "el design mteeha mch ajebnii jemla, badlholi b
// whd ekher ykoun moderne w les couleur mteou bhyin w yrayhou el ein
// f mode sombre wla light, ama ykoun yechrak ala el theme mtaa el
// app") - kanet: header rose "block" + liste satr/satr b'dividers +
// background dark hardcodé (#1E1E1E, mch theme-aware 7a9i9i).
//
// Tawa: header b'gradient rose ahfef (mch color wa7da flat), avatar
// dayer (mch mrabb3), badge "chip" moderne. El menu: "pilules" (nafs
// style AdminMenuTile elli déjà mawjoud fel Admin Home - consistance
// visuelle m3a el b39dh el kol tel panneau admin) - background
// isDark?white.withOpacity(0.06):grey.shade100 (nafs convention el
// screens el admin el kol fel conversation) - bch yeb9a behi w
// yerta7 lih el 3in fi mode sombre W light.
// ============================================================================
class SidebarAdmin extends StatelessWidget {
  final String adminName;
  final String? adminPhotoUrl;

  const SidebarAdmin({super.key, required this.adminName, this.adminPhotoUrl});

  Future<void> _onLogoutPressed(BuildContext context) async {
    await AuthSession.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AccountTypeView()),
      (route) => false,
    );
  }

  void _onHomePressed(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => AdminHomeScreen(adminName: adminName, adminPhotoUrl: adminPhotoUrl)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);

    return Drawer(
      width: sizes.sidebarWidth,
      // 🔴 FIX: kanet #1E1E1E hardcodé (dark) / Colors.white (light) -
      // tawa scaffoldBackgroundColor (el theme el 7a9i9i tel app,
      // yet3addel automatique m3a el thème mte3 el user).
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------------
            // Header: gradient rose (mch color flat wa7da) + avatar
            // dayer (mch mrabb3) + badge "chip" moderne (mch text bark).
            // ----------------------------------------------------------
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: sizes.adminSidebarHeaderPadding,
                vertical: sizes.adminSidebarHeaderPadding,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.pinkpetsy, Color.lerp(AppColors.pinkpetsy, AppColors.vertpetsy, 0.35)!],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -4,
                    right: sizes.screenWidth * 0.01,
                    child: Icon(Icons.pets, color: Colors.white.withOpacity(0.18), size: sizes.adminSidebarPawSize),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: sizes.screenHeight * 0.01),
                        // 🔵 avatar dayer (mch mrabb3) - ring blanche
                        // ahfef (mch bordure teal 3ريضة kifma 9bal).
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.85), width: 2.5),
                          ),
                          child: ClipOval(
                            child: Container(
                              width: sizes.adminSidebarAvatarSize,
                              height: sizes.adminSidebarAvatarSize,
                              color: Colors.white,
                              child: (adminPhotoUrl != null && adminPhotoUrl!.isNotEmpty)
                                  ? Image.network(adminPhotoUrl!, fit: BoxFit.cover)
                                  : Icon(Icons.admin_panel_settings, color: AppColors.pinkpetsy, size: sizes.adminSidebarAvatarIcon),
                            ),
                          ),
                        ),
                        SizedBox(height: sizes.adminSidebarAvatarNameGap),
                        Text(
                          adminName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: sizes.adminSidebarNameFontSize,
                          ),
                        ),
                        SizedBox(height: sizes.adminSidebarNameBadgeGap),
                        // 🔵 badge "chip" (pilule semi-transparente) -
                        // mch text 3ادي kifma 9bal, look modern.
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: sizes.adminSidebarBadgeHPadding, vertical: sizes.adminSidebarBadgeVPadding),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'admin_badge_label'.tr(),
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: sizes.adminSidebarBadgeFontSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sizes.adminSidebarListTopGap),

            // ----------------------------------------------------------
            // Liste el menu - "pilules" (nafs style AdminMenuTile, mch
            // satr/satr b'dividers kifma 9bal) - background theme-aware.
            // ----------------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: sizes.adminSidebarListHorizontalPadding),
                child: Column(
                  children: [
                    SidebarPillItem(
                      icon: Icons.home_outlined,
                      label: 'home_label'.tr(),
                      color: AppColors.vertpetsy,
                      onTap: () => _onHomePressed(context),
                    ),
                    SizedBox(height: sizes.adminSidebarItemGap),
                    SidebarPillItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'statistics_menu_label'.tr(),
                      color: AppColors.pinkpetsy,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AdminStatisticsScreen()),
                        );
                      },
                    ),
                    SizedBox(height: sizes.adminSidebarItemGap),
                    SidebarPillItem(
                      icon: Icons.settings_outlined,
                      label: 'settings_label'.tr(),
                      color: AppColors.vertpetsy,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                    SizedBox(height: sizes.adminSidebarLogoutGap),
                    // 🔵 Déconnexion: accent rouge (mch nefs loun tel
                    // menu l'okhrin) - action "destructive", mfaraz
                    // b'gap akbar - convention moderne (mch mkhalta
                    // m3al menu el 3adi).
                    SidebarPillItem(
                      icon: Icons.logout,
                      label: 'log_out_label'.tr(),
                      color: AppColors.error,
                      onTap: () => _onLogoutPressed(context),
                    ),
                    SizedBox(height: sizes.adminSidebarItemGap),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}