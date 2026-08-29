// routes/userRoutes.js
const express = require('express');
const router = express.Router();

const userController = require('../controllers/userController');
const { userUpload } = require('../middleware/upload');
const { protect } = require('../middleware/auth');

// 🔵 "protect" 9bal el controller: ychek el token JWT (Authorization
// header), w y7ott req.userId - lowkan token ghalet/mafamech, el
// controller 7ata ma ye5demch (protect twaqqaf el request).
router.get('/profile', protect, userController.getProfile);
router.patch('/profile', protect, userController.updateProfile);

// 🔵 ZID (kifma tlab): "el esm unique kima el insta" - live check
// (user_create_profile.dart, update_profile_owner.dart/update_profile_
// sitter.dart).
router.get('/check-name', protect, userController.checkNameAvailability);

// 🔵 ZID: écrans create_sitter_profile.dart / create_sitter_profile_2.dart
// - PATCH partiel (services WALA home&transport, mch lezمهم el zoùz
// f nefs el appel).
router.patch('/sitter-details', protect, userController.updateSitterDetails);

// 🔴 FIX: kanet "mch protégée" (public) - lakin tawa ne7taj el owner
// el connecté (req.userId) bch najjmou najjmou n7esbou el distance
// bin el owner w kol sitter. Tawa protégée (nafs mant9 el b39dhin).
router.get('/sitters', protect, userController.getSittersByCity);

// 🔵 ZID (kifma tlab): search.dart - autocomplete (esm) + filtres
// (gender/city/win yoskon/distance/kadeh 3ndou fel app).
router.get('/sitters/search', protect, userController.searchSitters);

// 🔴 FIX: kanet bla "protect" - ay wa7ed ynajjam yeb3ath photo l'ay
// userId (bla token) w ybeddel el avatar tel 7ad okhor. Tawa nafs
// el mant9 amni tel petRoutes.js.
router.post('/:userId/photo', protect, userUpload.single('photo'), userController.uploadUserPhoto);

// 🔵 ZID: view_profile_sitter.dart - profile 7AD OKHOR (sitter), mch
// el user el connecté nafsou.
router.get('/:sitterId/public-profile', protect, userController.getSitterPublicProfile);

// 🔵 ZID (kifma tlab): "avis" (questionnaire ba3d checkout) ywalli VRAI
// review, yban 3al profile (view_profile_sitter.dart w profile_owner.dart).
router.get('/:userId/reviews', protect, userController.getUserReviews);

// 🔵 ZID: "My Favourites" (owner) - toggle + liste
router.patch('/favorites/:sitterId/toggle', protect, userController.toggleFavorite);
router.get('/favorites', protect, userController.getMyFavorites);

module.exports = router;