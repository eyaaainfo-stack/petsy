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

// 🔵 ZID: écrans create_sitter_profile.dart / create_sitter_profile_2.dart
// - PATCH partiel (services WALA home&transport, mch lezمهم el zoùz
// f nefs el appel).
router.patch('/sitter-details', protect, userController.updateSitterDetails);

// 🔵 mch protégée (GET public) - ay wa7ed ynajjam yechouf el sitters
// (kifha kif "l9a sitter" fel app, mch lezmou ykoun logué).
router.get('/sitters', userController.getSittersByCity);

// 🔴 FIX: kanet bla "protect" - ay wa7ed ynajjam yeb3ath photo l'ay
// userId (bla token) w ybeddel el avatar tel 7ad okhor. Tawa nafs
// el mant9 amni tel petRoutes.js.
router.post('/:userId/photo', protect, userUpload.single('photo'), userController.uploadUserPhoto);

module.exports = router;