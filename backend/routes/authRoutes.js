// routes/authRoutes.js
const express = require('express');
const router = express.Router();

// ⚠️ Lezem '../controllers/authController' (zūz noqṭāt '..' bāsh takhrej mel-folder routes w tdkhoul l-controllers)
const authController = require('../controllers/authController');

// Route Login (Lil-Admin, Sitter, Owner, Courier)
router.post('/login', authController.login);

// Route Register (Lil-Sitter, Owner, Courier)
router.post('/register', authController.register);

module.exports = router;