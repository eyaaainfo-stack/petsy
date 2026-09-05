import 'package:flutter/material.dart';

// ============================================================================
// SitterServiceCatalog (kifma tlab: "les services nhbhom fi des titre w
// ki tenzel alihom yethallou hedhom... ken yhb yzid service ekher")
// ============================================================================
// 🔴 FIX: refonte kaملa tel liste el services (kanet flat, 6 services
// bark) - tawa mnadhmin f categories (Toilettage/Garde d'animaux/
// Promenade/Dressage), kol wa7da fiha el sous-services tou3ha (accordion
// - chraht fel widgets/service_category_selector.dart), + "Autre" (el
// sitter ynajjam yzid service custom, esmou b ydik, lowkan mafamech
// wa7ed mel liste ye9abbel service tou3ou 7a9i9i).
//
// 🔵 blasa WA7DA (single source of truth) - create_sitter_profile.dart
// (signup), update_profile_sitter.dart (édition) w view_profile_sitter.dart
// (affichage, owner) el KOL ysta3malou NAFS el liste houni (bla
// duplication - risque "chwaya mnesyin" lowkan zdna service fi blasa
// wa7da w nsyna el b9iya, kifma sar 9bal m3a el behaviors).
// ============================================================================
class SitterServiceDef {
  final String id;
  final String labelKey;
  const SitterServiceDef({required this.id, required this.labelKey});
}

class SitterServiceCategory {
  final String titleKey;
  final IconData icon;
  final List<SitterServiceDef> services;
  const SitterServiceCategory({required this.titleKey, required this.icon, required this.services});
}

// 🔵 ZID: "Autre" (custom) - serviceId lel entries elli el sitter zad
// b ydik (mch mel catalogue taht) - el esm 7a9i9i mo5azzan fel
// "customLabel" (chraht fel models/my_profile_data.dart, models/sitter.js).
//
// 🔴 FIX: kanet "customServiceMarker" (constante WA7DA, 'custom') -
// lowkan sitter 3andou 2+ services custom, el KOL kanou ye5demou b
// NAFS el id ('custom') - mafamech 7al t-select-i wa7ed mnhom b'rou7ou
// (mathalan fel Set<String> _selectedServiceIds, request_a_book.dart) -
// tawa kol entry custom 3andou id UNIQUE ('custom_<timestamp>').
bool isCustomServiceId(String id) => id.startsWith('custom_');

String generateCustomServiceId() => 'custom_${DateTime.now().microsecondsSinceEpoch}';

const List<SitterServiceCategory> sitterServiceCatalog = [
  SitterServiceCategory(
    titleKey: 'sitter_category_grooming',
    icon: Icons.content_cut,
    services: [
      SitterServiceDef(id: 'grooming_full_bath', labelKey: 'sitter_service_full_bath'),
      SitterServiceDef(id: 'grooming_fur_trim', labelKey: 'sitter_service_fur_trim'),
      SitterServiceDef(id: 'grooming_brushing', labelKey: 'sitter_service_brushing'),
      SitterServiceDef(id: 'grooming_nail_trim', labelKey: 'sitter_service_nail_trim'),
      SitterServiceDef(id: 'grooming_ear_eye_cleaning', labelKey: 'sitter_service_ear_eye_cleaning'),
    ],
  ),
  SitterServiceCategory(
    titleKey: 'sitter_category_pet_sitting',
    icon: Icons.home_outlined,
    services: [
      SitterServiceDef(id: 'sitting_day_care_home', labelKey: 'sitter_service_day_care_home'),
      SitterServiceDef(id: 'sitting_long_term_boarding', labelKey: 'sitter_service_long_term_boarding'),
      SitterServiceDef(id: 'sitting_home_check_visits', labelKey: 'sitter_service_home_check_visits'),
    ],
  ),
  SitterServiceCategory(
    titleKey: 'sitter_category_walking',
    icon: Icons.directions_walk,
    services: [
      SitterServiceDef(id: 'walking_daily_walk', labelKey: 'sitter_service_daily_walk'),
      SitterServiceDef(id: 'walking_running', labelKey: 'sitter_service_running'),
    ],
  ),
  SitterServiceCategory(
    titleKey: 'sitter_category_training',
    icon: Icons.school_outlined,
    services: [
      SitterServiceDef(id: 'training_basic_obedience', labelKey: 'sitter_service_basic_obedience'),
      SitterServiceDef(id: 'training_behavior_correction', labelKey: 'sitter_service_behavior_correction'),
      SitterServiceDef(id: 'training_socialization', labelKey: 'sitter_service_socialization'),
      SitterServiceDef(id: 'training_advanced_agility', labelKey: 'sitter_service_advanced_agility'),
    ],
  ),
];

// 🔵 ZID: map flat (id -> labelKey) mchtou9a mel catalogue fou9 - bch
// view_profile_sitter.dart (w ay blasa te7taj "esm el service mel id")
// ma te7tajch t3awad tekteb el liste mel jdid (single source of truth).
Map<String, String> get sitterServiceLabelKeys => {
      for (final cat in sitterServiceCatalog) for (final s in cat.services) s.id: s.labelKey,
    };

// 🔵 ZID: icon tel category (mch tel service el fardi - 14 icon
// mnafslin kanou aktar mel lezem) - testa3mel fel sitter_calender.dart
// (icon jamb kol booking, "wa9t sur3a" mch detail).
IconData? categoryIconForService(String serviceId) {
  for (final cat in sitterServiceCatalog) {
    if (cat.services.any((s) => s.id == serviceId)) return cat.icon;
  }
  return null;
}