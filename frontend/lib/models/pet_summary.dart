import 'dart:typed_data';
import 'package:flutter/material.dart';

// ============================================================================
// PetSummary
// ============================================================================
// Class sghira ("data holder") - tsafer m3a el flow kaملها (create_pet_
// profile -> create_pet_profile_2 -> add_pet_photo -> profile_owner /
// see_all_pets -> pet_profile), bch pet_profile.dart ynajjam ywarri
// EL MA3LOUMET EL KOL elli el user 3amarhom fel inscription (mch bess
// el esm/photo kifha kif kanet 9bal).
//
// 🔴 TODO: lowkan 3andek photoUrl 7a9i9i mel backend (ba3d ma tab3ath
// el photo b multipart), zid 7a9el "photoUrl" w esta3melha bdal el
// bytes fel UI (Image.network).
// ============================================================================
class PetSummary {
  final String name;
  final String petType; // 'dog' wala 'cat'
  final Uint8List? photoBytes;
  // 🔵 ZID: photoUrl (mel backend, ba3d el upload) + id (el MongoDB
  // _id 7a9i9i) - photoBytes te5dem bess houni fi hedhi el session
  // (mémoire), photoUrl teb9a t3aych ba3d ma el user ye5rej mel app
  // (Image.network bدل Image.memory).
  final String? photoUrl;
  final String? id;

  // 🔵 ZID: el ba9i mel data (age/breed/size/gender mel écran el
  // loula, behaviors/careInfo/vet mel écran el thenya) - kanet
  // tenkhla9 lakin ma tsaferch m3a el reste.
  final String? age;
  final String? breed;
  final String? size;
  final String? gender;
  final List<String> behaviors;
  final Map<String, bool> careInfo;
  final String? vetClinicName;
  final String? vetClinicPhone;

  const PetSummary({
    required this.name,
    required this.petType,
    this.photoBytes,
    this.photoUrl,
    this.id,
    this.age,
    this.breed,
    this.size,
    this.gender,
    this.behaviors = const [],
    this.careInfo = const {},
    this.vetClinicName,
    this.vetClinicPhone,
  });

  IconData get icon => Icons.pets;
}