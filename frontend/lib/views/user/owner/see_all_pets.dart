import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../constants/app_colors.dart';
import '../../../models/pet_summary.dart';
import '../../../widgets/back_button.dart';
import '../../../widgets/paw_widget.dart';
import '../../../widgets/pet_tile.dart';
import 'create_pet_profile.dart';
import 'pet_profile.dart';

// ============================================================================
// SeeAllPetsScreen ("My Pets")
// ============================================================================
// Yji ba3d "See All" fel profile_owner.dart. Nafs mant9 "Your Pets"
// (grid tel PetTile/AddPetTile, mchtarkin déjà) - ghir b'chekel grid
// kamel (mch sef horizontal), w b CustomBackButton (mch drawer/menu
// icon kifha kif fel design l'oula - chrahtha: "awadhli el bouton
// mtaa el drawer bel back button").
// ============================================================================
class SeeAllPetsScreen extends StatelessWidget {
  final String ownerName;
  final String ownerCity;
  final List<PetSummary> pets;
  final Uint8List? ownerPhotoBytes;

  const SeeAllPetsScreen({
    super.key,
    required this.ownerName,
    required this.ownerCity,
    required this.pets,
    this.ownerPhotoBytes,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // 🐾 Paw (fou9-yemin, kifha kif el design)
            buildPetPaw(context: context, size: screenSize.width * 0.09, topPercent: 0.025, leftPercent: 0.85, color: AppColors.pinkpetsy.withOpacity(0.6)),

            const CustomBackButton(),

            SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: screenSize.height * 0.09),

                  Text(
                    'my_pets_title'.tr(),
                    style: TextStyle(
                      fontSize: screenSize.width * 0.06,
                      fontWeight: FontWeight.bold,
                      color: AppColors.pinkpetsy,
                    ),
                  ),

                  SizedBox(height: screenSize.height * 0.03),

                  // ----------------------------------------------------
                  // Grid: el pets el kol + "Add" fel a5er (kifha kif
                  // el design - Misha, Lucky, ba3dhom "Add").
                  // ----------------------------------------------------
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pets.length + 1, // +1 lel "Add" tile
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: screenSize.width * 0.06,
                      mainAxisSpacing: screenSize.height * 0.025,
                      childAspectRatio: 0.85,
                    ),
                    itemBuilder: (context, index) {
                      // el "Add" tile dima fel A5ER (ba3d el pets el kol)
                      if (index == pets.length) {
                        return Center(
                          child: AddPetTile(
                            size: screenSize.width * 0.28,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CreatePetProfileScreen(
                                    ownerName: ownerName,
                                    ownerCity: ownerCity,
                                    existingPets: pets,
                                    ownerPhotoBytes: ownerPhotoBytes,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }
                      return Center(
                        child: PetTile(
                          pet: pets[index],
                          size: screenSize.width * 0.28,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PetProfileScreen(pet: pets[index])),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  SizedBox(height: screenSize.height * 0.03),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}