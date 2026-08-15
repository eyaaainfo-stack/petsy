import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../constants/app_colors.dart';
import '../models/pet_summary.dart';

// ============================================================================
// AddPetTile / PetTile
// ============================================================================
// 🔵 nqalou mel profile_owner.dart (kanou _AddPetTile/_PetTile b
// underscore, yesta3malouhom fel fichier hedhak biss) l'houni - tاوة
// PUBLIC (bla underscore) bch nnajmou nsta3malouhom fi see_all_pets.dart
// zeda, bla ma nkarrarou el code.
// ============================================================================
class AddPetTile extends StatelessWidget {
  final double size;
  final VoidCallback onTap;

  const AddPetTile({super.key, required this.size, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.vertpetsy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.add, color: Colors.white, size: size * 0.45),
          ),
          SizedBox(height: size * 0.06),
          Text('add_pet_label'.tr(), style: TextStyle(fontSize: size * 0.14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class PetTile extends StatelessWidget {
  final PetSummary pet;
  final double size;
  // 🔵 ZID: optionnel (mch required) - bch PetTile tab9a te5dem 7ata
  // fi blayes mch lezemhom navigation.
  final VoidCallback? onTap;

  const PetTile({super.key, required this.pet, required this.size, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppColors.pinkpetsy.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            // el photo el 7a9i9iya (mkhtara fel add_pet_photo.dart) lowkan
            // mawjouda, wala icon placeholder.
            child: pet.photoBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(pet.photoBytes!, fit: BoxFit.cover),
                  )
                : Icon(pet.icon, color: AppColors.pinkpetsy, size: size * 0.5),
          ),
          SizedBox(height: size * 0.06),
          Text(pet.name, style: TextStyle(fontSize: size * 0.14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}