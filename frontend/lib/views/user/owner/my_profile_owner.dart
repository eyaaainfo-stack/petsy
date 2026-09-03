import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/verified_badge.dart';
import '../../../controllers/my_profile_controller.dart';
import '../../../models/my_profile_data.dart';
import '../../../models/pet_summary.dart';
import '../../../repositories/pet_repository.dart';
import '../../../services/api_service.dart';
import 'pet_profile.dart';
import 'update_profile_owner.dart';

// ============================================================================
// MyProfileOwnerScreen ("My Profile" tel owner)
// ============================================================================
// 🔵 Wsulha mel Sidebar ("Account") - dima ta3mel appel API jdid (GET
// /api/users/profile + PetRepository.fetchOwnerPets()) ki tefte7.
// ============================================================================
class MyProfileOwnerScreen extends StatefulWidget {
  const MyProfileOwnerScreen({super.key});

  @override
  State<MyProfileOwnerScreen> createState() => _MyProfileOwnerScreenState();
}

class _MyProfileOwnerScreenState extends State<MyProfileOwnerScreen> {
  final MyProfileController _controller = MyProfileController();
  MyProfileData? _profile;
  List<PetSummary> _pets = [];
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

    // 🔵 el zouj appels f nefs el wa9t (mch wa7ed ba3d wa7ed) - a7sen
    // performance (Future.wait).
    final results = await Future.wait([
      _controller.fetchMyProfile(),
      PetRepository.fetchOwnerPets(),
    ]);

    if (!mounted) return;
    final profile = results[0] as MyProfileData?;
    setState(() {
      _profile = profile;
      _pets = results[1] as List<PetSummary>;
      _isLoading = false;
      _hasError = profile == null;
    });
  }

  String _genderLabel(String? gender) {
    if (gender == 'male') return 'male_label'.tr();
    if (gender == 'female') return 'female_label'.tr();
    return '-';
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
                          children: [
                            SizedBox(height: sizes.screenHeight * 0.35),
                            Center(
                              child: Column(
                                children: [
                                  Icon(Icons.error_outline, color: mutedTextColor, size: sizes.screenWidth * 0.12),
                                  SizedBox(height: sizes.screenHeight * 0.012),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.1),
                                    child: Text('no_profile_data_error'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : _OwnerProfileContent(
                          profile: _profile!,
                          pets: _pets,
                          sizes: sizes,
                          mutedTextColor: mutedTextColor,
                          genderLabel: _genderLabel,
                          onEditPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => UpdateProfileOwnerScreen(currentProfile: _profile!)),
                            );
                            if (!mounted) return;
                            _load();
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

class _OwnerProfileContent extends StatelessWidget {
  final MyProfileData profile;
  final List<PetSummary> pets;
  final AppSizes sizes;
  final Color mutedTextColor;
  final String Function(String?) genderLabel;
  final VoidCallback onEditPressed;

  const _OwnerProfileContent({
    required this.profile,
    required this.pets,
    required this.sizes,
    required this.mutedTextColor,
    required this.genderLabel,
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
          child: Text(pillText, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: sizes.myProfilePillFontSize)),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(sizes.screenWidth * 0.05, sizes.screenHeight * 0.022, sizes.screenWidth * 0.05, sizes.screenHeight * 0.018),
          decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.10), borderRadius: BorderRadius.circular(18)),
          child: content,
        ),
      ],
    );
  }

  Widget _miniOutlinedCard({required IconData icon, required String label, required String value}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.016, horizontal: sizes.screenWidth * 0.03),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.pinkpetsy.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.pinkpetsy, size: sizes.screenWidth * 0.05),
            SizedBox(width: sizes.screenWidth * 0.02),
            Expanded(
              child: Text(
                '$label : $value',
                style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.w600, fontSize: sizes.screenWidth * 0.03),
              ),
            ),
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
          child: Text('my_profile_title'.tr(), style: TextStyle(fontSize: sizes.myProfileNameFontSize, fontWeight: FontWeight.bold)),
        ),

        SizedBox(height: sizes.myProfileSectionGap),

        // ---------------------------------------------------------
        // Photo MRABB3A + esm + blasa + bouton edit
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
            InkWell(
              onTap: onEditPressed,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: EdgeInsets.all(sizes.screenWidth * 0.022),
                decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(Icons.edit_outlined, color: AppColors.pinkpetsy, size: sizes.screenWidth * 0.05),
              ),
            ),
          ],
        ),

        SizedBox(height: sizes.myProfileSectionGap),

        // ---------------------------------------------------------
        // 🔴 FIX (kifma tlabt): "About me" tawa ma tbanach 7atta lowkan
        // el owner ma kteb 7atta 7aja (bio fadhya) - mch tban b "-".
        // ---------------------------------------------------------
        if (profile.bio.isNotEmpty) ...[
          _pillCard(
            pillText: 'about_me_label'.tr(),
            content: Text(profile.bio, style: TextStyle(fontSize: sizes.myProfileBodyFontSize, height: 1.4)),
          ),
          SizedBox(height: sizes.myProfileSectionGap),
        ],

        // 🔴 FIX (kifma tlabt): Gender/Birthday tna77aw tamaman mel
        // "My Profile" tel owner (kanou zeydinhom fel message elli 9bal,
        // tawa el owner ma yheبhomch).

        // ---------------------------------------------------------
        // "My pets" - tappable, ymchi l PetProfileScreen
        // ---------------------------------------------------------
        Text('my_pets_title'.tr(), style: TextStyle(fontSize: sizes.myProfileNameFontSize * 0.85, fontWeight: FontWeight.bold)),
        SizedBox(height: sizes.myProfileSectionGap * 0.6),

        if (pets.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.02),
            child: Center(child: Text('no_pets_yet_label'.tr(), style: TextStyle(color: mutedTextColor))),
          )
        else
          for (final pet in pets)
            Padding(
              padding: EdgeInsets.only(bottom: sizes.screenHeight * 0.014),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => PetProfileScreen(pet: pet)));
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenHeight * 0.01),
                  decoration: BoxDecoration(
                    color: AppColors.vertpetsy.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.vertpetsy.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child: Container(
                          width: sizes.screenWidth * 0.1,
                          height: sizes.screenWidth * 0.1,
                          color: AppColors.vertpetsy.withOpacity(0.2),
                          child: pet.photoBytes != null
                              ? Image.memory(pet.photoBytes!, fit: BoxFit.cover)
                              : pet.photoUrl != null
                                  ? Image.network(pet.photoUrl!, fit: BoxFit.cover)
                                  : Icon(Icons.pets, color: AppColors.vertpetsy, size: sizes.screenWidth * 0.05),
                        ),
                      ),
                      SizedBox(width: sizes.screenWidth * 0.03),
                      Expanded(
                        child: Text(pet.name, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.vertpetsy, fontSize: sizes.myProfileBodyFontSize)),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.vertpetsy),
                    ],
                  ),
                ),
              ),
            ),

        SizedBox(height: sizes.myProfileBottomGap),
      ],
    );
  }
}