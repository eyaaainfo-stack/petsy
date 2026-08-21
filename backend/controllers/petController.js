// controllers/petController.js
const Animal = require('../models/animal');

// ============================================================================
// 1. CREATE (Zid pet jdid, bla photo l'hin)
// ============================================================================
exports.createPet = async (req, res) => {
  try {
    const { petType, name, age, breed, size, gender, behaviors, careInfo, vetClinicName, vetClinicPhone } = req.body;

    const pet = await Animal.create({
      owner: req.userId, // 🔵 sa77e7t: mel token (protect middleware), MCH mel body
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

// ============================================================================
// 3. GET PETS BY OWNER
// ============================================================================
// 🔵 ZID: hedhi elli el Flutter (user_login.dart) lezمha te3yet biha
// ba3d el login - bch tجib el pets el 7a9i9iyin tel user (mafamech
// ma tab9ach 3andou "pets" ka fadhya kif ye3mel login mel jdid).
// ============================================================================
exports.getPetsByOwner = async (req, res) => {
  try {
    // 🔵 mel token (protect middleware), MCH mel query - nafs el mant9
    // amni tel createPet (bla ha, ay wa7ed ynajjam yechouf pets 7ad okhor).
    const pets = await Animal.find({ owner: req.userId });
    res.status(200).json({ pets });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};