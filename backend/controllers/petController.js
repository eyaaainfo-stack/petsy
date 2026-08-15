// controllers/petController.js
const Animal = require('../models/animal');

// ============================================================================
// 1. CREATE (Zid pet jdid, bla photo l'hin)
// ============================================================================
exports.createPet = async (req, res) => {
  try {
    const { owner, petType, name, age, breed, size, gender, behaviors, careInfo, vetClinicName, vetClinicPhone } = req.body;

    const pet = await Animal.create({
      owner,
      petType,
      name,
      age,
      breed,
      size,
      gender,
      behaviors,
      careInfo,
      vetClinicName,
      vetClinicPhone,
    });

    res.status(201).json({ message: 'Pet created successfully', pet });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// 2. UPLOAD PHOTO (el image nafsha, route mnfassla)
// ============================================================================
// 🔵 el "upload" middleware (multer, chrahtha fel routes/petRoutes.js)
// yehدi el image w y7otha fel "req.file" 9bal ma tousel houni - houni
// bess n7ottou el PATH tou3ha fel base tel Animal.
// ============================================================================
exports.uploadPetPhoto = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No photo uploaded' });
    }

    const { petId } = req.params;

    // el URL elli el front ynajjam ye3mel biha 3rd el image (chrahtha
    // fel server.js: app.use('/uploads', express.static(...)))
    const photoUrl = `/uploads/pets/${req.file.filename}`;

    const pet = await Animal.findByIdAndUpdate(
      petId,
      { photoUrl },
      { new: true } // yrajja3 el document el jdid (ba3d el update)
    );

    if (!pet) {
      return res.status(404).json({ message: 'Pet not found' });
    }

    res.status(200).json({ message: 'Photo uploaded successfully', pet });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};