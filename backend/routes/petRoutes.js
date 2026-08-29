// routes/petRoutes.js
const express = require('express');
const router = express.Router();

const petController = require('../controllers/petController');
const { petUpload } = require('../middleware/upload');
const { protect } = require('../middleware/auth');

// 🔵 ZID: "protect" - bch nnajjmou ne3refou chkoun el owner mel token
// (req.userId), MCH mel body (bla ha, ay wa7ed ynajjam ye5tera3 pet
// tebt7at esm 7ad okhor).
router.post('/', protect, petController.createPet);

// 🔵 ZID: el owner ye3raf mel token ("req.userId" jowa el controller)
// - mch query param, bla ha ay wa7ed ynajjam yechouf pets 7ad okhor.
router.get('/', protect, petController.getPetsByOwner);

// 🔵 "petUpload.single('photo')": el middleware ye5dhem 9bal el
// controller, yehدi el image w y7ott el path fel "req.file". "photo"
// houni lezem ykoun NAFS el esm elli el front yesta3mlou fel multipart
// request.
router.post('/:petId/photo', protect, petUpload.single('photo'), petController.uploadPetPhoto);

// 🔵 ZID: update_pet_profile.dart - PATCH partiel (name/age/breed/size/
// gender/behaviors/careInfo/vetClinicName/vetClinicPhone).
router.patch('/:petId', protect, petController.updatePet);

module.exports = router;