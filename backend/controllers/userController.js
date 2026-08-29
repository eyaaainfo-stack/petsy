// controllers/userController.js
const User = require('../models/user');
const Sitter = require('../models/sitter');
const CheckoutQuestionnaire = require('../models/checkoutQuestionnaire');

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
      gender: baseUser.gender,
      locationName: baseUser.locationName,
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
      // 🔵 ZID (kifma tlab): "disponibilité" - bch sitter_calender.dart
      // ynajjam yjib el état el 7ali (ki yefte7 mode "Availability").
      responseUser.recurringDaysOff = sitterUser.recurringDaysOff;
      responseUser.specificDatesOff = sitterUser.specificDatesOff;
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
    const { fullName, phone, city, location, birthday, bio, gender, locationName } = req.body;

    // 🔵 ZID (kifma tlab): "el esm ykoun unique kima el insta" - nchekkou
    // 9bal el update (case-insensitive, mistathnayin el user el 7ali
    // rou7ou - bch ma yban-ch "esmou meakhoud" ken 3awd b3ath NAFS
    // esmou mel update_profile_owner.dart/update_profile_sitter.dart).
    if (fullName !== undefined && fullName.trim()) {
      const escaped = fullName.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const conflict = await User.findOne({
        _id: { $ne: req.userId },
        fullName: { $regex: `^${escaped}$`, $options: 'i' },
      }).select('_id');
      if (conflict) {
        return res.status(400).json({ message: 'Name already taken' });
      }
    }

    const updates = {};
    if (fullName !== undefined) updates.fullName = fullName;
    if (phone !== undefined) updates.phone = phone;
    if (city !== undefined) updates.city = city;
    if (location !== undefined) updates.location = location;
    if (birthday !== undefined) updates.birthday = birthday;
    if (bio !== undefined) updates.bio = bio;
    if (gender !== undefined) updates.gender = gender;
    if (locationName !== undefined) updates.locationName = locationName;

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
        gender: user.gender,
        locationName: user.locationName,
      },
    });
  } catch (error) {
    // 🔵 filet de sécurité: race condition (zouj requests "fi nefs
    // el lehdha" b'nefs el esm, el chek fou9 el 2 3adethom "khaliya")
    // - MongoDB nafsou yerfudh (unique index) w yرمي E11000.
    if (error.code === 11000 && error.keyPattern?.fullName) {
      return res.status(400).json({ message: 'Name already taken' });
    }
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
    const { services, residenceType, hasTransportation, hasPetAtHome, ownedPetTypes, recurringDaysOff, specificDatesOff } = req.body;

    // 🔵 n7ottou GHIR el 7ou9oul elli 7a9i9atan tzadou fel body (mch
    // undefined) - bch PATCH mel écran 1 (services bark) ma ymassa7ch
    // el data mel écran 2 (residenceType...) b "undefined", w l3aks.
    const updates = {};
    if (services !== undefined) updates.services = services;
    if (residenceType !== undefined) updates.residenceType = residenceType;
    if (hasTransportation !== undefined) updates.hasTransportation = hasTransportation;
    if (hasPetAtHome !== undefined) updates.hasPetAtHome = hasPetAtHome;
    if (ownedPetTypes !== undefined) updates.ownedPetTypes = ownedPetTypes;
    // 🔵 ZID (kifma tlab): "disponibilité" (signup w sitter_calender.dart)
    if (recurringDaysOff !== undefined) updates.recurringDaysOff = recurringDaysOff;
    if (specificDatesOff !== undefined) updates.specificDatesOff = specificDatesOff.map((d) => new Date(d));

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
        recurringDaysOff: sitter.recurringDaysOff,
        specificDatesOff: sitter.specificDatesOff,
      },
    });
  } catch (error) {
    console.log(`🔴 [SITTER-DETAILS] EXCEPTION: ${error.message}\n`);
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET SITTER PUBLIC PROFILE (view_profile_sitter.dart)
// ============================================================================
// 🔵 ZID: ki el owner ydouss 3al card tel sitter (Available for urgent
// sitting), ye7taj ychouf profile tou3ou (photo/bio/residence/services+
// prix). Route MNFASSLA 3an "getProfile" (elli terja3 GHIR profile
// el user el CONNECTÉ mel token) - houni njibou profile SITTER 7AD
// OKHOR (mel :sitterId fel URL), bark el 7ou9oul el amnin (bla email).
// ============================================================================
exports.getSitterPublicProfile = async (req, res) => {
  try {
    const { sitterId } = req.params;

    const sitter = await Sitter.findOne({ _id: sitterId, role: 'sitter' });
    if (!sitter) {
      return res.status(404).json({ message: 'Sitter not found' });
    }

    // 🔴 FIX (kifma tlab: "el rating ma waletach todhhor fel profile") -
    // el moyenne 7a9i9iya (averageRating mel questionnaires "completed")
    // - MECH "0" statique.
    const ratingAgg = await CheckoutQuestionnaire.aggregate([
      { $match: { reviewee: sitter._id, averageRating: { $ne: null } } },
      { $group: { _id: null, avg: { $avg: '$averageRating' }, count: { $sum: 1 } } },
    ]);
    const averageRating = ratingAgg.length > 0 ? Math.round(ratingAgg[0].avg * 10) / 10 : null;
    const reviewsCount = ratingAgg.length > 0 ? ratingAgg[0].count : 0;

    res.status(200).json({
      user: {
        fullName: sitter.fullName,
        city: sitter.city,
        photoUrl: sitter.photoUrl,
        bio: sitter.bio,
        role: sitter.role,
        residenceType: sitter.residenceType,
        hasTransportation: sitter.hasTransportation,
        hasPetAtHome: sitter.hasPetAtHome,
        ownedPetTypes: sitter.ownedPetTypes,
        services: sitter.services,
        averageRating,
        reviewsCount,
        // 🔵 ZID (kifma tlab): "el owner ma yenajjamch ye5tar youm el
        // sitter mch dispo fih" - lezmou el owner ychouf had data 9bal
        // ma yekhtar date (request_a_book.dart).
        recurringDaysOff: sitter.recurringDaysOff,
        specificDatesOff: sitter.specificDatesOff,
      },
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
// 🔵 hedhi elli profile_owner.dart lezemha te3yet biha (bdal el list
// fadhya el hardcodée) - traja3 el sitters (role: 'sitter') elli fi
// NEFS el city elli tab3ath fel query (?city=Sfax).
// ============================================================================
// 🔴 FIX (kanou na9sin): "location" ma kanetch fel .select() (fa el
// distance kanet dima 0, mahroudh fel front) - w el route tawa
// PROTÉGÉE (protect middleware, chrahtha fel route) bch nnajjmou
// nchekkou "req.userId" (el owner el connecté) w njibou el location
// tou3ou mel base, bch ne7sbou el distance el 7a9i9iya bin el zoùj.
exports.getSittersByCity = async (req, res) => {
  try {
    const { city } = req.query;

    if (!city) {
      return res.status(400).json({ message: 'city query param is required' });
    }

    // 🔵 el owner el connecté (mel token) - bch njibou el location
    // tou3ou w ne7sbou el distance, W el favorites tou3ou (bch nchekkou
    // "isFavorite" lel kol sitter).
    const owner = await User.findById(req.userId).select('location favorites');
    const ownerLat = owner?.location?.lat;
    const ownerLng = owner?.location?.lng;
    const favoriteIds = new Set((owner?.favorites || []).map((id) => id.toString()));

    const sitters = await User.find({ role: 'sitter', city }).select(
      'fullName city photoUrl location' // 🔴 FIX: "location" kanet na9sa
    );

    // 🔴 FIX (kifma tlab: "nbr des etoiles ma tbadelch fel cards
    // lokhrin") - rating 7a9i9i (averageRating mel questionnaires
    // "completed") - wa7da aggregation lel sitters el kol (mch N+1 query).
    const sitterIds = sitters.map((s) => s._id);
    const ratingAgg = await CheckoutQuestionnaire.aggregate([
      { $match: { reviewee: { $in: sitterIds }, averageRating: { $ne: null } } },
      { $group: { _id: '$reviewee', avg: { $avg: '$averageRating' }, count: { $sum: 1 } } },
    ]);
    const ratingMap = new Map(ratingAgg.map((r) => [r._id.toString(), { avg: Math.round(r.avg * 10) / 10, count: r.count }]));

    const sittersWithDistance = sitters.map((sitter) => {
      let distanceKm = null;
      const sitterLat = sitter.location?.lat;
      const sitterLng = sitter.location?.lng;

      if (ownerLat != null && ownerLng != null && sitterLat != null && sitterLng != null) {
        distanceKm = haversineDistanceKm(ownerLat, ownerLng, sitterLat, sitterLng);
      }

      const ratingInfo = ratingMap.get(sitter._id.toString());

      return {
        _id: sitter._id,
        fullName: sitter.fullName,
        city: sitter.city,
        photoUrl: sitter.photoUrl,
        distanceKm,
        // 🔵 ZID (kifma tlab): "My Favourites" - el card twarri el
        // heart mel bidaya sa7i7 (mfilé lowkan déjà favori).
        isFavorite: favoriteIds.has(sitter._id.toString()),
        rating: ratingInfo?.avg ?? 0,
        reviewsCount: ratingInfo?.count ?? 0,
      };
    });

    res.status(200).json({ sitters: sittersWithDistance });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 🔵 ZID: formule Haversine (standard lel distance "à vol d'oiseau"
// bin 2 coordonnées GPS) - terja3 el distance bel KM, rounded l 1
// chiffre ba3d el fasla.
function haversineDistanceKm(lat1, lng1, lat2, lng2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const R = 6371; // rayon el ardh bel km
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c * 10) / 10;
}

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

// ============================================================================
// TOGGLE FAVORITE (heart icon 3al card tel sitter, "My Favourites")
// ============================================================================
exports.toggleFavorite = async (req, res) => {
  try {
    const { sitterId } = req.params;
    const user = await User.findById(req.userId);
    if (!user) return res.status(404).json({ message: 'User not found' });

    const index = user.favorites.findIndex((id) => id.toString() === sitterId);
    let isFavorite;
    if (index === -1) {
      user.favorites.push(sitterId);
      isFavorite = true;
    } else {
      user.favorites.splice(index, 1);
      isFavorite = false;
    }
    await user.save({ validateBeforeSave: false });

    res.status(200).json({ isFavorite });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET MY FAVORITES ("My Favourites" screen, owner)
// ============================================================================
// 🔵 nafs mant9 getSittersByCity (distance mel Haversine, chrahtha
// fou9 fel fichier hedha) - zid "startingPrice" (a5f prix mel services
// tel sitter, "à partir de").
// ============================================================================
exports.getMyFavorites = async (req, res) => {
  try {
    const owner = await User.findById(req.userId).select('location favorites');
    if (!owner) return res.status(404).json({ message: 'User not found' });

    const ownerLat = owner.location?.lat;
    const ownerLng = owner.location?.lng;

    const sitters = await Sitter.find({ _id: { $in: owner.favorites } }).select(
      'fullName city photoUrl location services'
    );

    const favoritesWithDetails = sitters.map((sitter) => {
      let distanceKm = null;
      const sitterLat = sitter.location?.lat;
      const sitterLng = sitter.location?.lng;
      if (ownerLat != null && ownerLng != null && sitterLat != null && sitterLng != null) {
        distanceKm = haversineDistanceKm(ownerLat, ownerLng, sitterLat, sitterLng);
      }

      const prices = (sitter.services || []).map((s) => s.price);
      const startingPrice = prices.length > 0 ? Math.min(...prices) : null;

      return {
        _id: sitter._id,
        fullName: sitter.fullName,
        city: sitter.city,
        photoUrl: sitter.photoUrl,
        distanceKm,
        startingPrice,
      };
    });

    res.status(200).json({ favorites: favoritesWithDetails });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// CHECK NAME AVAILABILITY (kifma tlab: "Instagram-style" live check -
// user_create_profile.dart, w update_profile_owner.dart/update_profile_
// sitter.dart zeda, ki el user yekteb esmou).
// ============================================================================
// 🔵 route protégée (token) - bch nnajmou nesta7nou el user el 7ali
// rou7ou mel conflict (ken 3awd yeb3ath NAFS esmou, mch ye7seb "meakhoud").
// ============================================================================
exports.checkNameAvailability = async (req, res) => {
  try {
    const { name } = req.query;
    if (!name || !name.trim()) {
      return res.status(400).json({ message: 'name query param is required' });
    }

    const escaped = name.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const [conflict, requestingUser] = await Promise.all([
      User.findOne({
        _id: { $ne: req.userId },
        fullName: { $regex: `^${escaped}$`, $options: 'i' },
      }).select('_id fullName'),
      User.findById(req.userId).select('email fullName'),
    ]);

    // 🔵 ZID (debug): "check-name yrajja3 available=true ken el esm
    // déjà mawjoud" - bch nchoufou b'a3yonna CHKOUN el "moi" (mel
    // token - email/fullName tou3ou el 7ali) w el conflict (lowkan
    // mal9ihech, chnowa el esm elli el DB fih el 9rib). Lowkan
    // "requestingUser.email" howa NAFS el compte el 9dim (firas) -
    // mch compte jdid - el session mazelt "khaltat" bel compte l9dim.
    console.log(`🔍 [CHECK-NAME] req.userId="${req.userId}" (email="${requestingUser?.email}", fullName_7ali="${requestingUser?.fullName}") name_mchouwef="${name}" conflict=${conflict ? `FOUND(_id=${conflict._id}, fullName="${conflict.fullName}")` : 'NONE'}`);

    res.status(200).json({ available: !conflict });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// SEARCH SITTERS (search.dart - owner side)
// ============================================================================
// 🔵 ZID (kifma tlab): "kif nekteb fi esm el sitter yjiwni deja les
// propositions" (autocomplete, "q") + filtres: gender/city/residenceType
// (win yoskon)/maxDistanceKm/minMemberMonths ("kadeh 3ndou fel app",
// mel createdAt). NAFS endpoint yesta3malou el zoùj (autocomplete
// LIVE bark "q", wela m3a el filtres el kol) - result triés el a9rab
// (distance) awalan.
//
// 🔴 "rating/stars": MECH mawjoud houni b'9asd - mafamech système
// reviews 7a9i9i mrakez fel backend l'hin (chrahtha view_profile_
// sitter.dart, "Reviews (0)" dima) - lowkan el front yeb3ath "minRating"
// nzidouha wa9tha, lakin tawa ma3andhach me3na (kol sitter "0").
// ============================================================================
exports.searchSitters = async (req, res) => {
  try {
    const { q, gender, city, residenceType, maxDistanceKm, minMemberMonths } = req.query;

    const owner = await User.findById(req.userId).select('location favorites');
    const ownerLat = owner?.location?.lat;
    const ownerLng = owner?.location?.lng;
    const favoriteIds = new Set((owner?.favorites || []).map((id) => id.toString()));

    const filter = { role: 'sitter' };

    if (q && q.trim()) {
      const escaped = q.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      filter.fullName = { $regex: escaped, $options: 'i' };
    }
    if (gender) filter.gender = gender;
    if (city) filter.city = city;
    if (residenceType) filter.residenceType = residenceType;

    // 🔵 "kadeh 3ndou fel app" - sitters elli sجلو (createdAt) 9bal
    // "cutoff" (mathalan minMemberMonths=6 -> mawjoudin fel app men
    // 6 chhour 3ala 9al ma).
    if (minMemberMonths) {
      const months = Number(minMemberMonths);
      if (!Number.isNaN(months) && months > 0) {
        const cutoff = new Date();
        cutoff.setMonth(cutoff.getMonth() - months);
        filter.createdAt = { $lte: cutoff };
      }
    }

    const sitters = await User.find(filter)
      .select('fullName city photoUrl location gender residenceType createdAt')
      .limit(30);

    let results = sitters.map((sitter) => {
      let distanceKm = null;
      const sitterLat = sitter.location?.lat;
      const sitterLng = sitter.location?.lng;
      if (ownerLat != null && ownerLng != null && sitterLat != null && sitterLng != null) {
        distanceKm = haversineDistanceKm(ownerLat, ownerLng, sitterLat, sitterLng);
      }

      return {
        _id: sitter._id,
        fullName: sitter.fullName,
        city: sitter.city,
        photoUrl: sitter.photoUrl,
        gender: sitter.gender,
        residenceType: sitter.residenceType,
        memberSince: sitter.createdAt,
        distanceKm,
        isFavorite: favoriteIds.has(sitter._id.toString()),
      };
    });

    if (maxDistanceKm) {
      const maxKm = Number(maxDistanceKm);
      if (!Number.isNaN(maxKm) && maxKm > 0) {
        results = results.filter((s) => s.distanceKm == null || s.distanceKm <= maxKm);
      }
    }

    // el a9rab (distance) awalan - sitters bla location (distance null) fel lekher
    results.sort((a, b) => {
      if (a.distanceKm == null && b.distanceKm == null) return 0;
      if (a.distanceKm == null) return 1;
      if (b.distanceKm == null) return -1;
      return a.distanceKm - b.distanceKm;
    });

    res.status(200).json({ sitters: results });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET USER REVIEWS (view_profile_sitter.dart w wla profile_owner - VRAI
// reviews, kifma tlab: "el avis ywalli VRAI review yban 3al profile")
// ============================================================================
// 🔵 ZID: "review" houni mch rating 1-5 - "satisfied" (boolean, mel
// questionnaire ba3d el checkout) + "review" (text). Nrajj3ou el liste
// + 3adad "satisfied" bch el front ynajjam ye7seb "X% satisfaction"
// (mch star average fake).
// ============================================================================
exports.getUserReviews = async (req, res) => {
  try {
    const reviews = await CheckoutQuestionnaire.find({ reviewee: req.params.userId, averageRating: { $ne: null } })
      .sort({ createdAt: -1 })
      .populate('respondent', 'fullName photoUrl')
      .limit(50);

    const totalAverage = reviews.length > 0 ? Math.round((reviews.reduce((sum, r) => sum + r.averageRating, 0) / reviews.length) * 10) / 10 : null;

    res.status(200).json({
      reviews: reviews.map((r) => ({
        id: r._id,
        reviewerName: r.respondent?.fullName || '',
        reviewerPhotoUrl: r.respondent?.photoUrl || null,
        satisfied: r.satisfied,
        ratingTrust: r.ratingTrust,
        ratingService: r.ratingService,
        ratingCommunication: r.ratingCommunication,
        ratingKnowledge: r.ratingKnowledge,
        averageRating: r.averageRating,
        review: r.review,
        createdAt: r.createdAt,
      })),
      totalAverage,
      totalCount: reviews.length,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};