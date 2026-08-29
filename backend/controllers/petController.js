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

// ============================================================================
// 4. UPDATE PET (route "protégée" - lezem el pet ykoun mte3 el user
// el connecté, MCH ay pet)
// ============================================================================
// 🔵 ZID: update_pet_profile.dart (Flutter) - PATCH partiel (ghir el
// 7ou9oul elli el user beddel). "owner: req.userId" fel filter (mch
// bark "_id: petId") - bch ay wa7ed ma ynajjamch ybeddel pet 7ad okhor
// (7atta ken ye5men el petId 7a9i9i).
// ============================================================================
exports.updatePet = async (req, res) => {
  try {
    const { petId } = req.params;
    const { name, age, breed, size, gender, behaviors, careInfo, vetClinicName, vetClinicPhone } = req.body;

    const updates = {};
    if (name !== undefined) updates.name = name;
    if (age !== undefined) updates.age = age;
    if (breed !== undefined) updates.breed = breed;
    if (size !== undefined) updates.size = size;
    if (gender !== undefined) updates.gender = gender;
    if (behaviors !== undefined) updates.behaviors = behaviors;
    if (careInfo !== undefined) updates.careInfo = careInfo;
    if (vetClinicName !== undefined) updates.vetClinicName = vetClinicName;
    if (vetClinicPhone !== undefined) updates.vetClinicPhone = vetClinicPhone;

    const pet = await Animal.findOneAndUpdate(
      { _id: petId, owner: req.userId }, // 🔴 IMPORTANT: owner zeda, mch ghir _id
      updates,
      { new: true, runValidators: true }
    );

    if (!pet) {
      return res.status(404).json({ message: 'Pet not found' });
    }

    res.status(200).json({ message: 'Pet updated successfully', pet });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};