import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/verified_badge.dart';
import '../../../controllers/my_profile_controller.dart';
import '../../../models/my_profile_data.dart';
import '../../../models/sitter_service_catalog.dart';
import '../../../services/api_service.dart';
import 'update_profile_sitter.dart';

// ============================================================================
// MyProfileSitterScreen ("My Profile" - fiha data 7a9i9iya, mch mockup)
// ============================================================================
// 🔵 Wsulha mel Sidebar ("Account") - dima ta3mel appel API jdid (GET
// /api/users/profile) ki tefte7 (bch tban dima el data el akhira, 7atta
// ba3d Update).
// ============================================================================
class MyProfileSitterScreen extends StatefulWidget {
  const MyProfileSitterScreen({super.key});

  @override
  State<MyProfileSitterScreen> createState() => _MyProfileSitterScreenState();
}

class _MyProfileSitterScreenState extends State<MyProfileSitterScreen> {
  final MyProfileController _controller = MyProfileController();
  MyProfileData? _profile;
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

    final profile = await _controller.fetchMyProfile();

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _isLoading = false;
      _hasError = profile == null;
    });
  }

  // 🔴 FIX (kifma tlab: "les services nhbhom fi des titre... ken yhb
  // yzid service ekher") - sitterServiceLabelKeys mel catalogue partagé
  // (bدal liste mkarrra houni) - "custom" (Autre) yesta3mel "customLabel".
  String _serviceLabel(SitterServiceEntry service) {
    if (isCustomServiceId(service.serviceId)) {
      return (service.customLabel != null && service.customLabel!.isNotEmpty) ? service.customLabel! : service.serviceId;
    }
    final key = sitterServiceLabelKeys[service.serviceId];
    return key != null ? key.tr() : service.serviceId;
  }

  String _residenceLabel(String? residenceType) {
    switch (residenceType) {
      case 'apartment':
        return 'sitter_residence_apartment'.tr();
      case 'house':
        return 'sitter_residence_house'.tr();
      case 'countryHouse':
        return 'sitter_residence_country_house'.tr();
      default:
        return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor =
        Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.65) ?? Colors.grey;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              color: AppColors.pinkpetsy,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasError || _profile == null
                      ? ListView(
                          // 🔵 ListView (mch Center/Column 3adiya) bch
                          // "pull to refresh" ye5dem 7atta fel error state.
                          children: [
                            SizedBox(height: sizes.screenHeight * 0.35),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline, color: mutedTextColor, size: sizes.screenWidth * 0.12),
                                  SizedBox(height: sizes.screenHeight * 0.012),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.1),
                                    child: Text(
                                      'no_profile_data_error'.tr(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: mutedTextColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : _ProfileContent(
                          profile: _profile!,
                          sizes: sizes,
                          mutedTextColor: mutedTextColor,
                          serviceLabel: _serviceLabel,
                          residenceLabel: _residenceLabel,
                          onEditPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => UpdateProfileSitterScreen(currentProfile: _profile!),
                              ),
                            );
                            if (!mounted) return;
                            _load(); // 🔵 ba3d ma el user yerja3 mel Update, n3awdou njibou el data el jdida
                          },
                        ),
            ),

            const CustomBackButton(),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// _ProfileContent: el UI el kamel (photo/esm/about me/residence/rates/
// services) - mfassel 3an el state class bch el build() ma yeb9ach twil.
// ============================================================================
class _ProfileContent extends StatelessWidget {
  final MyProfileData profile;
  final AppSizes sizes;
  final Color mutedTextColor;
  final String Function(SitterServiceEntry) serviceLabel;
  final String Function(String?) residenceLabel;
  final VoidCallback onEditPressed;

  const _ProfileContent({
    required this.profile,
    required this.sizes,
    required this.mutedTextColor,
    required this.serviceLabel,
    required this.residenceLabel,
    required this.onEditPressed,
  });

  Widget _pillCard({required String pillText, required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.012),
          decoration: BoxDecoration(color: AppColors.pinkpetsy, borderRadius: BorderRadius.circular(30)),
          alignment: Alignment.center,
          child: Text(
            pillText,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.myProfilePillFontSize),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            sizes.screenWidth * 0.05,
            sizes.screenHeight * 0.022,
            sizes.screenWidth * 0.05,
            sizes.screenHeight * 0.018,
          ),
          decoration: BoxDecoration(
            color: AppColors.pinkpetsy.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _miniInfoCard({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.018, horizontal: sizes.screenWidth * 0.02),
        decoration: BoxDecoration(
          color: AppColors.pinkpetsy.withOpacity(0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: sizes.screenWidth * 0.026, color: mutedTextColor)),
            SizedBox(height: sizes.screenHeight * 0.008),
            Icon(icon, color: AppColors.pinkpetsy, size: sizes.myProfileMiniCardIconSize),
            SizedBox(height: sizes.screenHeight * 0.006),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.screenWidth * 0.032)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: sizes.myProfileHorizontalPadding),
      children: [
        SizedBox(height: sizes.myProfileTopGap),

        Center(
          child: Text(
            'my_profile_title'.tr(),
            style: TextStyle(fontSize: sizes.myProfileNameFontSize, fontWeight: FontWeight.bold),
          ),
        ),

        SizedBox(height: sizes.myProfileSectionGap),

        // ---------------------------------------------------------
        // Photo MRABB3A (kifma tlabt) + esm + blasa + bouton edit
        // ---------------------------------------------------------
        Row(
          children: [
            // 🔵 ZID (kifma tlab: "el validation eli noksod biha hia
            // kima el tick el zarka eli tji fel insta ala el pdp") -
            // Stack + Positioned (bottom-right, kifha kif Instagram) -
            // VerifiedBadge ghir ken profile.isVerified true.
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: sizes.myProfilePhotoSize,
                    height: sizes.myProfilePhotoSize,
                    color: AppColors.vertpetsy.withOpacity(0.15),
                    child: profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                        ? Image.network('${ApiService.mediaBaseUrl}${profile.photoUrl}', fit: BoxFit.cover)
                        : Icon(Icons.person, color: AppColors.vertpetsy, size: sizes.myProfilePhotoSize * 0.5),
                  ),
                ),
                if (profile.isVerified)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: VerifiedBadge(size: sizes.myProfilePhotoSize * 0.28),
                  ),
              ],
            ),
            SizedBox(width: sizes.screenWidth * 0.04),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.fullName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.myProfileNameFontSize * 0.85)),
                  SizedBox(height: sizes.screenHeight * 0.004),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: sizes.myProfileCityFontSize, color: mutedTextColor),
                      SizedBox(width: sizes.screenWidth * 0.01),
                      Text('${profile.city}, ${'tunisia_label'.tr()}', style: TextStyle(fontSize: sizes.myProfileCityFontSize, color: mutedTextColor)),
                    ],
                  ),
                ],
              ),
            ),
            // 🔵 ZID (kifma tlabt): stylo -> Update My Profile
            InkWell(
              onTap: onEditPressed,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: EdgeInsets.all(sizes.screenWidth * 0.022),
                decoration: BoxDecoration(color: AppColors.vertpetsy.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(Icons.edit_outlined, color: AppColors.vertpetsy, size: sizes.screenWidth * 0.05),
              ),
            ),
          ],
        ),

        SizedBox(height: sizes.myProfileSectionGap),

        // ---------------------------------------------------------
        // About me
        // ---------------------------------------------------------
        _pillCard(
          pillText: 'about_me_label'.tr(),
          content: Text(
            profile.bio.isNotEmpty ? profile.bio : '-',
            style: TextStyle(fontSize: sizes.myProfileBodyFontSize, height: 1.4),
          ),
        ),

        SizedBox(height: sizes.myProfileSectionGap),

        // ---------------------------------------------------------
        // "I live in" / "means of transportation"
        // ---------------------------------------------------------
        Row(
          children: [
            _miniInfoCard(
              icon: Icons.home_outlined,
              label: 'i_live_in_label'.tr(),
              value: residenceLabel(profile.residenceType),
            ),
            SizedBox(width: sizes.screenWidth * 0.03),
            _miniInfoCard(
              icon: profile.hasTransportation == true ? Icons.directions_car_outlined : Icons.directions_walk,
              label: 'means_of_transportation_label'.tr(),
              value: profile.hasTransportation == true ? 'has_car_label'.tr() : 'no_car_label'.tr(),
            ),
          ],
        ),

        // 🔴 FIX: kanet mjabda mel backend (profile.hasPetAtHome/
        // ownedPetTypes) lakin ma kanetch tban 7atta fel écran - tawa
        // zdithom (nafs style el zouj cards el fou9).
        if (profile.hasPetAtHome != null) ...[
          SizedBox(height: sizes.screenHeight * 0.015),
          Row(
            // 🔴 FIX: _miniInfoCard yrajja3 "Expanded" mel dakhel (bch
            // ye5dem sa7i7 fel Row el fou9 m3a 2 cards) - lezmou ykoun
            // DIMA jowa Row/Column, mch standalone fi ListView direct
            // (Expanded barra Flex widget = crash "RenderFlex...").
            children: [
              _miniInfoCard(
                icon: Icons.pets,
                label: 'sitter_has_pet_question'.tr(),
                value: profile.hasPetAtHome == true
                    ? profile.ownedPetTypes
                        .map((t) => t == 'dog' ? 'sitter_pet_type_dog'.tr() : 'sitter_pet_type_cat'.tr())
                        .join(' & ')
                    : 'no_label'.tr(),
              ),
            ],
          ),
        ],

        SizedBox(height: sizes.myProfileSectionGap),

        // ---------------------------------------------------------
        // 🔴 FIX (kifma tlabt): "Rates" w "Services Offered" tawa
        // BOX WA7DA bark (mch mnfassleen) - kol service m3ah el
        // prix mte3ou 9damou, bla ma nkarrar el liste marratayn.
        // ---------------------------------------------------------
        if (profile.services.isNotEmpty)
          _pillCard(
            pillText: 'rates_label'.tr(),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final service in profile.services)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.006),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.025, vertical: sizes.screenHeight * 0.004),
                          decoration: BoxDecoration(color: AppColors.pinkpetsy, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            '${service.price.toStringAsFixed(0)} DT',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.myProfileBodyFontSize * 0.85),
                          ),
                        ),
                        SizedBox(width: sizes.screenWidth * 0.025),
                        Expanded(child: Text(serviceLabel(service), style: TextStyle(fontSize: sizes.myProfileBodyFontSize))),
                      ],
                    ),
                  ),
              ],
            ),
          ),

        SizedBox(height: sizes.myProfileBottomGap),
      ],
    );
  }
}