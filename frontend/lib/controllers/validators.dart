import 'package:easy_localization/easy_localization.dart';

// ============================================================================
// Validators
// ============================================================================
// Class "static" biha el functions el validation el CHTARKA bin
// user_login.dart w user_signin.dart. Bch ma nkarrarouch nafs el code
// fel 2 fichiers - hedha balgha "DRY" (Don't Repeat Yourself).
//
// Validators._() taht = "private constructor" - ma3neha ma tnajjamch
// te3mel "Validators()" (instance mel class), 7it el class biha ghir
// static functions, mafamech "state" te7taj instance. Testa3melha
// direct: Validators.email(value), bla "new".
// ============================================================================
class Validators {
  Validators._();

  // Email: khadem fel LOGIN w el SIGNUP kifkif (nafs el format check)
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'email_required_error'.tr();
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'email_invalid_error'.tr();
    }
    return null;
  }

  // --------------------------------------------------------------------
  // Password LOGIN: bess "ma yeb9ach fadhi". 3lech mch rules 9awiya
  // houni zeda? 7it el user 3andou déjà compte w password mkhtar mel
  // 9bal (elli t7at3 el rules 3lih fel SIGNUP) - fel login el compte
  // rah déjà existant, el rules t3awed ma3neha mahouch loji9i.
  // --------------------------------------------------------------------
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required_error'.tr();
    }
    return null;
  }

  // --------------------------------------------------------------------
  // Password SIGNUP: rules 9awiya (tal9ithom kif tlabt):
  //   - 8 caractères 3ala l'a9al
  //   - 1 7arf kbir (majuscule) 3ala l'a9al
  //   - 1 ra9m (chiffre) 3ala l'a9al
  // Kol condition tcheck WA7DAHA w terja3 el message el mounasib, bch
  // el user ye3raf BALDHA chnowa el 7aja elli na9sa (mch message wa7ed
  // 3am "password faible").
  // --------------------------------------------------------------------
  static String? signupPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'password_required_error'.tr();
    }
    if (value.length < 8) {
      return 'password_min_length_error'.tr();
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'password_uppercase_error'.tr();
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'password_digit_error'.tr();
    }
    // 🔵 ZID (kifma tlab: "nhb 8 car min w 1 maj w 1 chif w 1 sambole
    // min") - symbole = 7arf mch alphanumeric (mch A-Z/a-z/0-9) -
    // regex négative (kol 7arf elli mch letter/digit ynajjam yeb9a
    // "symbole": !@#$%^&*()_+-=... etc.)
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(value)) {
      return 'password_symbol_error'.tr();
    }
    return null;
  }
}