// routes/adminRoutes.js
const express = require('express');
const router = express.Router();

const adminController = require('../controllers/adminController');
const { protect, isAdmin } = require('../middleware/auth');

// 🔵 ZID: kol el routes houni protégées b (protect + isAdmin) - lezmha
// token JWT sa7i7 W role == 'admin', wala 403.
router.get('/stats', protect, isAdmin, adminController.getStats);
router.get('/registrations/monthly', protect, isAdmin, adminController.getMonthlyRegistrations);

// 🔵 ZID: "Gestion des comptes" (recherche/filtre + CRUD comptes).
router.get('/users', protect, isAdmin, adminController.listUsers);
router.get('/users/:id', protect, isAdmin, adminController.getUserDetail);
router.post('/users', protect, isAdmin, adminController.createUser);
router.put('/users/:id', protect, isAdmin, adminController.updateUser);
router.delete('/users/:id', protect, isAdmin, adminController.deleteUser);

// 🔵 ZID: "Avis" (vue globale el reviews el kol - CheckoutQuestionnaire).
router.get('/reviews', protect, isAdmin, adminController.listReviews);

// 🔵 ZID (kifma tlab: "acteur vérifié - checklist... proposition...
// validation") - checklist + queue "Validation".
// 🔴 FIX (kifma tlab: "fazet el cin... el USER nafsou") - POST
// /users/:id/cin (l'admin yeb3ath 3la isem el user) etna77a - tawa
// POST /users/me/cin (userRoutes.js), el USER nafsou.
router.get('/users/:id/checklist', protect, isAdmin, adminController.getUserChecklist);
router.get('/validations', protect, isAdmin, adminController.listValidations);
router.post('/users/:id/verify', protect, isAdmin, adminController.verifyUser);
router.post('/users/:id/unverify', protect, isAdmin, adminController.unverifyUser);

// 🔵 ZID (kifma tlab: "khalli les conditions... 3and el admin w
// ynajem yamlelhom modification") - seuils configurables (services/
// clients/% avis).
router.get('/verification-settings', protect, isAdmin, adminController.getVerificationSettingsHandler);
router.put('/verification-settings', protect, isAdmin, adminController.updateVerificationSettingsHandler);

module.exports = router;