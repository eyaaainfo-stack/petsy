import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/auth_session.dart';
import '../../repositories/pet_repository.dart';
import '../paw_widget.dart';
import 'sidebar_item.dart';
import '../../views/user/account_type.dart';
import '../../views/user/owner/profile_owner.dart';
import '../../views/user/owner/my_profile_owner.dart';
import '../../views/user/notifications_screen.dart';
import '../../views/user/settings_screen.dart';
import '../../views/user/owner/my_favourites_screen.dart';
import '../../views/user/owner/les_reservations.dart';
import '../../controllers/notification_controller.dart';

// ============================================================================
// SidebarOwner (Drawer tel owner)
// ============================================================================
// 🔵 "kif kif" (kifma tlabt) - NAFS design/mant9 SidebarSitter (widgets/
// drawers/sidebar_sitter.dart) b7ذافيرha (rose ahfef, photo mrabb3a
// akbar fel west, shape melouta, mafamech VetBot) - ghir el esm/navigation
// mbadlin lel "owner".
//
// 🔴 Farq WA7ED 3an SidebarSitter: "Home" houni ASYNC - 7it
// ProfileOwnerScreen yestenna "pets" (obligatoire, List<PetSummary>) -
// fa lezemna njibou el pets mel backend (PetRepository.fetchOwnerPets())
// 9bal ma nnavigui-w, nafs mant9 splash_decider.dart/user_login.dart.
// ============================================================================
class SidebarOwner extends StatefulWidget {
  final String ownerName;
  final String ownerCity;
  final Uint8List? ownerPhotoBytes;
  final String? ownerPhotoUrl;

  const SidebarOwner({
    super.key,
    required this.ownerName,
    required this.ownerCity,
    this.ownerPhotoBytes,
    this.ownerPhotoUrl,
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
            // Header: background rose ahfef, paws, photo mrabb3a akbar
            // fel west + esm
            // ----------------------------------------------------------
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: sizes.sidebarHeaderPadding,
                vertical: sizes.sidebarHeaderPadding,
              ),
              decoration: BoxDecoration(
                color: softPink,
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
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: sizes.screenHeight * 0.015),
                        // 🔴 FIX: rja3t l mrabb3a (ClipRRect) - "meme
                        // design" kifma tlabt (design/shape LEZEM ykoun
                        // kif kif bin owner w sitter, el image kanet
                        // ghir data reference - esm/"Bookings" - mch
                        // design change).
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
                              child: widget.ownerPhotoBytes != null
                                  ? Image.memory(widget.ownerPhotoBytes!, fit: BoxFit.cover)
                                  : widget.ownerPhotoUrl != null
                                      ? Image.network(widget.ownerPhotoUrl!, fit: BoxFit.cover)
                                      : Icon(Icons.person, color: AppColors.pinkpetsy, size: sizes.sidebarPhotoSize * 0.55),
                            ),
                          ),
                        ),
                        SizedBox(height: sizes.screenHeight * 0.014),
                        Text(
                          widget.ownerName,
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
            // Liste el menu (Account/Home/Bookings/Notifications/
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
                        // (my_profile_owner.dart).
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyProfileOwnerScreen()),
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
                      label: 'bookings_label'.tr(), // 🔴 FIX: "Bookings" mch "Calendar" (mockup el owner)
                      sizes: sizes,
                      // 🔴 FIX (kifma tlab): kanet TODO - tawa ymchi l
                      // "Bookings" (les_reservations.dart) - data 7a9i9iya
                      // (GET /api/bookings/mine).
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LesReservationsScreen()),
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
                        // 🔵 ba3d ma el user yerja3 (notifications tawa
                        // "read"), n3awdou njibou el count (bch el badge
                        // yeb9a mzabet, mch stale).
                        _fetchUnreadCount();
                      },
                    ),
                    SidebarItem(
                      icon: Icons.chat_bubble_outline,
                      label: 'messages_label'.tr(),
                      sizes: sizes,
                      onTap: () => _notImplementedYet(context),
                    ),
                    // 🔵 ZID (kifma tlab): "My Favourites"
                    SidebarItem(
                      icon: Icons.favorite_outline,
                      label: 'favourites_label'.tr(),
                      sizes: sizes,
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MyFavouritesScreen()),
                        );
                      },
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
                    backgroundColor: softPink,
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