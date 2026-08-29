import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:latlong2/latlong.dart';
import '../services/api_service.dart';
import 'auth_session.dart';

// ============================================================================
// tunisiaGovernorates
// ============================================================================
// El 24 wilaya tounsiya, lezmin lel "City" (dropdown/bottom sheet).
// 🔵 Asmeihom b'a7rouf latinia mahiin (mch traduits fel 3 loughat) - hedhi
// convention mesta3mla brcha (asmeh el wilayet ma yetbeddlouch bel
// lougha, kifha kif asmeh el bledan).
// ============================================================================
const List<String> tunisiaGovernorates = [
  'Ariana',
  'Béja',
  'Ben Arous',
  'Bizerte',
  'Gabès',
  'Gafsa',
  'Jendouba',
  'Kairouan',
  'Kasserine',
  'Kébili',
  'Le Kef',
  'Mahdia',
  'La Manouba',
  'Médenine',
  'Monastir',
  'Nabeul',
  'Sfax',
  'Sidi Bouzid',
  'Siliana',
  'Sousse',
  'Tataouine',
  'Tozeur',
  'Tunis',
  'Zaghouan',
];

// ============================================================================
// matchTunisianGovernorate
// ============================================================================
// 🔵 ZID: Nominatim (reverse-geocoding, widgets/map.dart) yrajja3 "state"
// b'ay format ("Sfax", "Béja"/"Beja" bla accent, "Kef" bla "Le"...) -
// hedhi el fonction tsib el wilaya el 3adia mel tunisiaGovernorates elli
// t9areb (case/accent-insensitive, w tsib "Le"/"La" el préfixe).
// Terja3 "null" ken ma l9atch match (mathalan location barra Tounes).
//
// 🔴 FIX: Nominatim ynajjam yrajja3 "state" BEL 3ARBI ("ولاية صفاقس")
// 7atta ki tطlobنا el fransi (accept-language=fr) - khousousan lel
// blayet el mtaghshiya (rate-limit cache 3and Nominatim). Fa zdit
// "filet de sécurité": matching bel 3arbi zeda (esm el wilaya bel
// 3arbi, mel liste _arabicGovernorateNames ta7t).
// ============================================================================
const Map<String, String> _arabicGovernorateNames = {
  'أريانة': 'Ariana',
  'باجة': 'Béja',
  'بن عروس': 'Ben Arous',
  'بنزرت': 'Bizerte',
  'قابس': 'Gabès',
  'قفصة': 'Gafsa',
  'جندوبة': 'Jendouba',
  'القيروان': 'Kairouan',
  'القصرين': 'Kasserine',
  'قبلي': 'Kébili',
  'الكاف': 'Le Kef',
  'المهدية': 'Mahdia',
  'منوبة': 'La Manouba',
  'مدنين': 'Médenine',
  'المنستير': 'Monastir',
  'نابل': 'Nabeul',
  'صفاقس': 'Sfax',
  'سيدي بوزيد': 'Sidi Bouzid',
  'سليانة': 'Siliana',
  'سوسة': 'Sousse',
  'تطاوين': 'Tataouine',
  'توزر': 'Tozeur',
  'تونس': 'Tunis',
  'زغوان': 'Zaghouan',
};

String _normalizeGovernorateName(String s) {
  return s
      .toLowerCase()
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ô', 'o')
      .replaceAll('â', 'a')
      .replaceAll(RegExp(r'^(le|la|l\x27)\s+'), '')
      .trim();
}

String? matchTunisianGovernorate(String? rawStateName) {
  if (rawStateName == null || rawStateName.trim().isEmpty) return null;

  // 🔵 1️⃣ chek bel 3arbi awalan (contains - Nominatim yeb3ath "ولاية
  // صفاقس", mch "صفاقس" bark, fa exact match ma ye5demch).
  for (final entry in _arabicGovernorateNames.entries) {
    if (rawStateName.contains(entry.key)) return entry.value;
  }

  // 🔵 2️⃣ chek bel fransi/latin (normalized, kifma kanet).
  final String normalizedInput = _normalizeGovernorateName(rawStateName);
  for (final governorate in tunisiaGovernorates) {
    final String normalizedGov = _normalizeGovernorateName(governorate);
    if (normalizedGov == normalizedInput || normalizedInput.contains(normalizedGov) || normalizedGov.contains(normalizedInput)) {
      return governorate;
    }
  }
  return null;
}

// ============================================================================
// ProfileValidators
// ============================================================================
class ProfileValidators {
  ProfileValidators._();

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'name_required_error'.tr();
    }
    return null;
  }

  // --------------------------------------------------------------------
  // Phone: LEZEM 8 ra9ma bel 7arf (mch bess "ma yeb9ach fadhi"). El
  // TextField nfsou (fel écran) ye5alli el user yekteb GHIR ar9am b'el
  // inputFormatters, houni nchekkou el 6oul bel 7arf.
  // --------------------------------------------------------------------
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'phone_required_error'.tr();
    }
    // 🔴 FIX (kifma tlab): el 7a9el tawa formaté ("+216 XX XXX XXX")
    // - ne5dou GHIR el ar9am el 7a9i9iyin (na7i "216" tel prefix zeda)
    // bch el validation ma tet3atalch.
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('216')) digits = digits.substring(3);
    if (digits.length != 8) {
      return 'phone_invalid_error'.tr();
    }
    return null;
  }

  // --------------------------------------------------------------------
  // About you: obligatoire GHIR lel "sitter" w "courier" (mch lel
  // "owner") - hedhi 3lech el function te5tej "role" b'zeda, mch kifha
  // kif el validators l'okhrin elli "static rules" fixe.
  // --------------------------------------------------------------------
  static String? aboutYou(String? value, String role) {
    final bool isRequired = role == 'sitter' || role == 'courier';
    if (!isRequired) return null; // owner: optionnel, ay 7aja tsa77

    if (value == null || value.trim().isEmpty) {
      return 'about_you_required_error'.tr();
    }
    return null;
  }
}

// ============================================================================
// UserCreateProfileController
// ============================================================================
// 🔴 TAWA REAL - appel PATCH /api/users/profile (route "protégée",
// te7taj token JWT - AuthSession.token, elli AuthController.signUp()
// 7attou déjà fel mémoire).
// ============================================================================
class UserCreateProfileController {
  // 🔵 ZID (kifma tlab): "el esm unique kima el insta" - live check
  // (debounced mel écran) ki el user yekteb. Terja3 true (disponible)/
  // false (meakhoud)/null (erreur réseau - ma nwarrouch "meakhoud"
  // b'ghalta ken el appel fechel).
  Future<bool?> checkNameAvailability(String name) async {
    if (name.trim().isEmpty) return null;
    try {
      final response = await ApiService.get(
        '/users/check-name?name=${Uri.encodeQueryComponent(name.trim())}',
        token: AuthSession.token,
      );
      if (response.statusCode != 200) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['available'] as bool?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> submitProfile({
    required String role,
    required String name,
    required String birthday,
    required String city,
    required String phone,
    required String aboutYou,
    LatLng? location,
    String? locationName,
    String? gender,
  }) async {
    // 🔵 ZID: print UNCONDITIONNEL - bch nchoufou b'a3yonna chnowa
    // el valeurs el 7a9i9iyin (khousousan "aboutYou") 9bal ma tab3ath.
    debugPrint('🟠 [submitProfile] name="$name" birthday="$birthday" city="$city" phone="$phone" aboutYou="$aboutYou" gender="$gender" locationName="$locationName"');
    try {
      final response = await ApiService.patch(
        '/users/profile',
        {
          'fullName': name,
          'phone': phone,
          'city': city,
          if (location != null)
            'location': {'lat': location.latitude, 'lng': location.longitude},
          // 🔴 FIX: kanou TODO (backend ma3andouch 7ou9oul lihom) -
          // tawa el User model 3andou "birthday"/"bio", fa nab3thouhom.
          'birthday': birthday,
          'bio': aboutYou,
          // 🔵 ZID: gender + esm el blasa (reverse-geocoding).
          if (gender != null) 'gender': gender,
          if (locationName != null) 'locationName': locationName,
        },
        token: AuthSession.token, // 🔵 mel session, chrahtha fel AuthController
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
        final Map<String, dynamic> user = data['user'] as Map<String, dynamic>;
        // 🔵 n7ottou el city fel session zeda - profile_owner.dart
        // testa3melha bch tel9a sitters mel nefs el ville.
        AuthSession.userCity = user['city'] as String?;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}