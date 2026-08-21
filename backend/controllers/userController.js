// controllers/userController.js
const User = require('../models/user');
const Sitter = require('../models/sitter');

// ============================================================================
// GET PROFILE (route "protégée" - te7taj token JWT)
// ============================================================================
// 🔵 ZID: hedhi elli el Flutter SplashDecider lezemha te3yet biha ki
// el app tebda (w el user 3andou session mahfoudha) - traja3 el data
// el kaملha tel user el connecté (mel token, MCH mel query/params -
// nafs el mant9 amni tel updateProfile: ay wa7ed ynajjam yeb3ath
// token sa7i7 bess, mch ID ykhtarou).
// ============================================================================
exports.getProfile = async (req, res) => {
  try {
    const baseUser = await User.findById(req.userId);

    if (!baseUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    const responseUser = {
      id: baseUser._id,
      email: baseUser.email,
      fullName: baseUser.fullName,
      phone: baseUser.phone,
      city: baseUser.city,
      location: baseUser.location,
      role: baseUser.role,
      photoUrl: baseUser.photoUrl,
      birthday: baseUser.birthday,
      bio: baseUser.bio,
    };

    // 🔴 FIX: el 7ou9oul el 5assa bel sitter (services/residenceType/...)
    // MAWJOUDIN GHIR fel schema tel discriminator "Sitter" - "User.
    // findById" (el schema el asli) ma yerja3homch (Mongoose ynasso7hom
    // automatique, nafs mochkla updateSitterDetails elli sawwabnaha
    // 9bal). Fa ki role=='sitter', n3awdou njibou el document b "Sitter"
    // (el schema el kamel, bihom).
    if (baseUser.role === 'sitter') {
      const sitterUser = await Sitter.findById(req.userId);
      console.log(`🔵 [GET-PROFILE] sitter services mel base: ${JSON.stringify(sitterUser.services)}`);
      responseUser.services = sitterUser.services;
      responseUser.residenceType = sitterUser.residenceType;
      responseUser.hasTransportation = sitterUser.hasTransportation;
      responseUser.hasPetAtHome = sitterUser.hasPetAtHome;
      responseUser.ownedPetTypes = sitterUser.ownedPetTypes;
    }

    res.status(200).json({ user: responseUser });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

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
  console.log(`\n🟠 [UPDATE-PROFILE] Bda - ${new Date().toISOString()}`);
  console.log(`🟠 [UPDATE-PROFILE] userId: ${req.userId}`);
  console.log(`🟠 [UPDATE-PROFILE] Body mawsoul: ${JSON.stringify(req.body)}`);
  try {
    const { fullName, phone, city, location, birthday, bio } = req.body;

    const updates = {};
    if (fullName !== undefined) updates.fullName = fullName;
    if (phone !== undefined) updates.phone = phone;
    if (city !== undefined) updates.city = city;
    if (location !== undefined) updates.location = location;
    if (birthday !== undefined) updates.birthday = birthday;
    if (bio !== undefined) updates.bio = bio;

    console.log(`🟠 [UPDATE-PROFILE] updates elli bch ndouzou: ${JSON.stringify(updates)}`);

    const user = await User.findByIdAndUpdate(
      req.userId, // 🔵 mel token, MCH mel body
      updates,
      { new: true, runValidators: true }
    );

    if (!user) {
      console.log('🔴 [UPDATE-PROFILE] user NULL\n');
      return res.status(404).json({ message: 'User not found' });
    }

    console.log(`✅ [UPDATE-PROFILE] khlas - user.bio ba3d save: "${user.bio}"\n`);

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
        birthday: user.birthday,
        bio: user.bio,
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// UPDATE SITTER DETAILS (route "protégée" - te7taj token JWT, role sitter)
// ============================================================================
// 🔵 ZID: hedhi elli el 2 écrans Flutter (create_sitter_profile.dart -
// services+prix+pet type, w create_sitter_profile_2.dart - home&transport)
// lezmhom ye3ytou biha. PATCH mch PUT: kol écran yeb3ath GHIR el 7ou9oul
// elli 3andou (mathalan écran 1 yeb3ath "services" bark, écran 2 yeb3ath
// "residenceType/hasTransportation/..." bark) - el 7ou9oul l'okhrin ma
// yetmasso7ouch (partial update).
//
// 🔴 IMPORTANT: nesta3mlou "Sitter.findByIdAndUpdate" (MCH "User") - 7it
// "services/residenceType/..." mawjoudin GHIR fel schema tel discriminator
// "Sitter" (mch fel schema el asli tel "User") - lowkan sta3malna "User",
// Mongoose (strict mode par défaut) kan ynasso7 el 7ou9oul el jdad
// automatique 9bal el sauvegarde (silent - bla erreur, bla data).
// ============================================================================
exports.updateSitterDetails = async (req, res) => {
  console.log(`\n🟢 [SITTER-DETAILS] Bda - ${new Date().toISOString()}`);
  console.log(`🟢 [SITTER-DETAILS] userId (mel token): ${req.userId}`);
  console.log(`🟢 [SITTER-DETAILS] Body mawsoul: ${JSON.stringify(req.body)}`);
  try {
    const { services, residenceType, hasTransportation, hasPetAtHome, ownedPetTypes } = req.body;

    // 🔵 n7ottou GHIR el 7ou9oul elli 7a9i9atan tzadou fel body (mch
    // undefined) - bch PATCH mel écran 1 (services bark) ma ymassa7ch
    // el data mel écran 2 (residenceType...) b "undefined", w l3aks.
    const updates = {};
    if (services !== undefined) updates.services = services;
    if (residenceType !== undefined) updates.residenceType = residenceType;
    if (hasTransportation !== undefined) updates.hasTransportation = hasTransportation;
    if (hasPetAtHome !== undefined) updates.hasPetAtHome = hasPetAtHome;
    if (ownedPetTypes !== undefined) updates.ownedPetTypes = ownedPetTypes;

    console.log(`🟢 [SITTER-DETAILS] updates elli bch ndouzou: ${JSON.stringify(updates)}`);

    const sitter = await Sitter.findByIdAndUpdate(
      req.userId, // 🔵 mel token (protect middleware), MCH mel body
      updates,
      { new: true, runValidators: true }
    );

    if (!sitter) {
      console.log(`🔴 [SITTER-DETAILS] Sitter.findByIdAndUpdate rejja3 NULL (userId ma l9ah/mch sitter) - (${req.userId})\n`);
      return res.status(404).json({ message: 'Sitter not found' });
    }

    console.log(`✅ [SITTER-DETAILS] khlas - sitter.services ba3d save: ${JSON.stringify(sitter.services)}\n`);

    res.status(200).json({
      message: 'Sitter details updated successfully',
      sitter: {
        id: sitter._id,
        services: sitter.services,
        residenceType: sitter.residenceType,
        hasTransportation: sitter.hasTransportation,
        hasPetAtHome: sitter.hasPetAtHome,
        ownedPetTypes: sitter.ownedPetTypes,
      },
    });
  } catch (error) {
    console.log(`🔴 [SITTER-DETAILS] EXCEPTION: ${error.message}\n`);
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