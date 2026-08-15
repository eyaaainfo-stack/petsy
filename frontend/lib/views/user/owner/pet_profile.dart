import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../models/pet_summary.dart';
import '../../../widgets/back_button.dart';

// ============================================================================
// PetProfileScreen
// ============================================================================
// Ywarri EL MA3LOUMET EL KOL tel pet (elli 3amarhom el user fel
// create_pet_profile.dart + create_pet_profile_2.dart + add_pet_photo.dart)
// - yeftah kif dass 3al pet (mel profile_owner.dart "Your Pets" wala
// mel see_all_pets.dart grid, kifma tlabt).
//
// 🔵 "awadhli el bouton mtaa el drawer bel back button" - nafs mant9
// see_all_pets.dart: CustomBackButton (mch menu icon).
//
// 🔴 el "Create/View Moodboard" (mawjoudin fel design) - MECH mawjoudin
// houni, 7it houma mch jozz mel data elli tetzad wa9t l'inscription
// (feature mnfassla, TODO lel mostakbal lowkan tebni).
// ============================================================================
class PetProfileScreen extends StatelessWidget {
  final PetSummary pet;

  const PetProfileScreen({super.key, required this.pet});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final Color textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ------------------------------------------------------
              // Banner rose (photo + paws) - el pill teal tghouss
              // fel a5er tou3ha, nafs mant9 el "_pillCard" mel
              // create_pet_profile_2.dart.
              // ------------------------------------------------------
              _PetBanner(pet: pet, screenSize: screenSize),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.07),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: screenSize.height * 0.05),

                    Text(
                      'about_pet_title'.tr(namedArgs: {'name': pet.name}),
                      style: TextStyle(
                        fontSize: screenSize.width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.015),

                    // Size / Gender / Age
                    Row(
                      children: [
                        Expanded(
                          child: _InfoPill(
                            icon: Icons.monitor_weight_outlined,
                            label: 'pet_size_label'.tr(),
                            value: pet.size?.isNotEmpty == true ? '${pet.size} kg' : '-',
                            screenWidth: screenSize.width,
                          ),
                        ),
                        SizedBox(width: screenSize.width * 0.025),
                        Expanded(
                          child: _InfoPill(
                            icon: Icons.male_outlined,
                            label: 'gender_label'.tr(),
                            value: pet.gender != null
                                ? (pet.gender == 'female' ? 'female_label'.tr() : 'male_label'.tr())
                                : '-',
                            screenWidth: screenSize.width,
                          ),
                        ),
                        SizedBox(width: screenSize.width * 0.025),
                        Expanded(
                          child: _InfoPill(
                            icon: Icons.cake_outlined,
                            label: 'pet_age_label'.tr(),
                            value: pet.age?.isNotEmpty == true ? '${pet.age} ans' : '-',
                            screenWidth: screenSize.width,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: screenSize.height * 0.035),

                    // Behaviors
                    Text(
                      'pet_behaviors_title'.tr(namedArgs: {'name': pet.name}),
                      style: TextStyle(
                        fontSize: screenSize.width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.015),

                    if (pet.behaviors.isEmpty)
                      Text(
                        'no_data_label'.tr(),
                        style: TextStyle(color: AppColors.vertpetsy.withOpacity(0.6), fontSize: screenSize.width * 0.034),
                      )
                    else
                      Wrap(
                        spacing: screenSize.width * 0.03,
                        runSpacing: screenSize.height * 0.015,
                        children: pet.behaviors.map((key) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.04, vertical: screenSize.height * 0.012),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.vertpetsy, width: 1.3),
                            ),
                            child: Text(
                              key.tr(),
                              style: TextStyle(color: AppColors.vertpetsy, fontWeight: FontWeight.w600, fontSize: screenSize.width * 0.033),
                            ),
                          );
                        }).toList(),
                      ),

                    SizedBox(height: screenSize.height * 0.035),

                    // Care info
                    Text(
                      'care_info_label'.tr(),
                      style: TextStyle(
                        fontSize: screenSize.width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    SizedBox(height: screenSize.height * 0.015),

                    _careInfoRow('microchipped_label'.tr(), pet.careInfo['microchipped'] ?? false, screenSize.width),
                    _careInfoRow('vaccinated_label'.tr(), pet.careInfo['vaccinated'] ?? false, screenSize.width),
                    _careInfoRow('neutered_label'.tr(), pet.careInfo['neutered'] ?? false, screenSize.width),
                    _careInfoRow('medication_label'.tr(), pet.careInfo['medication'] ?? false, screenSize.width),

                    // Veterinary info (lowkan mawjouda)
                    if (pet.vetClinicName?.isNotEmpty == true) ...[
                      SizedBox(height: screenSize.height * 0.035),
                      Text(
                        'veterinary_info_label'.tr(),
                        style: TextStyle(
                          fontSize: screenSize.width * 0.045,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.01),
                      Text('${pet.vetClinicName}', style: TextStyle(fontSize: screenSize.width * 0.036)),
                      if (pet.vetClinicPhone?.isNotEmpty == true)
                        Text(pet.vetClinicPhone!, style: TextStyle(fontSize: screenSize.width * 0.036, color: Colors.grey)),
                    ],

                    SizedBox(height: screenSize.height * 0.04),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _careInfoRow(String label, bool value, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontSize: screenWidth * 0.038)),
          SizedBox(width: screenWidth * 0.02),
          Container(
            width: screenWidth * 0.035,
            height: screenWidth * 0.035,
            decoration: BoxDecoration(
              color: value ? AppColors.pinkpetsy : Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _PetBanner: photo kbira + paws + pill "{name}'s Profile"
// ============================================================================
class _PetBanner extends StatelessWidget {
  final PetSummary pet;
  final Size screenSize;

  const _PetBanner({required this.pet, required this.screenSize});

  @override
  Widget build(BuildContext context) {
    final double pillHeight = screenSize.width * 0.16;
    final double bannerHeight = screenSize.height * 0.28;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: bannerHeight,
          decoration: BoxDecoration(
            color: AppColors.pinkpetsy.withOpacity(0.15),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: screenSize.height * 0.02,
                right: screenSize.width * 0.06,
                child: Icon(Icons.pets, color: AppColors.pinkpetsy.withOpacity(0.7), size: screenSize.width * 0.08),
              ),
              Positioned(
                bottom: screenSize.height * 0.06,
                left: screenSize.width * 0.06,
                child: Icon(Icons.pets, color: AppColors.pinkpetsy.withOpacity(0.6), size: screenSize.width * 0.06),
              ),
              Center(
                child: Container(
                  width: screenSize.width * 0.30,
                  height: screenSize.width * 0.30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.pinkpetsy, width: 2.5),
                  ),
                  child: ClipOval(
                    child: pet.photoBytes != null
                        ? Image.memory(pet.photoBytes!, fit: BoxFit.cover)
                        : Icon(pet.icon, color: AppColors.pinkpetsy, size: screenSize.width * 0.14),
                  ),
                ),
              ),
            ],
          ),
        ),

        const CustomBackButton(),

        // Pill teal - tghouss ta7t el banner (nafs mant9 _pillCard)
        Positioned(
          bottom: -pillHeight * 0.4,
          left: screenSize.width * 0.15,
          right: screenSize.width * 0.15,
          child: Container(
            height: pillHeight,
            decoration: BoxDecoration(
              color: AppColors.vertpetsy,
              borderRadius: BorderRadius.circular(25),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'pet_profile_pill_title'.tr(namedArgs: {'name': pet.name}),
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: screenSize.width * 0.036),
                ),
                if (pet.breed?.isNotEmpty == true)
                  Text(
                    pet.breed!,
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: screenSize.width * 0.03),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// _InfoPill: Size / Gender / Age
// ============================================================================
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final double screenWidth;

  const _InfoPill({required this.icon, required this.label, required this.value, required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.03),
      decoration: BoxDecoration(
        color: AppColors.pinkpetsy.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(screenWidth * 0.015),
            decoration: BoxDecoration(color: AppColors.pinkpetsy.withOpacity(0.25), shape: BoxShape.circle),
            child: Text(label, style: TextStyle(fontSize: screenWidth * 0.026, fontWeight: FontWeight.w600, color: AppColors.pinkpetsy)),
          ),
          SizedBox(height: screenWidth * 0.015),
          Icon(icon, color: AppColors.pinkpetsy, size: screenWidth * 0.05),
          SizedBox(height: screenWidth * 0.008),
          Text(value, style: TextStyle(fontSize: screenWidth * 0.03, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}