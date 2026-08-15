// routes/userRoutes.js
const express = require('express');
const router = express.Router();

const userController = require('../controllers/userController');
const { userUpload } = require('../middleware/upload');
const { protect } = require('../middleware/auth');

// 🔵 "protect" 9bal el controller: ychek el token JWT (Authorization
// header), w y7ott req.userId - lowkan token ghalet/mafamech, el
// controller 7ata ma ye5demch (protect twaqqaf el request).
router.patch('/profile', protect, userController.updateProfile);

// 🔵 mch protégée (GET public) - ay wa7ed ynajjam yechouf el sitters
// (kifha kif "l9a sitter" fel app, mch lezmou ykoun logué).
router.get('/sitters', userController.getSittersByCity);

// nafs mant9 petRoutes.js - "userUpload.single('photo')" ye5dhem 9bal
// el controller, yehdi el image w y7ott el path fel "req.file".
router.post('/:userId/photo', userUpload.single('photo'), userController.uploadUserPhoto);

module.exports = router;