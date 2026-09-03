import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/auth_session.dart';
import '../../repositories/pet_repository.dart';
import '../verified_badge.dart';
import 'sidebar_pill_item.dart';
import '../../views/user/account_type.dart';
import '../../views/user/owner/profile_owner.dart';
import '../../views/user/owner/my_profile_owner.dart';
import '../../views/user/notifications_screen.dart';
import '../../views/user/settings_screen.dart';
import '../../views/user/owner/my_favourites_screen.dart';
import '../../views/user/owner/les_reservations.dart';
import '../../controllers/notification_controller.dart';

// ============================================================================
// SidebarOwner (Drawer tel owner) - redesign "moderne"
// ============================================================================
// 🔴 FIX (kifma tlab: "nhb hatta el sitter wel owner [nafs redesign
// tel SidebarAdmin]") - kanet: header rose "block" + liste satr/satr
// b'dividers + background dark hardcodé.
//
// Tawa: header b'gradient rose ahfef (mch color wa7da flat), avatar
// dayer (mch mrabb3) + VerifiedBadge (kifma tlab 9bal, "el tick...
// fel home fel pdp mteou" - tawa fel sidebar zeda), badge "chip"
// moderne. El menu: "pilules" (SidebarPillItem, widget PARTAGÉ m3a
// SidebarAdmin/SidebarSitter) - background theme-aware.
// ============================================================================
class SidebarOwner extends StatefulWidget {
  final String ownerName;
  final String ownerCity;
  final Uint8List? ownerPhotoBytes;
  final String? ownerPhotoUrl;
  final bool isVerified;
  // 🔵 ZID (kifma tlab: "ken el user homme nkhalliwh vert, keno femme
  // pink") - couleur el header + bouton "About us" 7asb el gender.
  final String? gender;

  const SidebarOwner({
    super.key,
    required this.ownerName,
    required this.ownerCity,
    this.ownerPhotoBytes,
    this.ownerPhotoUrl,
    this.isVerified = false,
    this.gender,
  });

  @override
  State<SidebarOwner> createState() => _SidebarOwnerState();
}

class _SidebarOwnerState extends State<SidebarOwner> {
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

  Future<void> _onHomePressed(BuildContext context) async {
    Navigator.of(context).pop(); // yghaleg el drawer awalan

    // 🔴 ProfileOwnerScreen yestenna "pets" - njibouhom mel backend
    // 9bal el navigation (nafs mant9 splash_decider.dart/user_login.dart).
    final pets = await PetRepository.fetchOwnerPets();
    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ProfileOwnerScreen(
          ownerName: widget.ownerName,
          ownerCity: widget.ownerCity,
          pets: pets,
          ownerPhotoBytes: widget.ownerPhotoBytes,
          ownerPhotoUrl: widget.ownerPhotoUrl,
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
  // pink") - couleur el header (+ "About us") 7asb el gender - homme
  // -> vertpetsy, femme (wla mch renseigné) -> pinkpetsy (el couleur
  // "par défaut" tel app déjà - kifma kanet 9bal el feature hedhi).
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
                        // 🔵 avatar dayer (mch mrabb3) - ring blanche
                        // + VerifiedBadge (kifma tlab 9bal, tawa fel
                        // sidebar zeda, mch ghir home/my profile).
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
                                  child: widget.ownerPhotoBytes != null
                                      ? Image.memory(widget.ownerPhotoBytes!, fit: BoxFit.cover)
                                      : widget.ownerPhotoUrl != null
                                          ? Image.network(widget.ownerPhotoUrl!, fit: BoxFit.cover)
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
                          widget.ownerName,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: sizes.sidebarNameFontSize,
                          ),
                        ),
                        if (widget.ownerCity.isNotEmpty) ...[
                          SizedBox(height: sizes.screenHeight * 0.004),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenWidth * 0.012),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              widget.ownerCity,
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
                          MaterialPageRoute(builder: (_) => const MyProfileOwnerScreen()),
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
                      label: 'bookings_label'.tr(),
                      color: AppColors.vertpetsy,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LesReservationsScreen()),
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
                        // 🔵 ba3d ma el user yerja3 (notifications tawa
                        // "read"), n3awdou njibou el count.
                        _fetchUnreadCount();
                      },
                    ),
                    SizedBox(height: sizes.sidebarPillGap),
                    SidebarPillItem(
                      icon: Icons.chat_bubble_outline,
                      label: 'messages_label'.tr(),
                      color: AppColors.vertpetsy,
                      onTap: () => _notImplementedYet(context),
                    ),
                    SizedBox(height: sizes.sidebarPillGap),
                    // 🔵 ZID (kifma tlab): "My Favourites"
                    SidebarPillItem(
                      icon: Icons.favorite_outline,
                      label: 'favourites_label'.tr(),
                      color: AppColors.pinkpetsy,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyFavouritesScreen()),
                        );
                      },
                    ),
                    SizedBox(height: sizes.sidebarPillGap),
                    // 🔵 ZID (kifma tlab): "Settings" (Theme + Language +
                    // Vérification).
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