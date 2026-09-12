const mongoose = require('mongoose');
const Booking = require('../models/booking');
const Notification = require('../models/notification');
const User = require('../models/user');
const Sitter = require('../models/sitter');
const Animal = require('../models/animal');

// ============================================================================
// FEATURE "COMPATIBILITE ENTRE ANIMAUX" (safety scheduling)
// ============================================================================
// Regle (kifma tlab): 3 categories - 'small_dog' / 'guard_dog' / 'cat'.
// - Kol pets fi NEFS el booking lezem ykounou nefs el category (bla
//   mzij small_dog + guard_dog fi nefs el talab).
// - NAFS el sitter ma ynajjamch ykoun 3andou, fi NEFS el creneau
//   (checkIn/checkOut mتداخلين), 2 categories mختلفة b'nefs el wa9t.
// - Max MAX_PETS_PER_SLOT (5) pets (nefs el category) 3and NAFS el
//   sitter fi nefs el creneau.
// Hedhi el logique metmarkza houni bch tetsta3mel mel 3 blayes elli
// booking ynajjam "yetakadd" fihom (createBooking, respondToBooking,
// confirmCandidate) - defense en profondeur, nafs l'approche mta3 el
// verification tel dates (checkOutDate > checkInDate).
// ============================================================================
const MAX_PETS_PER_SLOT = 5;
const ACTIVE_BOOKING_STATUSES = ['pending', 'accepted', 'awaiting_confirmation'];

// 🔵 el pets el kol fi booking lezem ykounou nefs el category. Terja3
// el category (string) ken kol chay sa77i7, wala "null" ken famma mzij
// (caller ye5tar chnowa ye3mel - 9bal wla n7esbouha "pas de conflit").
function getSingleCategory(petsWithCategory) {
  const categories = new Set((petsWithCategory || []).map((p) => p.category).filter(Boolean));
  if (categories.size !== 1) return null;
  return [...categories][0];
}

// 🔵 yjib el Animal docs (category bark) mel IDs, w yرجع el category
// el mchtarka + l'3adad - wala "error" ken el pets ma jeach lqahom,
// wala ken el category mch nefsha 3al kol el pets fel booking.
async function resolveBookingPetsCategory(petIds) {
  const pets = await Animal.find({ _id: { $in: petIds } }).select('category');
  if (pets.length !== petIds.length) {
    return { error: 'One or more pets were not found' };
  }
  const category = getSingleCategory(pets);
  if (!category) {
    return { error: 'All pets in a single booking must belong to the same category' };
  }
  return { category, count: pets.length };
}

// 🔵 el fonction "el mou7imma": tchekk ken had el sitter, fi had el
// creneau, ynajjam ye5ou booking jdid b had el category/3adad. Terja3
// { ok: true } wala { ok: false, reason, ... } (reason: 'category_
// mismatch' wala 'capacity_full').
async function checkCategoryCapacityConflict({ sitterId, checkIn, checkOut, category, newPetCount, excludeBookingId }) {
  // 🔵 fail-open: ken el category mahich m3aroufa (null/undefined -
  // data legacy/incohérente), ma nbلokiw walou - a7san ma nziidouch
  // erreurs ghreeba 3al data el 9dima.
  if (!category) return { ok: true };

  const overlapFilter = {
    sitter: sitterId,
    status: { $in: ACTIVE_BOOKING_STATUSES },
    checkIn: { $lt: checkOut },
    checkOut: { $gt: checkIn },
  };
  if (excludeBookingId) {
    overlapFilter._id = { $ne: excludeBookingId };
  }

  const overlapping = await Booking.find(overlapFilter).populate('pets', 'category');

  let existingCount = 0;
  const otherCategories = new Set();
  for (const b of overlapping) {
    for (const pet of b.pets) {
      if (!pet?.category) continue;
      if (pet.category === category) existingCount += 1;
      else otherCategories.add(pet.category);
    }
  }

  if (otherCategories.size > 0) {
    return { ok: false, reason: 'category_mismatch', conflictingCategories: [...otherCategories] };
  }
  if (existingCount + newPetCount > MAX_PETS_PER_SLOT) {
    return { ok: false, reason: 'capacity_full', existingCount, max: MAX_PETS_PER_SLOT };
  }
  return { ok: true, existingCount };
}

function buildConflictMessage(conflict) {
  if (conflict.reason === 'category_mismatch') {
    return 'This sitter already has a booking with a different pet category during this time slot.';
  }
  if (conflict.reason === 'capacity_full') {
    return `This sitter already has ${conflict.existingCount}/${MAX_PETS_PER_SLOT} pets booked for this time slot.`;
  }
  return 'This time slot is not available for this sitter.';
}

// 🔵 el sitter "off" (recurringDaysOff/specificDatesOff, sitter_calender.dart)
// 3al youm tel date mo3ayana - nafs convention DateTime.weekday
// (1=Mon...7=Sun) elli chraht fel models/sitter.js.
function isSitterOffOnDate(sitterDoc, date) {
  const weekday = date.getDay() === 0 ? 7 : date.getDay();
  if ((sitterDoc.recurringDaysOff || []).includes(weekday)) return true;
  const dateStr = date.toISOString().slice(0, 10);
  return (sitterDoc.specificDatesOff || []).some((d) => new Date(d).toISOString().slice(0, 10) === dateStr);
}

// 🔵 ZID: nafs el formule Haversine (userController.js) - mkarrra houni
// bch bookingController.js ma yeh tajch "require" cross-controller
// (nafs convention el fichier - maps zgheer mkarrarin déjà, mathalan
// _serviceLabelKeys fel plusieurs écrans Flutter).
function haversineDistanceKm(lat1, lng1, lat2, lng2) {
  const toRad = (deg) => (deg * Math.PI) / 180;
  const R = 6371;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return Math.round(R * c * 10) / 10;
}

// ============================================================================
// GET MY NOTIFICATIONS (bch testa3milha écran "Notifications" - mazel
// ma tsawwabch l'hin, TODO lel mostaqbal, lakin el backend jahez).
// ============================================================================
exports.getMyNotifications = async (req, res) => {
  try {
    const notifications = await Notification.find({ recipient: req.userId }).sort({ createdAt: -1 });
    res.status(200).json({ notifications });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET UNREAD NOTIFICATIONS COUNT (bell icon badge - profile_owner.dart/
// sitter_profile.dart)
// ============================================================================
exports.getUnreadNotificationsCount = async (req, res) => {
  try {
    const count = await Notification.countDocuments({ recipient: req.userId, isRead: false });
    res.status(200).json({ count });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// DISMISS NOTIFICATION (bouton "No" - "booking_rejected"/"candidate_accepted":
// ma nbeddlouch 7ata 7aja fel booking, ghir el notification ma tban-ch
// mrra thenya b'el bottons).
// ============================================================================
exports.dismissNotification = async (req, res) => {
  try {
    const notification = await Notification.findOne({ _id: req.params.id, recipient: req.userId });
    if (!notification) return res.status(404).json({ message: 'Notification not found' });

    notification.isActioned = true;
    notification.isRead = true;
    await notification.save();

    res.status(200).json({ message: 'Notification dismissed' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// MARK ALL NOTIFICATIONS AS READ (ki el user yefte7 écran "Notifications")
// ============================================================================
exports.markAllNotificationsRead = async (req, res) => {
  try {
    await Notification.updateMany({ recipient: req.userId, isRead: false }, { isRead: true });
    res.status(200).json({ message: 'Notifications marked as read' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET MY BOOKINGS (owner side) - les_reservations.dart
// ============================================================================
// 🔵 ZID: el owner ye7eb ychouf el bookings tou3ou el kol (pending/
// accepted/rejected) - m3a esm+photo tel sitter, w esm+photo tel pets,
// bch el front ma yeb9ach ye3mel appels mnfaslin lel kol booking.
// Tertib: checkIn DESC (el a9rab/el jday awalan - nafs tertib el
// mockup: 5-10 July -> 22-25 May -> 9 March -> 1 March).
// ============================================================================
exports.getMyBookings = async (req, res) => {
  try {
    const owner = await User.findById(req.userId).select('location');
    const ownerLat = owner?.location?.lat;
    const ownerLng = owner?.location?.lng;

    const bookings = await Booking.find({ owner: req.userId })
      .sort({ checkIn: -1 })
      .populate('sitter', 'fullName photoUrl city phone location')
      .populate('pendingCandidateSitter', 'fullName photoUrl city phone location')
      .populate('pets', 'name photoUrl');

    // 🔵 ZID (kifma tlab): "kadeh famma distance binethom" - nafs mant9
    // getBookingById (candidate lowkan awaiting_confirmation, wela el
    // sitter el mfassal).
    const bookingsWithDistance = bookings.map((b) => {
      const effectiveSitter = b.pendingCandidateSitter || b.sitter;
      const sitterLat = effectiveSitter?.location?.lat;
      const sitterLng = effectiveSitter?.location?.lng;

      let distanceKm = null;
      if (ownerLat != null && ownerLng != null && sitterLat != null && sitterLng != null) {
        distanceKm = haversineDistanceKm(ownerLat, ownerLng, sitterLat, sitterLng);
      }

      const obj = b.toObject();
      obj.distanceKm = distanceKm;
      return obj;
    });

    res.status(200).json({ bookings: bookingsWithDistance });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// CREATE BOOKING (request_a_book.dart -> "Send Request")
// ============================================================================
// 🔵 ZID: el owner (mel token, req.userId) yebaath talab l'sitter mo3ayan
// (sitterId fel body) - ye5le9 Booking, w NOTIFICATIONS l'ZOUJ (sitter +
// owner), kifma tlab.
// ============================================================================
exports.createBooking = async (req, res) => {
  try {
    const { sitterId, petIds, services, checkIn, checkOut, total } = req.body;

    if (!sitterId || !petIds || !petIds.length || !services || !services.length || !checkIn || !checkOut) {
      return res.status(400).json({ message: 'Missing required booking fields' });
    }

    // 🔴 IMPORTANT: nchekkou el zoùj dates 7a9i9atan (mch nathi9 el
    // front bark - security/data integrity, defense en profondeur).
    const checkInDate = new Date(checkIn);
    const checkOutDate = new Date(checkOut);
    if (checkOutDate <= checkInDate) {
      return res.status(400).json({ message: 'Check-out must be after check-in' });
    }
    const oneHourFromNow = new Date(Date.now() + 60 * 60 * 1000);
    if (checkInDate < oneHourFromNow) {
      return res.status(400).json({ message: 'Check-in must be at least 1 hour from now' });
    }

    // 🔵 ZID (feature "compatibilite entre animaux"): 9bal ma nzidou el
    // booking, nchekkou el category (kol pets fel talab lezem ykounou
    // nefs el category) w el conflit m3a bookings okhrin el sitter fi
    // nefs el creneau.
    const petsCheck = await resolveBookingPetsCategory(petIds);
    if (petsCheck.error) {
      return res.status(400).json({ message: petsCheck.error });
    }

    const conflict = await checkCategoryCapacityConflict({
      sitterId,
      checkIn: checkInDate,
      checkOut: checkOutDate,
      category: petsCheck.category,
      newPetCount: petsCheck.count,
    });
    if (!conflict.ok) {
      return res.status(409).json({ message: buildConflictMessage(conflict), reason: conflict.reason });
    }

    const booking = await Booking.create({
      owner: req.userId,
      sitter: sitterId,
      pets: petIds,
      services,
      checkIn: checkInDate,
      checkOut: checkOutDate,
      total,
    });

    // 🔵 esm el owner (bch el notification tel sitter tban fiha "min")
    const owner = await User.findById(req.userId).select('fullName');
    const sitter = await User.findById(sitterId).select('fullName');

    // notification l'SITTER: "talab jdid wselou"
    await Notification.create({
      recipient: sitterId,
      message: `New booking request from ${owner?.fullName || 'an owner'}!`,
      type: 'booking_received',
      relatedBooking: booking._id,
    });

    // notification l'OWNER: "el talab tب3ath"
    await Notification.create({
      recipient: req.userId,
      message: `Your booking request has been sent to ${sitter?.fullName || 'the sitter'}!`,
      type: 'booking_sent',
      relatedBooking: booking._id,
    });

    res.status(201).json({ message: 'Booking request sent successfully', booking });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET MY SCHEDULE (sitter_calender.dart) - sitter side
// ============================================================================
// 🔵 ZID (kifma tlab): kol el bookings "accepted" (confirmés) tel
// sitter el 7ali - bch el calendrier ywarri noqat (fel jours elli
// 3andhom service) w "Upcoming events" (liste mrattba checkIn ASC).
// ============================================================================
exports.getMySchedule = async (req, res) => {
  try {
    const bookings = await Booking.find({ sitter: req.userId, status: 'accepted' })
      .sort({ checkIn: 1 })
      .populate('pets', 'name photoUrl gender');

    res.status(200).json({ bookings });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET URGENT BOOKINGS FOR SITTER (sitter_profile.dart - "Need urgent
// sitting services")
// ============================================================================
// 🔵 ZID (kifma tlab): bookings "open" (broadcast, ba3d ma sitter okhor
// rafedh w el owner 9bel el rebroadcast) - LI TETMATCHI m3a hedha el
// sitter: NAFS el ville (tel owner) + 3andou 3al a9al service wa7ed
// mel talab ("nafs caractéristiques"), w MECH mawjoud fel rejectedBy
// tou3ha (bch ma yban-lhomch NAFS el talab elli déjà rafdou/refusé).
//
// 🔴 IMPORTANT: hedhi route "GET /urgent" - LEZEM te-register 9BAL
// "GET /:id" (fel routes/bookingRoutes.js), wa9tha Express ma ye5ltch
// "urgent" ka ID.
// ============================================================================
exports.getUrgentBookingsForSitter = async (req, res) => {
  try {
    const sitter = await Sitter.findById(req.userId).select('city services location');
    if (!sitter) return res.status(404).json({ message: 'Sitter not found' });

    const mySitterServiceIds = new Set((sitter.services || []).map((s) => s.serviceId));
    const sitterLat = sitter.location?.lat;
    const sitterLng = sitter.location?.lng;

    const bookings = await Booking.find({
      status: 'open',
      // 🔴 FIX (kifma tlab: "sallahli just enou hatta el sitter eli
      // rfadh el talab tjih fel need urgent services") - cast explicite
      // l'ObjectId (mch req.userId, string raw mel JWT decoded) - $ne
      // 3ala array field (rejectedBy) yeحtaj el valeur mratb b'NAFS
      // type el elements bch el exclusion te5dem b'thi9a (mch depend
      // 3al auto-cast implicite tel Mongoose).
      rejectedBy: { $ne: new mongoose.Types.ObjectId(req.userId) },
    })
      .populate('owner', 'fullName city location')
      .populate('pets', 'name photoUrl')
      .sort({ createdAt: -1 })
      .limit(30);

    const filtered = bookings
      .filter((b) => {
        const sameCity = b.owner?.city && b.owner.city === sitter.city;
        const hasMatchingService = (b.services || []).some((s) => mySitterServiceIds.has(s.serviceId));
        return sameCity && hasMatchingService;
      })
      .map((b) => {
        let distanceKm = null;
        const ownerLat = b.owner?.location?.lat;
        const ownerLng = b.owner?.location?.lng;
        if (sitterLat != null && sitterLng != null && ownerLat != null && ownerLng != null) {
          distanceKm = haversineDistanceKm(sitterLat, sitterLng, ownerLat, ownerLng);
        }
        // 🔵 el .toObject() bch nnajjmou nzidou "distanceKm" (mch jozz
        // mel schema) fel object el mrajja3 lel front.
        const obj = b.toObject();
        obj.distanceKm = distanceKm;
        return obj;
      });

    res.status(200).json({ bookings: filtered });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET BOOKING BY ID (request.dart - "Request Details")
// ============================================================================
// 🔵 ZID: authorization mnfassla (mch bess "protect") - ynajjam ychoufha:
// el owner tou3ha, el sitter el mfassal (lowkan mawjoud), el candidate
// elli "mestanni confirmation", WALA ay sitter lowkan status=="open"
// (marketplace - houwa el mant9 elli el sitter yel9a el talab 9bal ma
// ye5tar ya5douh).
// ============================================================================
exports.getBookingById = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id)
      .populate('owner', 'fullName photoUrl city phone location')
      .populate('sitter', 'fullName photoUrl city location')
      .populate('pendingCandidateSitter', 'fullName photoUrl city phone location')
      .populate('pets', 'name photoUrl petType age breed size gender behaviors careInfo vetClinicName vetClinicPhone');

    if (!booking) return res.status(404).json({ message: 'Booking not found' });

    const requester = await User.findById(req.userId).select('role');
    const uid = req.userId.toString();
    const isOwner = booking.owner._id.toString() === uid;
    const isAssignedSitter = booking.sitter && booking.sitter._id.toString() === uid;
    const isCandidate = booking.pendingCandidateSitter && booking.pendingCandidateSitter._id.toString() === uid;
    const isBrowsingOpenMarketplace = booking.status === 'open' && requester?.role === 'sitter';

    if (!isOwner && !isAssignedSitter && !isCandidate && !isBrowsingOpenMarketplace) {
      return res.status(403).json({ message: 'Not authorized to view this booking' });
    }

    // 🔵 ZID (kifma tlab): "kadeh famma distance binethom" - bin el
    // owner w el sitter "effectif" (candidate lowkan awaiting_confirmation,
    // wela el sitter el mfassal, wela el sitter elli 3andou el token
    // lowkan houwa "open" marketplace - mch mawjoud fel booking l'hin).
    const ownerLat = booking.owner?.location?.lat;
    const ownerLng = booking.owner?.location?.lng;
    const effectiveSitter = booking.pendingCandidateSitter || booking.sitter;
    const sitterLat = effectiveSitter?.location?.lat;
    const sitterLng = effectiveSitter?.location?.lng;

    let distanceKm = null;
    if (ownerLat != null && ownerLng != null && sitterLat != null && sitterLng != null) {
      distanceKm = haversineDistanceKm(ownerLat, ownerLng, sitterLat, sitterLng);
    }

    const bookingObj = booking.toObject();
    bookingObj.distanceKm = distanceKm;

    // 🔵 ZID (kifma tlab: "nhb el logo mtaa el categorie... w ki nenzel
    // ala categorie tethalli el service eli khtarou el owner") - el
    // Booking.services (models/booking.js) yeحtafedh GHIR serviceId +
    // price (mch "esm" 7a9i9i) - ken "custom_..." (chraht kaملa fel
    // sitter_service_catalog.dart/isCustomServiceId), el esm el 7a9i9i
    // (customLabel) mo5azzan GHIR fel PROFILE mte3 el sitter (models/
    // sitter.js), mch fel booking nafsou. Njibouh houni (best-effort -
    // null ken el sitter 7ذef/beddel el service custom mel profile
    // tou3ou ba3d el booking, el front ywarri fallback generic) -
    // effectiveSitter mawjoud déjà fou9 (distance haversine).
    if (effectiveSitter) {
      // 🔴 FIX: "services" mch mel base schema (User) - houwa discriminator
      // field (Sitter bark, models/sitter.js) - ".lean()" houni MHIM
      // (ma3neha object khadem bark, bla hydration Mongoose elli
      // ynajjam "yfassa5" el 7ou9oul elli mch mel schema el "base").
      const sitterDoc = await User.findById(effectiveSitter._id).select('services').lean();
      const customLabelById = {};
      if (sitterDoc && Array.isArray(sitterDoc.services)) {
        for (const s of sitterDoc.services) {
          if (s.customLabel) customLabelById[s.serviceId] = s.customLabel;
        }
      }
      bookingObj.services = (bookingObj.services || []).map((s) => ({
        ...s,
        customLabel: customLabelById[s.serviceId] || null,
      }));
    }

    res.status(200).json({ booking: bookingObj });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// RESPOND TO BOOKING (request.dart - Accept/Reject, sitter side)
// ============================================================================
// 🔵 ZID: te5dem fel 2 7alet - "pending" (talab direct l'had sitter -
// accept/reject 3adi) W "open" (marketplace - "accept" y7ott had
// sitter kaندidat, mestanni confirmation el owner; "reject" ghir
// yzid houni fel rejectedBy, bla notification l'owner - el owner
// 3omro ma 5tar had sitter, mafamech me3na y3araf "candidate X ma7ebbech").
// ============================================================================
exports.respondToBooking = async (req, res) => {
  try {
    const { action } = req.body;
    if (!['accept', 'reject'].includes(action)) {
      return res.status(400).json({ message: 'action must be "accept" or "reject"' });
    }

    const booking = await Booking.findById(req.params.id).populate('pets', 'category');
    if (!booking) return res.status(404).json({ message: 'Booking not found' });

    const uid = req.userId.toString();
    const isAssignedSitter = booking.status === 'pending' && booking.sitter && booking.sitter.toString() === uid;
    const isOpenMarketplace = booking.status === 'open';

    if (!isAssignedSitter && !isOpenMarketplace) {
      return res.status(403).json({ message: 'Not authorized to respond to this booking' });
    }

    // 🔴 FIX (bug: "el sitter rfadhha... w hiya awdet jetou fel ntf w
    // ki 9belha jetou l'attente mtaa el confirmation") - el notification
    // "booking_received" el asliya (createBooking) MA tetmسa7ch/ma
    // tet-disable-ch ba3d el sitter yerfudh - ken ye3awed ydass 3liha
    // mel jdid (Notifications, stale) ba3d el owner yrebroadcasti
    // (status="open"), RequestScreen yeحell b'NAFS el bookingId, w
    // "isOpenMarketplace" (fou9) ma yeحekk-ch ken had el sitter HOWA
    // NAFSOU elli rafedh déjà - ynajjam ye5tar "accept" mel jdid 3la
    // el booking mte3ou nafsou (candidate), el owner ye5ou "En attente
    // de confirmation" 3la sitter elli déjà rafedh. Guard explicite:
    // sitter mawjoud fel "rejectedBy" MARFOUDH yerja3 yjaweb (accept
    // WALA reject) 3la NAFS el booking, quelle que soit el tari9a elli
    // wselou biha (notification stale, appel API direct...).
    if (isOpenMarketplace && booking.rejectedBy.some((id) => id.toString() === uid)) {
      return res.status(403).json({ message: 'You already declined this booking' });
    }

    const respondingSitter = await User.findById(req.userId).select('fullName');

    if (booking.status === 'pending') {
      if (action === 'accept') {
        // 🔵 ZID (feature "compatibilite entre animaux"): n3awdou
        // nchekkou el conflit CE moment (mch ghir ki createBooking) -
        // el sitter momken 9bel booking okhra (nefs creneau, category
        // mختلفة) MIN BAAD el owner ba3ath had el talab (defense en
        // profondeur, nafs l'approche mta3 verification el dates).
        const conflict = await checkCategoryCapacityConflict({
          sitterId: req.userId,
          checkIn: booking.checkIn,
          checkOut: booking.checkOut,
          category: getSingleCategory(booking.pets),
          newPetCount: booking.pets.length,
          excludeBookingId: booking._id,
        });
        if (!conflict.ok) {
          return res.status(409).json({ message: buildConflictMessage(conflict), reason: conflict.reason });
        }

        booking.status = 'accepted';
        await booking.save();
        await Notification.create({
          recipient: booking.owner,
          message: `${respondingSitter?.fullName || 'The sitter'} accepted your booking request!`,
          type: 'booking_accepted',
          relatedBooking: booking._id,
        });
      } else {
        booking.status = 'rejected';
        booking.rejectedBy.push(req.userId);
        await booking.save();
        await Notification.create({
          recipient: booking.owner,
          message: `${respondingSitter?.fullName || 'The sitter'} declined your booking request. Want to offer it to similar sitters nearby?`,
          type: 'booking_rejected',
          relatedBooking: booking._id,
        });
      }
    } else {
      // -------- "open" (marketplace) - candidate sitter --------
      if (action === 'accept') {
        // 🔵 ZID (kifma tlab): "el total yethseb 7asb les prix eli
        // ketebhom el sitter [candidate] el jdid, w X kadeh men pet" -
        // el prix el asli (mel sitter elli rafedh) MA3ANDOUCH me3na
        // tawa, kol sitter 3andou tarifs mte3ou. Ne5dou el services
        // (serviceId elli el owner talab) w n7ottoulhom PRIX el
        // candidate el jdid, w total = sum(price) * 3adad el pets.
        //
        // 🔵 ZID (feature "compatibilite entre animaux"): el prix tawa
        // ye5taleф 3ala 7sab el category (small_dog/guard_dog/cat) -
        // kol el pets fel booking NEFS el category (chraht fel
        // resolveBookingPetsCategory), fa n7esbou category WA7DA bark.
        const bookingCategory = getSingleCategory(booking.pets);
        const candidateSitterDoc = await Sitter.findById(req.userId).select('services');
        const candidatePriceMap = new Map();
        for (const s of candidateSitterDoc?.services || []) {
          const match = (s.prices || []).find((p) => p.category === bookingCategory);
          if (match) candidatePriceMap.set(s.serviceId, match.price);
        }

        // 🔵 ZID (kifma tlab): "kol service 3andou el pets mte3ou howa"
        // - MCH 3adad global tel pets (booking.pets.length) - kol
        // service, el 3adad houwa "s.petIds.length" (chraht fel
        // bookingServiceSchema, models/booking.js).
        // 🔴 FIX (kifma tlab: "el checkout mta3 service hebergement...
        // tethseb b prix nhar bark") - "sitting_long_term_boarding"
        // (per jour) lezmou *nb nights (checkOut - checkIn, days) -
        // el ba9i el services (per visite) ma yetbeddlouch (nafs
        // mant9 el frontend, request_a_book.dart, _nightsCount/_total).
        const PER_DAY_SERVICE_ID = 'sitting_long_term_boarding';
        const nightsCount = Math.max(1, Math.round((booking.checkOut - booking.checkIn) / (1000 * 60 * 60 * 24)));

        let newTotal = 0;
        booking.services = booking.services.map((s) => {
          // 🔵 fallback: lowkan (7ala nadra) had sitter ma3andouch had
          // service mrakez l'had category - n5alliw el prix el 9dim
          // (bch ma tsirch "0 DT" bla ma3na).
          const price = candidatePriceMap.has(s.serviceId) ? candidatePriceMap.get(s.serviceId) : s.price;
          const petCount = (s.petIds || []).length || booking.pets.length; // fallback: data 9dima (9bal el feature)
          const multiplier = s.serviceId === PER_DAY_SERVICE_ID ? nightsCount : 1;
          newTotal += price * petCount * multiplier;
          return { serviceId: s.serviceId, price, petIds: s.petIds };
        });
        booking.total = newTotal;

        booking.pendingCandidateSitter = req.userId;
        booking.status = 'awaiting_confirmation';
        await booking.save();
        await Notification.create({
          recipient: booking.owner,
          message: `${respondingSitter?.fullName || 'A sitter'} wants to take care of your pets. Do you accept?`,
          type: 'candidate_accepted',
          relatedBooking: booking._id,
        });
      } else {
        booking.rejectedBy.push(req.userId);
        await booking.save();
      }
    }

    res.status(200).json({ message: 'Response recorded', booking });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// BROADCAST BOOKING (owner - actionable "booking_rejected" notification,
// "Yes" bouton: "baathha l sitters okhrin")
// ============================================================================
exports.broadcastBooking = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    if (booking.owner.toString() !== req.userId.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    if (booking.status !== 'rejected') {
      return res.status(400).json({ message: 'Only a rejected booking can be re-broadcast' });
    }

    booking.status = 'open';
    booking.sitter = null;
    await booking.save();

    // 🔵 el bouton "Yes" fel notification ma yban-ch mrra thenya (déjà "handled").
    await Notification.updateMany(
      { relatedBooking: booking._id, type: 'booking_rejected', isActioned: false },
      { isActioned: true }
    );

    res.status(200).json({ message: 'Booking re-broadcast to similar sitters', booking });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// CONFIRM CANDIDATE (owner - actionable "candidate_accepted" notification,
// Accept/Decline el sitter el candidate)
// ============================================================================
exports.confirmCandidate = async (req, res) => {
  try {
    const { accept } = req.body;
    const booking = await Booking.findById(req.params.id).populate('pets', 'category');
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    if (booking.owner.toString() !== req.userId.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    if (booking.status !== 'awaiting_confirmation' || !booking.pendingCandidateSitter) {
      return res.status(400).json({ message: 'No pending candidate to confirm' });
    }

    const candidateId = booking.pendingCandidateSitter;

    // 🔵 ZID (feature "compatibilite entre animaux"): nchekkou el
    // conflit 9BAL ma nmassa7ou el notification ("actioned") - CE
    // moment houwa l'engagement 7a9i9i tel candidate. Ken famma
    // conflit, lezem el owner tab9a 3andou el boutons Accept/Decline
    // (ma yban-lou-ch "khlast" bla ma tsir 7atta 7aja).
    if (accept) {
      const conflict = await checkCategoryCapacityConflict({
        sitterId: candidateId,
        checkIn: booking.checkIn,
        checkOut: booking.checkOut,
        category: getSingleCategory(booking.pets),
        newPetCount: booking.pets.length,
        excludeBookingId: booking._id,
      });
      if (!conflict.ok) {
        return res.status(409).json({ message: buildConflictMessage(conflict), reason: conflict.reason });
      }
    }

    // 🔵 el bouton "Accept/Decline" fel notification ma yban-ch mrra thenya.
    await Notification.updateMany(
      { relatedBooking: booking._id, type: 'candidate_accepted', isActioned: false },
      { isActioned: true }
    );

    if (accept) {
      booking.sitter = candidateId;
      booking.status = 'accepted';
      booking.pendingCandidateSitter = null;
      await booking.save();
      await Notification.create({
        recipient: candidateId,
        message: `Your offer was accepted! You're now confirmed for this booking.`,
        type: 'booking_accepted',
        relatedBooking: booking._id,
      });
    } else {
      booking.rejectedBy.push(candidateId);
      booking.pendingCandidateSitter = null;
      booking.status = 'open'; // tab9a "mfattcha" lel sitters l'okhrin
      await booking.save();
      await Notification.create({
        recipient: candidateId,
        message: `The owner chose another sitter for this booking.`,
        type: 'candidate_declined',
        relatedBooking: booking._id,
      });
    }

    res.status(200).json({ message: 'Candidate response recorded', booking });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// CANCEL BOOKING (sitter - "Cancel Booking" mel sitter_calender.dart,
// booking déjà "accepted")
// ============================================================================
// 🔵 ZID (kifma tlab): el sitter ynajjam yenni booking mo'akkad (mch
// bess "pending"). Twalli "rejected" - NAFS mant9 el reject direct
// (rejectedBy + notification "booking_rejected" actionable l'owner:
// "tebaathha l sitters okhrin?").
// ============================================================================
exports.cancelBooking = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    if (!booking.sitter || booking.sitter.toString() !== req.userId.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    if (booking.status !== 'accepted') {
      return res.status(400).json({ message: 'Only a confirmed booking can be cancelled' });
    }

    const cancellingSitter = await User.findById(req.userId).select('fullName');

    booking.status = 'rejected';
    booking.rejectedBy.push(req.userId);
    booking.sitter = null;
    await booking.save();

    await Notification.create({
      recipient: booking.owner,
      message: `${cancellingSitter?.fullName || 'The sitter'} cancelled your confirmed booking. Want to offer it to similar sitters nearby?`,
      type: 'booking_rejected',
      relatedBooking: booking._id,
    });

    res.status(200).json({ message: 'Booking cancelled', booking });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET BOOKING ALTERNATIVES (feature "compatibilite entre animaux") -
// ki createBooking/respondToBooking/confirmCandidate yرجعو 409
// (conflit category/capacite), el front yeste5dem el endpoint hedha
// bch y3aroudh 3al owner:
//   A) "sameSitterSlots": horaire ekher 3and NAFS el sitter (nafs
//      douree, l'awwal 3 creneaux khalyin fel 7 ayem el jayin).
//   B) "otherSitters": sitters okhrin elli ye9blou el category, soit
//      fadhyin kaملement ("free") soit ynajjmou yzidou el pet fel
//      groupe mawjoud ("joinGroup", < 5).
// GET /bookings/alternatives?sitterId=..&checkIn=..&checkOut=..&petIds=id1,id2
// ============================================================================
exports.getBookingAlternatives = async (req, res) => {
  try {
    const { sitterId, checkIn, checkOut, petIds } = req.query;
    if (!sitterId || !checkIn || !checkOut || !petIds) {
      return res.status(400).json({ message: 'Missing required query params (sitterId, checkIn, checkOut, petIds)' });
    }

    const petIdList = String(petIds).split(',').filter(Boolean);
    const petsCheck = await resolveBookingPetsCategory(petIdList);
    if (petsCheck.error) {
      return res.status(400).json({ message: petsCheck.error });
    }
    const { category, count: newPetCount } = petsCheck;

    const originalCheckIn = new Date(checkIn);
    const originalCheckOut = new Date(checkOut);
    const durationMs = originalCheckOut.getTime() - originalCheckIn.getTime();
    const oneHourFromNow = Date.now() + 60 * 60 * 1000;

    // -------- A) nafs el Sitter, horaire ekher (l'awwal 3, 7 ayem el jayin) --------
    const currentSitter = await Sitter.findById(sitterId).select('recurringDaysOff specificDatesOff isAvailable');
    const sameSitterSlots = [];
    if (currentSitter) {
      for (let dayOffset = 0; dayOffset <= 6 && sameSitterSlots.length < 3; dayOffset++) {
        const candidateCheckIn = new Date(originalCheckIn.getTime() + dayOffset * 24 * 60 * 60 * 1000);
        const candidateCheckOut = new Date(candidateCheckIn.getTime() + durationMs);

        if (candidateCheckIn.getTime() < oneHourFromNow) continue;
        if (isSitterOffOnDate(currentSitter, candidateCheckIn)) continue;

        const conflict = await checkCategoryCapacityConflict({
          sitterId,
          checkIn: candidateCheckIn,
          checkOut: candidateCheckOut,
          category,
          newPetCount,
        });
        if (conflict.ok) {
          sameSitterSlots.push({ checkIn: candidateCheckIn, checkOut: candidateCheckOut });
        }
      }
    }

    // -------- B) sitters okhrin (nefs el creneau el mtaleb) --------
    const candidateSitters = await Sitter.find({
      _id: { $ne: sitterId },
      role: 'sitter',
      acceptedPetCategories: category,
    }).select('fullName photoUrl city location isAvailable recurringDaysOff specificDatesOff');

    const otherSitters = [];
    for (const s of candidateSitters) {
      if (s.isAvailable === false) continue;
      if (isSitterOffOnDate(s, originalCheckIn)) continue;

      const conflict = await checkCategoryCapacityConflict({
        sitterId: s._id,
        checkIn: originalCheckIn,
        checkOut: originalCheckOut,
        category,
        newPetCount,
      });
      if (!conflict.ok) continue; // category mختلفة wela complet - skip

      otherSitters.push({
        sitterId: s._id,
        fullName: s.fullName,
        photoUrl: s.photoUrl,
        city: s.city,
        type: conflict.existingCount > 0 ? 'joinGroup' : 'free',
        existingCount: conflict.existingCount || 0,
        // 🔵 mafamech "price" houni 3ala 9asd - el tarif tawa PER-
        // SERVICE (sitterServiceSchema.prices), w had endpoint ma
        // ye3rafch chnowa el services elli el owner talab (bark sitterId/
        // checkIn/checkOut/petIds) - el owner yechouf el prix el kaملa
        // ki yedkhol l'profile tel sitter (getSitterPublicProfile).
      });
    }

    res.status(200).json({ category, sameSitterSlots, otherSitters });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};