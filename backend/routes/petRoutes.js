// routes/petRoutes.js
const express = require('express');
const router = express.Router();

const petController = require('../controllers/petController');
const { petUpload } = require('../middleware/upload');

router.post('/', petController.createPet);

// 🔵 "petUpload.single('photo')": el middleware ye5dhem 9bal el
// controller, yehدi el image w y7ott el path fel "req.file". "photo"
// houni lezem ykoun NAFS el esm elli el front yesta3mlou fel multipart
// request.
router.post('/:petId/photo', petUpload.single('photo'), petController.uploadPetPhoto);

module.exports = router;