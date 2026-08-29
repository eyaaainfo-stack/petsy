import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../models/pet_summary.dart';
import '../../../widgets/back_button.dart';
import 'update_pet_profile.dart';

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
//
// 🔵 ZID: StatefulWidget (mch StatelessWidget kifma kanet) - bch
// nnajjmou n7ottou "bouton stylo" (edit) elli yeftah UpdatePetProfileScreen,
// w ki el user yerja3 mennha b'PetSummary jdid, ne3mlou setState (rebuild
// direct, bla ma ne7tajou refetch el liste el kaملha mel backend).
// ============================================================================
class PetProfileScreen extends StatefulWidget {
  final PetSummary pet;
  // 🔵 ZID (kifma tlab: request.dart, sitter ychouf pet tel owner) -
  // lowkan true, ne5fiw bouton l'edit (stylo) - sitter MA YNAJJAMCH
  // ybeddel data tel pet tel owner.
  final bool readOnly;

  const PetProfileScreen({super.key, required this.pet, this.readOnly = false});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  late PetSummary _pet;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
  }

  Future<void> _onEditPressed() async {
    final PetSummary? updated = await Navigator.of(context).push<PetSummary>(
      MaterialPageRoute(builder: (_) => UpdatePetProfileScreen(pet: _pet)),
    );
    if (updated != null && mounted) {
      setState(() => _pet = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = _pet;
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
              _PetBanner(pet: pet, screenSize: screenSize, onEditPressed: widget.readOnly ? null : _onEditPressed),

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
    // 🔴 FIX (kifma tlabt): "kima tableau" - 2 colonnes (label 3al
    // yesar, "Oui"/"Non" 3al yemin, 7asb el valeur el 7a9i9iya) - mch
    // dot mlouna (elli ma twarrich "Yes"/"No" bel 7arf).
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontSize: screenWidth * 0.038)),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenWidth * 0.01),
            decoration: BoxDecoration(
              color: value ? AppColors.pinkpetsy.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value ? 'yes_label'.tr() : 'no_label'.tr(),
              style: TextStyle(
                fontSize: screenWidth * 0.033,
                fontWeight: FontWeight.w600,
                color: value ? AppColors.pinkpetsy : Colors.grey.shade600,
              ),
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
  final VoidCallback? onEditPressed;

  const _PetBanner({required this.pet, required this.screenSize, required this.onEditPressed});

  @override
  Widget build(BuildContext context) {
    // 🔵 sa77e7t: bannerHeight/photo kanou kbar barcha (0.28/0.30) -
    // "hassithou vulgaire" (kbir zayed 3an el design). Sghart el 2.
    final double pillHeight = screenSize.width * 0.14;
    final double bannerHeight = screenSize.height * 0.20;

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
                top: screenSize.height * 0.015,
                right: screenSize.width * 0.06,
                child: Icon(Icons.pets, color: AppColors.pinkpetsy.withOpacity(0.7), size: screenSize.width * 0.06),
              ),
              Positioned(
                bottom: screenSize.height * 0.03,
                left: screenSize.width * 0.06,
                child: Icon(Icons.pets, color: AppColors.pinkpetsy.withOpacity(0.6), size: screenSize.width * 0.05),
              ),
              Center(
                child: Container(
                  width: screenSize.width * 0.22,
                  height: screenSize.width * 0.22,
                  decoration: BoxDecoration(
                    // 🔵 sa77e7t: mrabba3 b zawaya mdawra (mch dayra) -
                    // nafs mant9 add_pet_photo.dart/profile_owner.dart.
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.pinkpetsy, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: pet.photoBytes != null
                        ? Image.memory(pet.photoBytes!, fit: BoxFit.cover)
                        : pet.photoUrl != null
                            ? Image.network(pet.photoUrl!, fit: BoxFit.cover)
                            : Icon(pet.icon, color: AppColors.pinkpetsy, size: screenSize.width * 0.10),
                  ),
                ),
              ),
            ],
          ),
        ),

        const CustomBackButton(),

        // 🔵 ZID (kifma tlabt): bouton stylo -> UpdatePetProfileScreen
        // (mfaqoud lowkan readOnly - sitter ychouf bark).
        if (onEditPressed != null)
          Positioned(
            top: screenSize.height * 0.015,
            right: screenSize.width * 0.04,
            child: InkWell(
              onTap: onEditPressed,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: EdgeInsets.all(screenSize.width * 0.022),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.7), shape: BoxShape.circle),
                child: Icon(Icons.edit_outlined, color: AppColors.pinkpetsy, size: screenSize.width * 0.05),
              ),
            ),
          ),

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
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.035),
      decoration: BoxDecoration(
        color: AppColors.pinkpetsy.withOpacity(0.12),
        // 🔵 sa77e7t: radius kbar (mch mrabba3 b zawaya cha7i7a) - "mch
        // carre kifma tlabt", tاوة chekel capsule/pilule aktar.
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        children: [
          Container(
            // 🔵 sa77e7t: kanet "shape: BoxShape.circle" - hedhi tekhدem
            // ghir m3a chekel mdawer (dayra), mch m3a ktiba ("Gender"
            // 6 a7rouf ma tدخلch fi dayra bla ma tetkas). Tاوة "pilule"
            // (borderRadius kbir 3ala rectangle, mch dayra 7a9i9iya).
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025, vertical: screenWidth * 0.012),
            decoration: BoxDecoration(
              color: AppColors.pinkpetsy.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(label, style: TextStyle(fontSize: screenWidth * 0.026, fontWeight: FontWeight.w600, color: AppColors.pinkpetsy)),
          ),
          SizedBox(height: screenWidth * 0.02),
          Icon(icon, color: AppColors.pinkpetsy, size: screenWidth * 0.05),
          SizedBox(height: screenWidth * 0.008),
          Text(value, style: TextStyle(fontSize: screenWidth * 0.03, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}