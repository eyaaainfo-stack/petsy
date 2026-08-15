// controllers/userController.js
const User = require('../models/user');

// ============================================================================
// UPDATE PROFILE (route "protégée" - te7taj token JWT)
// ============================================================================
// 🔵 hedhi elli el Flutter UserCreateProfileController lezmha te3yet
// biha (bdal el mock) - t7ott el fullName/phone/city/location (elli
// el user 3amar fel UserCreateProfileScreen).
//
// 🔴 IMPORTANT: "req.userId" ma yjich mel body (kan ay wa7ed ynajjam
// yeb3ath ID mch tou3ou w ybeddel data 7ad okhor!) - yji mel token
// (middleware "protect", chrahtha fel middleware/auth.js) - hedha el
// fikra kaملha tel authentification.
// ============================================================================
exports.updateProfile = async (req, res) => {
  try {
    const { fullName, phone, city, location } = req.body;

    const user = await User.findByIdAndUpdate(
      req.userId, // 🔵 mel token, MCH mel body
      { fullName, phone, city, location },
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({
      message: 'Profile updated successfully',
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        phone: user.phone,
        city: user.city,
        location: user.location,
        role: user.role,
        photoUrl: user.photoUrl,
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET SITTERS BY CITY
// ============================================================================
// 🔵 hedhi elli profile_owner.dart lezemha te3yet biha (bdal el list
// fadhya el hardcodée) - traja3 el sitters (role: 'sitter') elli fi
// NEFS el city elli tab3ath fel query (?city=Sfax).
// ============================================================================
exports.getSittersByCity = async (req, res) => {
  try {
    const { city } = req.query;

    if (!city) {
      return res.status(400).json({ message: 'city query param is required' });
    }

    const sitters = await User.find({ role: 'sitter', city }).select(
      'fullName city photoUrl' // 🔵 7ou9oul amnin bess (mch email/password)
    );

    res.status(200).json({ sitters });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// UPLOAD PHOTO (khass bel user - Admin/Owner/Sitter/Courier, kolhom
// nafs el collection "users" b fadhl el discriminator pattern)
// ============================================================================
// 🔵 nafs mant9 petController.uploadPetPhoto, houni khass bel User
// bdal el Animal - el "upload" middleware (multer, mawjoud déjà w
// chtarek) yehdi el image w y7otha fel "req.file" 9bal ma tousel houni.
// ============================================================================
exports.uploadUserPhoto = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: 'No photo uploaded' });
    }

    const { userId } = req.params;

    // el URL elli el front ynajjam ye3mel biha 3rd el image (chrahtha
    // fel server.js: app.use('/uploads', express.static(...)))
    const photoUrl = `/uploads/users/${req.file.filename}`;

    const user = await User.findByIdAndUpdate(
      userId,
      { photoUrl },
      { new: true } // yrajja3 el document el jdid (ba3d el update)
    );

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({
      message: 'Photo uploaded successfully',
      // 🔵 nafs el mant9 tel login/register: nrajj3ou 7ou9oul amnin
      // bess (mch el user el kol, mch el password 7ata lowkan mhashi)
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        phone: user.phone,
        role: user.role,
        photoUrl: user.photoUrl,
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};