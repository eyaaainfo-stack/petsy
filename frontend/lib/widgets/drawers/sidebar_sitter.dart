import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/auth_session.dart';
import '../verified_badge.dart';
import 'sidebar_pill_item.dart';
import '../../views/user/account_type.dart';
import '../../views/user/sitter/sitter_profile.dart';
import '../../views/user/sitter/my_profile_sitter.dart';
import '../../views/user/sitter/sitter_calender.dart';
import '../../views/user/notifications_screen.dart';
import '../../views/user/settings_screen.dart';
import '../../controllers/notification_controller.dart';
import '../../views/user/messages_list_screen.dart';
import '../../views/user/about_us_screen.dart';

// ============================================================================
// SidebarSitter (Drawer tel sitter) - redesign "moderne"
// ============================================================================
// 🔴 FIX (kifma tlab: "nhb hatta el sitter wel owner [nafs redesign
// tel SidebarAdmin]") - kanet: header rose "block" + liste satr/satr
// b'dividers + background dark hardcodé.
//
// Tawa: header b'gradient rose ahfef, avatar dayer + VerifiedBadge
// (kifma tlab 9bal, "el tick... fel home fel pdp mteou" - tawa fel
// sidebar zeda), badge "chip" moderne. El menu: "pilules"
// (SidebarPillItem, widget PARTAGÉ m3a SidebarAdmin/SidebarOwner) -
// background theme-aware.
// ============================================================================
class SidebarSitter extends StatefulWidget {
  final String sitterName;
  final String sitterCity;
  final Uint8List? sitterPhotoBytes;
  final String? sitterPhotoUrl;
  final bool isVerified;
  // 🔵 ZID (kifma tlab: "ken el user homme nkhalliwh vert, keno femme
  // pink") - couleur el header + bouton "About us" 7asb el gender.
  final String? gender;

  const SidebarSitter({
    super.key,
    required this.sitterName,
    required this.sitterCity,
    this.sitterPhotoBytes,
    this.sitterPhotoUrl,
    this.isVerified = false,
    this.gender,
  });

  @override
  State<SidebarSitter> createState() => _SidebarSitterState();
}

class _SidebarSitterState extends State<SidebarSitter> {
  // 🔵 ZID (kifma tlab): "yjiwni les notifications" - badge b ra9m
  // el notifications ma9rou2ach, 7dha "Notifications" fel sidebar.
  final NotificationController _notificationController = NotificationController();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
  }

  Future<void> _fetchUnreadCount() async {
    final count = await _notificationController.fetchUnreadCount();
    if (!mounted) return;
    setState(() => _unreadCount = count);
  }

  Future<void> _onLogoutPressed(BuildContext context) async {
    await AuthSession.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AccountTypeView()),
      (route) => false,
    );
  }

  void _onHomePressed(BuildContext context) {
    Navigator.of(context).pop(); // yghaleg el drawer awalan
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SitterProfileScreen(
          sitterName: widget.sitterName,
          sitterCity: widget.sitterCity,
          sitterPhotoBytes: widget.sitterPhotoBytes,
          sitterPhotoUrl: widget.sitterPhotoUrl,
          isVerified: widget.isVerified,
          gender: widget.gender,
        ),
      ),
      (route) => false,
    );
  }

  // 🔵 el screens l'okhrin (Messages/About us) mazel ma tsawbouch -
  // TODO bark, ghir yghaleg el drawer (bla crash "route not found").
  void _notImplementedYet(BuildContext context) {
    Navigator.of(context).pop();
  }

  // 🔵 ZID (kifma tlab: "ken el user homme nkhalliwh vert, keno femme
  // pink") - couleur el header (+ "About us") 7asb el gender.
  Color get _accentColor => widget.gender == 'male' ? AppColors.vertpetsy : AppColors.pinkpetsy;

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);

    return Drawer(
      width: sizes.sidebarWidth,
      // 🔴 FIX: kanet #1E1E1E hardcodé (dark) - tawa scaffoldBackgroundColor
      // (el theme el 7a9i9i tel app, yet3addel automatique).
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------------
            // Header: gradient rose + avatar dayer + VerifiedBadge +
            // badge "chip" moderne.
            // ----------------------------------------------------------
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: sizes.sidebarHeaderPadding,
                vertical: sizes.sidebarHeaderPadding,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_accentColor, Color.lerp(_accentColor, Colors.white, 0.3)!],
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
                    child: Icon(Icons.pets, color: Colors.white.withOpacity(0.18), size: sizes.sidebarPawSize1),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: sizes.screenHeight * 0.01),
                        // 🔵 avatar dayer + VerifiedBadge (kifma tlab
                        // 9bal, tawa fel sidebar zeda).
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.85), width: 2.5),
                              ),
                              child: ClipOval(
                                child: Container(
                                  width: sizes.sidebarPhotoSize,
                                  height: sizes.sidebarPhotoSize,
                                  color: Colors.white,
                                  child: widget.sitterPhotoBytes != null
                                      ? Image.memory(widget.sitterPhotoBytes!, fit: BoxFit.cover)
                                      : widget.sitterPhotoUrl != null
                                          ? Image.network(widget.sitterPhotoUrl!, fit: BoxFit.cover)
                                          : Icon(Icons.person, color: _accentColor, size: sizes.sidebarPhotoSize * 0.55),
                                ),
                              ),
                            ),
                            if (widget.isVerified)
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: VerifiedBadge(size: sizes.sidebarVerifiedBadgeSize),
                              ),
                          ],
                        ),
                        SizedBox(height: sizes.screenHeight * 0.014),
                        Text(
                          widget.sitterName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: sizes.sidebarNameFontSize,
                          ),
                        ),
                        if (widget.sitterCity.isNotEmpty) ...[
                          SizedBox(height: sizes.screenHeight * 0.004),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenWidth * 0.012),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              widget.sitterCity,
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: sizes.sidebarNameFontSize * 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sizes.screenHeight * 0.016),

            // ----------------------------------------------------------
            // Liste el menu - "pilules" (SidebarPillItem, mch satr/satr
            // b'dividers kifma 9bal).
            // ----------------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: sizes.sidebarHeaderPadding),
                child: Column(
                  children: [
                    SidebarPillItem(
                      icon: Icons.person_outline,
                      label: 'account_label'.tr(),
                      color: AppColors.vertpetsy,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyProfileSitterScreen()),
                        );
                      },
                    ),
                    SizedBox(height: sizes.sidebarPillGap),
                    SidebarPillItem(
                      icon: Icons.home_outlined,
                      label: 'home_label'.tr(),
                      color: AppColors.pinkpetsy,
                      onTap: () => _onHomePressed(context),
                    ),
                    SizedBox(height: sizes.sidebarPillGap),
                    SidebarPillItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'calendar_label'.tr(),
                      color: AppColors.vertpetsy,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SitterCalenderScreen()),
                        );
                      },
                    ),
                    SizedBox(height: sizes.sidebarPillGap),
                    SidebarPillItem(
                      icon: Icons.notifications_outlined,
                      label: 'notifications_label'.tr(),
                      color: AppColors.pinkpetsy,
                      // 🔵 ZID (kifma tlab): badge b ra9m el notifications
                      // ma9rou2ach.
                      badgeCount: _unreadCount,
                      onTap: () async {
                        Navigator.of(context).pop();
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                        );
                        _fetchUnreadCount();
                      },
                    ),
                    SizedBox(height: sizes.sidebarPillGap),
                    SidebarPillItem(
                      icon: Icons.chat_bubble_outline,
                      label: 'messages_label'.tr(),
                      color: AppColors.vertpetsy,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MessagesListScreen()),
                        );
                      },
                    ),
                    SizedBox(height: sizes.sidebarPillGap),
                    // 🔵 ZID (kifma tlab): "Settings" (Theme + Language +
                    // Vérification).
                    SidebarPillItem(
                      icon: Icons.settings_outlined,
                      label: 'settings_label'.tr(),
                      color: AppColors.pinkpetsy,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                    SizedBox(height: sizes.adminSidebarLogoutGap),
                    // 🔵 Déconnexion: accent rouge, mfaraz b'gap akbar -
                    // action "destructive" (nafs convention SidebarAdmin).
                    SidebarPillItem(
                      icon: Icons.logout,
                      label: 'log_out_label'.tr(),
                      color: AppColors.error,
                      onTap: () => _onLogoutPressed(context),
                    ),
                    SizedBox(height: sizes.sidebarPillGap),
                  ],
                ),
              ),
            ),

            // ----------------------------------------------------------
            // Bouton "About us"
            // ----------------------------------------------------------
            Padding(
              padding: EdgeInsets.all(sizes.sidebarHeaderPadding),
              child: SizedBox(
                width: double.infinity,
                height: sizes.sidebarAboutButtonHeight,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                    );
                  },
                  child: Text(
                    'about_us_label'.tr(),
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.sidebarItemFontSize),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}