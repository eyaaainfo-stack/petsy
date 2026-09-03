import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../models/pet_summary.dart';
import '../../../services/api_service.dart';
import '../../../controllers/auth_session.dart';
import '../../../widgets/pet_tile.dart';
import '../../../widgets/verified_badge.dart';
import '../../../widgets/drawers/sidebar_owner.dart';
import 'create_pet_profile.dart';
import 'see_all_pets.dart';
import 'pet_profile.dart';
import '../sitter/view_profile_sitter.dart';
import '../notifications_screen.dart';
import '../../../controllers/notification_controller.dart';
import '../../../controllers/favorites_controller.dart';
import 'my_favourites_screen.dart';
import 'search.dart';
import '../../../controllers/checkout_questionnaire_controller.dart';
import '../../../widgets/checkout_questionnaire_dialog.dart';

// ============================================================================
// _SitterSummary
// ============================================================================
// 🔴 TODO: tbadel b appel API 7a9i9i (GET /api/sitters?city=...) ki
// ykoun 3andek el backend route. Tawa el list tebda FADHYA (chrahtha
// tlabt: "sinn yokod feragh, mch tamlhom fake").
// ============================================================================
class _SitterSummary {
  final String? id; // 🔵 ZID: bch nnajjmou nemchiw l'ViewProfileSitterScreen(sitterId: ...)
  final String name;
  final double rating; // 1-5
  final double? distanceKm; // 🔴 FIX: null = mafamech location (owner wela sitter) - mch 0 (elli kan y5alli el user y7es eno "distance 0" 7a9i9i)
  final String city;
  // 🔴 FIX: kanet na9sa tamaman - el card el sitter kan ma3andouch
  // photo, ghir icon generic.
  final String? photoUrl;
  bool isFavorite;
  // 🔵 ZID (kifma tlab: "el tick bhdha pdp hta el users lokhrin yrawha").
  final bool isVerified;

  _SitterSummary({
    this.id,
    required this.name,
    required this.rating,
    required this.distanceKm,
    required this.city,
    this.photoUrl,
    this.isFavorite = false,
    this.isVerified = false,
  });
}

class ProfileOwnerScreen extends StatefulWidget {
  // 🔵 ZID: el esm/blasa/pets tawa yjiw mel flow el 7a9i9i (mch mock)
  final String ownerName;
  final String ownerCity;
  final List<PetSummary> pets;
  // 🔵 ZID: kanet tedhi3 (mkhtara fel UserCreateProfileScreen, ma
  // tousalch lel écran hedha) - tاوة تسافر kaملها.
  final Uint8List? ownerPhotoBytes;
  // 🔴 FIX: bytes mawjoudin ghir direct ba3d signup (mémoire, session
  // 7aliya) - ba3d login mel jdid, 3andna ghir el URL (mel backend,
  // mathalan "/uploads/users/xxx.jpg"). Bla el paramètre hedha, el
  // photo tel owner kanet dima tban icon ba3d login (7atta lowkan
  // 3andou photo mzouda fel base) - nafs el mant9 tel pet (pet_tile.dart).
  final String? ownerPhotoUrl;
  // 🔵 ZID (kifma tlab: "nhbha el tick todhhor hatta fi profile...
  // fel home fel pdp mteou") - badge bleu 3al avatar tel header (home
  // screen), mch ghir "My Profile".
  final bool isVerified;
  // 🔵 ZID (kifma tlab: "ken el user homme nkhalliwh vert, keno femme
  // pink") - couleur el sidebar (header) 7asb el gender.
  final String? gender;

  const ProfileOwnerScreen({
    super.key,
    required this.ownerName,
    required this.ownerCity,
    required this.pets,
    this.ownerPhotoBytes,
    this.ownerPhotoUrl,
    this.isVerified = false,
    this.gender,
  });

  @override
  State<ProfileOwnerScreen> createState() => _ProfileOwnerScreenState();
}

class _ProfileOwnerScreenState extends State<ProfileOwnerScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // 🔴 FIX: kanet mock (True dima) - tawa data 7a9i9iya (GET /api/
  // bookings/notifications/unread-count, fel initState() ta7t).
  bool _hasUnreadNotifications = false;
  final NotificationController _notificationController = NotificationController();
  final FavoritesController _favoritesController = FavoritesController();

  // 🔵 TAWA REAL: nemliw mel backend (GET /api/users/sitters?city=...)
  // fel initState() - el list tebda fadhya ('_isLoadingSitters' true),
  // w tet3emmar ki el appel yerja3.
  List<_SitterSummary> _sittersInMyCity = [];
  bool _isLoadingSitters = true;

  @override
  void initState() {
    super.initState();
    _fetchSitters();
    _fetchUnreadNotificationsCount();
    // 🔵 ZID (kifma tlab): questionnaire ba3d el checkout - nchekkou
    // ba3d el frame el loul (bch "context" ykoun jahez lel dialog).
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPendingQuestionnaires());
  }

  // 🔵 ZID: yjib el liste, ywarri l'wa7ed l'loul (blur backdrop) - lowkan
  // "completed" (mch "Later"), ychek 3la wa7ed okhor mestani w ywarrih
  // zeda (chain, bch el user ma yeb9ach ye7taj yre-open el app lkol wa7ed).
  Future<void> _checkPendingQuestionnaires() async {
    final pending = await CheckoutQuestionnaireController().fetchPending();
    if (!mounted || pending.isEmpty) return;
    final completed = await CheckoutQuestionnaireDialog.show(context, pending.first.bookingId);
    if (completed && mounted) _checkPendingQuestionnaires();
  }

  // 🔴 FIX: el appel el 7a9i9i kan na9es (declaration bark, ma yet3ayetch
  // biha 7atta) - hedhi el sebba el 7a9i9iya elli el bell ma yban-ch fiha
  // notification 7atta lowkan mawjouda 7a9i9atan fel backend.
  Future<void> _fetchUnreadNotificationsCount() async {
    final count = await _notificationController.fetchUnreadCount();
    if (!mounted) return;
    setState(() => _hasUnreadNotifications = count > 0);
  }

  Future<void> _fetchSitters() async {
    try {
      // 🔴 FIX: kanet bla token (route déjà kanet public) - tawa el
      // route protégée (bch el backend ye3ref el owner el connecté w
      // ye7seb el distance) - lezمها token.
      final response = await ApiService.get('/users/sitters?city=${widget.ownerCity}', token: AuthSession.token);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> sittersJson = data['sitters'] as List<dynamic>;

        setState(() {
          // 🔴 FIX (kifma tlab): el backend tawa YERJA3 rating 7a9i9i
          // (moyenne el questionnaires "completed") - mch "0" statique.
          _sittersInMyCity = sittersJson.map((json) {
            final String? rawPhotoUrl = json['photoUrl'] as String?;
            return _SitterSummary(
              id: json['_id'] as String?,
              name: (json['fullName'] as String?)?.isNotEmpty == true
                  ? json['fullName'] as String
                  : json['city'] as String? ?? '',
              rating: (json['rating'] as num?)?.toDouble() ?? 0,
              distanceKm: (json['distanceKm'] as num?)?.toDouble(),
              city: json['city'] as String? ?? '',
              photoUrl: (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawPhotoUrl' : null,
              // 🔵 ZID (kifma tlab): "My Favourites" - el heart mel
              // bidaya sa7i7 (mfilé lowkan déjà favori mel backend).
              isFavorite: json['isFavorite'] as bool? ?? false,
              isVerified: json['isVerified'] as bool? ?? false,
            );
          }).toList();
          _isLoadingSitters = false;
        });
      } else {
        setState(() => _isLoadingSitters = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingSitters = false);
    }
  }

  // 🔴 FIX (kifma tlab): kanet ghir local (setState, tedhi3 ki el user
  // ye5rej mel écran) - tawa te3mel appel 7a9i9i lel backend (mel
  // FavoritesController) bch "yetsajjel 7a9i9atan".
  Future<void> _toggleFavorite(_SitterSummary sitter) async {
    // 🔵 optimistic update - el heart yetbeddel FI EL LAHDHA (bla
    // ma yestenna el appel API), bch el UI y7es sri3.
    setState(() => sitter.isFavorite = !sitter.isFavorite);

    final result = await _favoritesController.toggleFavorite(sitter.id ?? '');
    if (!mounted) return;

    if (result == null) {
      // 🔴 el appel fechel - nrajj3ou el heart l7alto el asliya (revert).
      setState(() => sitter.isFavorite = !sitter.isFavorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    return Scaffold(
      key: _scaffoldKey,
      drawer: SidebarOwner(
        ownerName: widget.ownerName,
        ownerCity: widget.ownerCity,
        ownerPhotoBytes: widget.ownerPhotoBytes,
        ownerPhotoUrl: widget.ownerPhotoUrl,
        isVerified: widget.isVerified,
        gender: widget.gender,
      ),
      body: SafeArea(
        // 🔵 kolchi jowa SingleChildScrollView wa7da - hedhi elli
        // t5alli "Available for urgence sitting" (w el screen kaملها)
        // tنجم tetsecrolli lowkan el sitters aktar mel blasa el fadhya.
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: screenSize.height * 0.02),

              // ------------------------------------------------------
              // Header: photo (mrabba3) + esm/blasa + menu + notif
              // ------------------------------------------------------
              Row(
                children: [
                  // 🔵 photo mrabba3a (mch dayra) - nafs el mant9 elli
                  // t9arret fi add_pet_photo.dart
                  // 🔵 ZID (kifma tlab: "el tick... fel home fel pdp
                  // mteou") - Stack+Positioned, clipBehavior none bch
                  // el badge ma yet9assch mel ClipRRect.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: screenSize.width * 0.13,
                          height: screenSize.width * 0.13,
                          color: AppColors.vertpetsy.withOpacity(0.15),
                          // 🔵 ZID: el photo el 7a9i9iya - bytes (mémoire,
                          // ba3d signup direct) awalan, wala URL (mel
                          // backend, Image.network, ba3d login mel jdid) -
                          // wala icon placeholder. Nafs mant9 el pet
                          // (widgets/pet_tile.dart).
                          child: widget.ownerPhotoBytes != null
                              ? Image.memory(widget.ownerPhotoBytes!, fit: BoxFit.cover)
                              : widget.ownerPhotoUrl != null
                                  ? Image.network(widget.ownerPhotoUrl!, fit: BoxFit.cover)
                                  : Icon(Icons.person, color: AppColors.vertpetsy, size: screenSize.width * 0.08),
                        ),
                      ),
                      if (widget.isVerified)
                        Positioned(
                          right: -3,
                          bottom: -3,
                          child: VerifiedBadge(size: screenSize.width * 0.038),
                        ),
                    ],
                  ),

                  SizedBox(width: screenSize.width * 0.03),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'home_greeting'.tr(namedArgs: {'name': widget.ownerName}),
                          style: TextStyle(
                            fontSize: screenSize.width * 0.042,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          '${widget.ownerCity}, ${'tunisia_label'.tr()}',
                          style: TextStyle(
                            fontSize: screenSize.width * 0.032,
                            color: mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 🔵 7ithna bouton el "paw" (kifma tlabt) - 9na bouton
                  // el menu bess.
                  _HeaderIconButton(
                    icon: Icons.menu,
                    backgroundColor: AppColors.pinkpetsy,
                    size: screenSize.width * 0.10,
                    onTap: () {
                      // 🔴 FIX: kanet TODO - tawa yeftah SidebarOwner
                      // (widgets/drawers/sidebar_owner.dart).
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),

                  SizedBox(width: screenSize.width * 0.02),

                  // 🔵 ZID: bouton notification jdid, b no9ta 7amra
                  // lowkan fama notification jdida.
                  _HeaderIconButton(
                    icon: Icons.notifications_outlined,
                    backgroundColor: AppColors.vertpetsy,
                    size: screenSize.width * 0.10,
                    showBadge: _hasUnreadNotifications,
                    onTap: () {
                      setState(() => _hasUnreadNotifications = false);
                      // 🔴 FIX: kanet TODO - tawa ymchi l "Notifications".
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: screenSize.height * 0.03),

              // ------------------------------------------------------
              // "Your Pets"
              // ------------------------------------------------------
              Row(
                children: [
                  Text(
                    'your_pets_label'.tr(),
                    style: TextStyle(
                      fontSize: screenSize.width * 0.042,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SeeAllPetsScreen(
                            ownerName: widget.ownerName,
                            ownerCity: widget.ownerCity,
                            pets: widget.pets,
                            ownerPhotoBytes: widget.ownerPhotoBytes,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'see_all_label'.tr(),
                      style: TextStyle(
                        fontSize: screenSize.width * 0.032,
                        fontWeight: FontWeight.w600,
                        color: AppColors.vertpetsy,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: screenSize.height * 0.015),

              SizedBox(
                height: screenSize.width * 0.24,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    AddPetTile(
                      size: screenSize.width * 0.18,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreatePetProfileScreen(
                              ownerName: widget.ownerName,
                              ownerCity: widget.ownerCity,
                              existingPets: widget.pets,
                              ownerPhotoBytes: widget.ownerPhotoBytes,
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(width: screenSize.width * 0.04),
                    for (int i = 0; i < widget.pets.length; i++) ...[
                      PetTile(
                        pet: widget.pets[i],
                        size: screenSize.width * 0.18,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PetProfileScreen(pet: widget.pets[i])),
                          );
                        },
                      ),
                      if (i != widget.pets.length - 1) SizedBox(width: screenSize.width * 0.04),
                    ],
                  ],
                ),
              ),

              SizedBox(height: screenSize.height * 0.03),

              // ------------------------------------------------------
              // 🔵 ZID (kifma tlab): "kif nznel ala el search" -> ymchi
              // l'SearchScreen (search.dart) - el barre houni bess UI
              // (readOnly + onTap), el 7a9i9i (autocomplete+filtres)
              // fel écran l'okhor.
              // ------------------------------------------------------
              Container(
                decoration: BoxDecoration(
                  color: AppColors.vertpetsy.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  readOnly: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                  decoration: InputDecoration(
                    hintText: 'search_hint'.tr(),
                    hintStyle: TextStyle(color: mutedTextColor, fontSize: screenSize.width * 0.035),
                    prefixIcon: Icon(Icons.search, color: AppColors.vertpetsy),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: screenSize.height * 0.018),
                  ),
                ),
              ),

              SizedBox(height: screenSize.height * 0.03),

              // ------------------------------------------------------
              // "Available for urgence sitting"
              // ------------------------------------------------------
              Text(
                'available_urgent_sitting_label'.tr(),
                style: TextStyle(
                  fontSize: screenSize.width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),

              SizedBox(height: screenSize.height * 0.015),

              // 🔵 3 7alet mumkina: mazel el appel ye5dem (loading) -
              // wala el appel khlas w el list fadhya (empty state,
              // mch data fake) - wala 3andna sitters 7a9i9iyin (Grid).
              if (_isLoadingSitters)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.06),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.vertpetsy),
                  ),
                )
              else if (_sittersInMyCity.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenSize.height * 0.04),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.pets, color: mutedTextColor.withOpacity(0.5), size: screenSize.width * 0.12),
                        SizedBox(height: screenSize.height * 0.012),
                        Text(
                          'no_sitters_available_label'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: mutedTextColor, fontSize: screenSize.width * 0.034),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // GridView b shrinkWrap+NeverScrollableScrollPhysics bch
                // tetsecrolli m3a el SingleChildScrollView el barranya
                // (mch tetsara3 m3aha 3ala el scroll).
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sittersInMyCity.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: screenSize.width * 0.03,
                    mainAxisSpacing: screenSize.width * 0.03,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final sitter = _sittersInMyCity[index];
                    return _SitterCard(
                      sitter: sitter,
                      screenWidth: screenSize.width,
                      mutedTextColor: mutedTextColor,
                      onFavoriteTap: () => _toggleFavorite(sitter),
                      // 🔵 ZID: dass 3al card -> ViewProfileSitterScreen
                      // (kifma tlab) - bark lowkan 3andna "id" (mel
                      // backend).
                      onTap: sitter.id == null
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ViewProfileSitterScreen(sitterId: sitter.id!, distanceKm: sitter.distanceKm),
                                ),
                              );
                            },
                    );
                  },
                ),

              SizedBox(height: screenSize.height * 0.03),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// _HeaderIconButton: bouton mdawer sghir (menu/notification) + badge
// ============================================================================
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color backgroundColor;
  final double size;
  final VoidCallback onTap;
  final bool showBadge;

  const _HeaderIconButton({
    required this.icon,
    required this.backgroundColor,
    required this.size,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: backgroundColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(size * 0.35),
            ),
            child: Icon(icon, color: backgroundColor, size: size * 0.55),
          ),
          // 🔵 el no9ta el 7amra (badge) - tban ghir lowkan showBadge true
          if (showBadge)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// _SitterCard
// ============================================================================
// 🔵 el 9alb (favoris) TAWA ta7t el photo, fi nefs el sef mte3 el esm
// (esm 3al yesar, 9alb 3al yemin) - mch fou9 el photo kifma kan.
// ============================================================================
class _SitterCard extends StatelessWidget {
  final _SitterSummary sitter;
  final double screenWidth;
  final Color mutedTextColor;
  final VoidCallback onFavoriteTap;
  final VoidCallback? onTap;

  const _SitterCard({
    required this.sitter,
    required this.screenWidth,
    required this.mutedTextColor,
    required this.onFavoriteTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: EdgeInsets.all(screenWidth * 0.02),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔵 photo mrabba3a (mch rectangle) - AspectRatio 1:1, bla
            // 9alb fou9ha tawa (nzelnah taht, chrahtha fou9)
            // 🔵 ZID (kifma tlab: "el tick bhdha pdp hta el users
            // lokhrin yrawha") - Stack barra el ClipRRect (bch el badge
            // ma yet9assch, Positioned lezmou "clipBehavior: none").
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    // 🔴 FIX: kanet TODO (icon generic bark, 7atta lowkan el
                    // sitter 3andou photo mzouda).
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: AppColors.vertpetsy.withOpacity(0.18),
                      child: sitter.photoUrl != null
                          ? Image.network(sitter.photoUrl!, fit: BoxFit.cover)
                          : Icon(Icons.person, color: AppColors.vertpetsy, size: screenWidth * 0.12),
                    ),
                  ),
                  if (sitter.isVerified)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: VerifiedBadge(size: screenWidth * 0.05),
                    ),
                ],
              ),
            ),
          SizedBox(height: screenWidth * 0.015),

          // 🔵 ZID: el esm 3al yesar w el 9alb (favoris) 3al yemin,
          // fi nefs el sef.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  sitter.name,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: screenWidth * 0.034),
                ),
              ),
              GestureDetector(
                onTap: onFavoriteTap,
                child: Icon(
                  sitter.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: AppColors.pinkpetsy,
                  size: screenWidth * 0.045,
                ),
              ),
            ],
          ),

          SizedBox(height: screenWidth * 0.005),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: screenWidth * 0.032),
              SizedBox(width: screenWidth * 0.01),
              Text(sitter.rating.toString(), style: TextStyle(fontSize: screenWidth * 0.028, color: mutedTextColor)),
              SizedBox(width: screenWidth * 0.025),
              Icon(Icons.location_on_outlined, color: mutedTextColor, size: screenWidth * 0.032),
              // 🔴 FIX: kanet dima "0km" (mahroudh el 9dim) - tawa
              // distance 7a9i9iya (Haversine, backend), wla "-" ken
              // el owner wla el sitter ma3andouch location mzouda.
              Text(
                sitter.distanceKm != null ? '${sitter.distanceKm}km' : '-',
                style: TextStyle(fontSize: screenWidth * 0.028, color: mutedTextColor),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}