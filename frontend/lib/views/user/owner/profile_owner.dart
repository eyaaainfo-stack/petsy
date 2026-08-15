import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../models/pet_summary.dart';
import '../../../services/api_service.dart';
import '../../../widgets/pet_tile.dart';
import 'create_pet_profile.dart';
import 'see_all_pets.dart';
import 'pet_profile.dart';

// ============================================================================
// _SitterSummary
// ============================================================================
// 🔴 TODO: tbadel b appel API 7a9i9i (GET /api/sitters?city=...) ki
// ykoun 3andek el backend route. Tawa el list tebda FADHYA (chrahtha
// tlabt: "sinn yokod feragh, mch tamlhom fake").
// ============================================================================
class _SitterSummary {
  final String name;
  final double rating; // 1-5
  final double distanceKm;
  final String city;
  bool isFavorite;

  _SitterSummary({
    required this.name,
    required this.rating,
    required this.distanceKm,
    required this.city,
    this.isFavorite = false,
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

  const ProfileOwnerScreen({
    super.key,
    required this.ownerName,
    required this.ownerCity,
    required this.pets,
    this.ownerPhotoBytes,
  });

  @override
  State<ProfileOwnerScreen> createState() => _ProfileOwnerScreenState();
}

class _ProfileOwnerScreenState extends State<ProfileOwnerScreen> {
  bool _hasUnreadNotifications = true; // 🔴 mock - el no9ta el 7amra

  // 🔵 TAWA REAL: nemliw mel backend (GET /api/users/sitters?city=...)
  // fel initState() - el list tebda fadhya ('_isLoadingSitters' true),
  // w tet3emmar ki el appel yerja3.
  List<_SitterSummary> _sittersInMyCity = [];
  bool _isLoadingSitters = true;

  @override
  void initState() {
    super.initState();
    _fetchSitters();
  }

  Future<void> _fetchSitters() async {
    try {
      final response = await ApiService.get('/users/sitters?city=${widget.ownerCity}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final List<dynamic> sittersJson = data['sitters'] as List<dynamic>;

        setState(() {
          // 🔵 el backend tawa ma yرja3ch rating/distance (mazel ma
          // 3andouch système reviews/geoloc) - n7ottou 0 mo2a99tan,
          // TODO ki ykoun 3andek hedhoum el 7isabet.
          _sittersInMyCity = sittersJson.map((json) {
            return _SitterSummary(
              name: (json['fullName'] as String?)?.isNotEmpty == true
                  ? json['fullName'] as String
                  : json['city'] as String? ?? '',
              rating: 0,
              distanceKm: 0,
              city: json['city'] as String? ?? '',
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

  void _toggleFavorite(_SitterSummary sitter) {
    setState(() => sitter.isFavorite = !sitter.isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    return Scaffold(
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: screenSize.width * 0.13,
                      height: screenSize.width * 0.13,
                      color: AppColors.vertpetsy.withOpacity(0.15),
                      // 🔵 ZID: el photo el 7a9i9iya lowkan el owner
                      //5tarha (UserCreateProfileScreen) - kanet tedhi3
                      // 9bal, tاوة تسافر lel écran hedha.
                      child: widget.ownerPhotoBytes != null
                          ? Image.memory(widget.ownerPhotoBytes!, fit: BoxFit.cover)
                          : Icon(Icons.person, color: AppColors.vertpetsy, size: screenSize.width * 0.08),
                    ),
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
                      // TODO: yeftah el drawer/menu
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
                      // TODO: navigation lel écran notifications
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
              // 🔵 el case tel recherche - TAWA bess UI (bla mant9),
              // kifma tlabt.
              // ------------------------------------------------------
              Container(
                decoration: BoxDecoration(
                  color: AppColors.vertpetsy.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
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

  const _SitterCard({
    required this.sitter,
    required this.screenWidth,
    required this.mutedTextColor,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              // TODO: Image.network(sitter.photoUrl) lowkan mawjouda
              child: Container(
                width: double.infinity,
                color: AppColors.vertpetsy.withOpacity(0.18),
                child: Icon(Icons.person, color: AppColors.vertpetsy, size: screenWidth * 0.12),
              ),
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
              Text('${sitter.distanceKm}km', style: TextStyle(fontSize: screenWidth * 0.028, color: mutedTextColor)),
            ],
          ),
        ],
      ),
    );
  }
}