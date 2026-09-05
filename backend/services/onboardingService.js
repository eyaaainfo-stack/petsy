// services/onboardingService.js
const Animal = require('../models/animal');
const Sitter = require('../models/sitter');
const User = require('../models/user');

// ============================================================================
// ensureProfileComplete(user)
// ============================================================================
// 🔴 FIX (bug: "compte déjà mawjoud, ba3d el login yerja3 lel
// UserCreateProfileScreen bدal ProfileOwnerScreen/SitterProfileScreen"):
//
// 🔵 el mochkla el 7a9i9iya: "isProfileComplete" ma yetbeddelch True
// GHIR ki l'appel PATCH /users/me/complete-onboarding yenja7 (chraht
// fel add_pet_photo.dart / sitter_availability_question.dart / sitter_
// availability_setup.dart, "Terminer"/"Next" tel akher étape). Hedha
// l'appel "best-effort" (try/catch fadhi, mch bloquant - kifma tlab
// bch el UX ma tou9afech 3ala appel te9ni) - lakin lowkan yefchel
// (timeout, réseau, server mazel ma b9aach jahez...), el user
// yekmmel el parcours el kol w ychouf ProfileOwnerScreen (mel
// mémoire, el navigation ma tsna9ech b'el PATCH), lakin "isProfileComplete"
// ye39od FALSE fel base l'el abad - w mel marra el jaya (logout/login
// wla restart tel app), user_login.dart/splash_decider.dart yer d-douh
// lel UserCreateProfileScreen mel jdid, 7atta ken el compte 7a9i9i
// "complet" (3andou pets/services déjà mzoudin).
//
// 🔵 EL 7ALL: bدal ma na3atmadou GHIR 3al flag manuel (elli ynajjam
// "yfout" silencieusement), houni nchekkou zeda 3al DATA el 7a9i9iya
// (pets tel owner / services tel sitter) - lowkan el evidence mawjouda
// (el user 3adda el parcours 7a9i9i) lakin el flag mazel false, n-auto-
// correctih (self-heal) houni, w nerja3ouh True direct l'el front.
//
// Testa3mel fel authController.login() W userController.getProfile()
// (el 2 blayes elli el front yestenna 3lihom bch ye5tar el navigation).
// ============================================================================
async function ensureProfileComplete(user) {
  if (user.isProfileComplete === true) return true;

  // 🔵 fullName fadhi = el user 3malha ghir email+password w 5arej
  // (mazel ma bdach el parcours 7a9i9i) - hedha el 7ala "isProfileComplete:
  // false" el asliya/mant9iya, MA nsalliwhach (bla self-heal).
  const fullName = (user.fullName || '').trim();
  if (!fullName) return false;

  let hasEvidence = false;

  if (user.role === 'owner') {
    // 🔵 owner ykammel el parcours ghir ki yzid AY pet (create_pet_
    // profile.dart -> ... -> add_pet_photo.dart, "Terminer").
    hasEvidence = await Animal.exists({ owner: user._id });
  } else if (user.role === 'sitter') {
    // 🔵 sitter ykammel el parcours ghir ki y3addi create_sitter_
    // profile.dart (services) - "residenceType" zeda ye5tar fel étape
    // el jaya (create_sitter_profile_2.dart), fa ay wa7ed mel 2
    // (services wla residenceType mzoud) kaفi bch nchekkou "3adda
    // el parcours 7a9i9i".
    const sitter = await Sitter.findById(user._id).select('services residenceType');
    hasEvidence = !!sitter && (sitter.services?.length > 0 || !!sitter.residenceType);
  }

  if (!hasEvidence) return false;

  // 🔵 self-heal: nsalliw el flag houni w nerja3ouh True direct - el
  // user ma ye7tajch y3awad y3adi el parcours mel jdid.
  await User.findByIdAndUpdate(user._id, { isProfileComplete: true });
  return true;
}

module.exports = { ensureProfileComplete };