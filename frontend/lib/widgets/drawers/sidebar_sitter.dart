import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/auth_session.dart';
import '../paw_widget.dart';
import 'sidebar_item.dart';
import '../../views/user/account_type.dart';
import '../../views/user/sitter/sitter_profile.dart';
import '../../views/user/sitter/my_profile_sitter.dart';
import '../../views/user/sitter/sitter_calender.dart';
import '../../views/user/notifications_screen.dart';
import '../../views/user/settings_screen.dart';
import '../../controllers/notification_controller.dart';

// ============================================================================
// SidebarSitter (Drawer tel sitter)
// ============================================================================
// 🔵 Kifech testa3melha: fel Scaffold tel écran (mathalan SitterProfileScreen),
// zid "drawer: SidebarSitter(...)" - Flutter yeftahha automatique ki
// el user ysou7eb mel yesar l'lwosT, wala ki t3ayet "Scaffold.of(context)
// .openDrawer()" (mathalan mel bouton menu fel header).
//
// 🔴 "el photo mrabb3a" (kifma tlabt) - MCH dayra (CircleAvatar) kifha kif
// el design mte3 el mockup el asli - ClipRRect b radius sghir bark.
// ============================================================================
class SidebarSitter extends StatefulWidget {
  final String sitterName;
  final String sitterCity;
  final Uint8List? sitterPhotoBytes;
  final String? sitterPhotoUrl;

  const SidebarSitter({
    super.key,
    required this.sitterName,
    required this.sitterCity,
    this.sitterPhotoBytes,
    this.sitterPhotoUrl,
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
    // 🔵 ZID: logout 7a9i9i (mch TODO) - ynahi el session (token/user
    // data mel SharedPreferences) w yerja3 lel écran "choose account
    // type" (nafs el blasa elli el user ybda menha ki yefte7 l'app mel
    // jdid, bla ma y3addi mel Language/Onboarding mel jdid).
    await AuthSession.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AccountTypeView()),
      (route) => false,
    );
  }

  void _onHomePressed(BuildContext context) {
    // 🔵 ZID (kifma tlabt): "Home" ymchi l'SitterProfileScreen - dima,
    // 7ata lowkan el drawer maftou7 mel écran ekhor (mathalan Account/
    // Calendar - mazel ma tsawbouch, lakin ki ytsawbou el drawer yeb9a
    // ye5dem sa7i7 mennhom zeda).
    Navigator.of(context).pop(); // yghaleg el drawer awalan
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SitterProfileScreen(
          sitterName: widget.sitterName,
          sitterCity: widget.sitterCity,
          sitterPhotoBytes: widget.sitterPhotoBytes,
          sitterPhotoUrl: widget.sitterPhotoUrl,
        ),
      ),
      (route) => false,
    );
  }

  // 🔵 el screens l'okhrin (Calendar/Messages/About us) mazel ma
  // tsawbouch - TODO bark, ghir yghaleg el drawer (bla crash "route
  // not found").
  void _notImplementedYet(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    // 🔵 ZID: blasa WA7DA lel rose "ahfef" (mch vulgaire) - el header
    // W el bouton "About us" tawa yestaعمlouh el zoùz mel nefs el
    // variable (bla ma ykoun 2 rose mokhtalfin chwaya b'ghalta).
    final Color softPink = Color.lerp(AppColors.pinkpetsy, Colors.white, 0.35)!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: sizes.sidebarWidth,
      // 🔴 FIX (kifma tlab): "badel el vert bel blanc, w el bordure
      // mte3ha bel vert" - bdal background KAMEL a5dhar, tawa abyadh
      // (dark -> surface ghamqa, mch abyadh fa9i3 fel dark mode) +
      // bordure a5dhar 3al drawer kaملou (shape).
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: Border(right: BorderSide(color: AppColors.vertpetsy, width: 2)),
      child: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------------
            // Header: background rose AHFEF (mch vulgaire), paws, photo
            // MRABB3A AKBAR w fel WEST 7a9i9atan + esm
            // ----------------------------------------------------------
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: sizes.sidebarHeaderPadding,
                vertical: sizes.sidebarHeaderPadding,
              ),
              decoration: BoxDecoration(
                color: softPink,
                // 🔴 FIX: shape "melouta" akthar (mch ghir bottomRight) -
                // el 2 corners el ta7tanyin rounded, bch el box yeb9a
                // mtabet/mechya m3a el pdp (rounded square) el fou9ha.
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    right: sizes.screenWidth * 0.02,
                    child: Icon(Icons.pets, color: Colors.white.withOpacity(0.5), size: sizes.sidebarPawSize1),
                  ),
                  Positioned(
                    top: sizes.screenHeight * 0.035,
                    right: -sizes.screenWidth * 0.01,
                    child: Icon(Icons.pets, color: Colors.white.withOpacity(0.35), size: sizes.sidebarPawSize2),
                  ),
                  // 🔴 FIX: "el pdp fel west" - SizedBox b'width infinite
                  // (mch Positioned.fill - hedhi kanet twaqqaf el Stack
                  // ma3andouch 7aja "non-positioned" ta3tih hjm, w
                  // tenhar l'height 0) - el Column b'crossAxisAlignment
                  // center (default) tawa tetmarkaz 3ala 3ard el box
                  // KAMEL 7a9i9atan.
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: sizes.screenHeight * 0.015),
                        // 🔴 "photo mrabb3a AKBAR" kifma tlabt
                        // 🔵 ZID (kifma tlab): bordure a5dhar 3al pdp zeda.
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.vertpetsy, width: 2.5)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: sizes.sidebarPhotoSize,
                              height: sizes.sidebarPhotoSize,
                              color: Colors.white,
                              child: widget.sitterPhotoBytes != null
                                  ? Image.memory(widget.sitterPhotoBytes!, fit: BoxFit.cover)
                                  : widget.sitterPhotoUrl != null
                                      ? Image.network(widget.sitterPhotoUrl!, fit: BoxFit.cover)
                                      : Icon(Icons.person, color: AppColors.pinkpetsy, size: sizes.sidebarPhotoSize * 0.55),
                            ),
                          ),
                        ),
                        SizedBox(height: sizes.screenHeight * 0.014),
                        Text(
                          widget.sitterName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: sizes.sidebarNameFontSize,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: sizes.screenHeight * 0.01),

            // ----------------------------------------------------------
            // Liste el menu (Account/Home/Calendar/Notifications/
            // Messages/Settings/Log out) - fond teal
            // ----------------------------------------------------------
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: sizes.sidebarHeaderPadding),
                child: Column(
                  children: [
                    SidebarItem(
                      icon: Icons.person_outline,
                      label: 'account_label'.tr(),
                      sizes: sizes,
                      onTap: () {
                        // 🔴 FIX: kanet TODO - tawa ymchi l "My Profile"
                        // (my_profile_sitter.dart).
                        Navigator.of(context).pop(); // yghaleg el drawer awalan
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyProfileSitterScreen()),
                        );
                      },
                    ),
                    SidebarItem(
                      icon: Icons.home_outlined,
                      label: 'home_label'.tr(),
                      sizes: sizes,
                      onTap: () => _onHomePressed(context),
                    ),
                    SidebarItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'calendar_label'.tr(),
                      sizes: sizes,
                      // 🔴 FIX (kifma tlab): kanet TODO - tawa ymchi l
                      // "Calendar" (sitter_calender.dart).
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SitterCalenderScreen()),
                        );
                      },
                    ),
                    SidebarItem(
                      icon: Icons.notifications_outlined,
                      label: 'notifications_label'.tr(),
                      sizes: sizes,
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
                    SidebarItem(
                      icon: Icons.chat_bubble_outline,
                      label: 'messages_label'.tr(),
                      sizes: sizes,
                      onTap: () => _notImplementedYet(context),
                    ),
                    // 🔵 ZID (kifma tlab): "Settings" (Theme + Language)
                    SidebarItem(
                      icon: Icons.settings_outlined,
                      label: 'settings_label'.tr(),
                      sizes: sizes,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                    SidebarItem(
                      icon: Icons.logout,
                      label: 'log_out_label'.tr(),
                      sizes: sizes,
                      showDivider: false,
                      onTap: () => _onLogoutPressed(context),
                    ),
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
                    backgroundColor: softPink, // 🔴 FIX: nafs el rose ahfef tel header (bdal AppColors.pinkpetsy el 9dim)
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 2,
                  ),
                  onPressed: () => _notImplementedYet(context),
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