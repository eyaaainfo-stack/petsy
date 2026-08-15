import 'dart:convert';
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
    if (value.trim().length != 8) {
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
  Future<bool> submitProfile({
    required String role,
    required String name,
    required String birthday,
    required String city,
    required String phone,
    required String aboutYou,
    LatLng? location,
  }) async {
    try {
      final response = await ApiService.patch(
        '/users/profile',
        {
          'fullName': name,
          'phone': phone,
          'city': city,
          if (location != null)
            'location': {'lat': location.latitude, 'lng': location.longitude},
          // TODO: birthday/aboutYou - lezmhom 7ou9oul jdida fel User
          // schema (mazel mch mzoudin) ki tحب tzidhom.
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