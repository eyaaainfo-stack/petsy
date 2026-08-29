const Booking = require('../models/booking');
const Notification = require('../models/notification');
const User = require('../models/user');
const Sitter = require('../models/sitter');

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

    // 🔵 ZID (debug): "Patients du jour" fadhya rghm el booking mawjouda -
    // n7ebbou nchoufou: (1) kadeh booking "accepted" 3andou el sitter
    // el 7ali 7a9i9atan, (2) checkIn/checkOut b'dhabt (UTC, kifha kif
    // mo5zana fel DB) bch n9arnouhom m3a "el lyoum" (server local time).
    console.log(`\n🔍 [MY-SCHEDULE] sitterId="${req.userId}" - server "lyoum" (local): ${new Date().toString()}`);
    console.log(`🔍 [MY-SCHEDULE] server "lyoum" (UTC): ${new Date().toISOString()}`);
    console.log(`🔍 [MY-SCHEDULE] la9a ${bookings.length} booking(s) "accepted":`);
    bookings.forEach((b) => {
      console.log(`   - _id=${b._id} checkIn=${b.checkIn.toISOString()} checkOut=${b.checkOut.toISOString()} pets=${b.pets.map((p) => p.name).join(',')}`);
    });

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
      rejectedBy: { $ne: req.userId },
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

    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });

    const uid = req.userId.toString();
    const isAssignedSitter = booking.status === 'pending' && booking.sitter && booking.sitter.toString() === uid;
    const isOpenMarketplace = booking.status === 'open';

    if (!isAssignedSitter && !isOpenMarketplace) {
      return res.status(403).json({ message: 'Not authorized to respond to this booking' });
    }

    const respondingSitter = await User.findById(req.userId).select('fullName');

    if (booking.status === 'pending') {
      if (action === 'accept') {
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
        const candidateSitterDoc = await Sitter.findById(req.userId).select('services');
        const candidatePriceMap = new Map((candidateSitterDoc?.services || []).map((s) => [s.serviceId, s.price]));
        const petCount = booking.pets.length;

        let newTotal = 0;
        booking.services = booking.services.map((s) => {
          // 🔵 fallback: lowkan (7ala nadra) had sitter ma3andouch had
          // service mrakez - n5alliw el prix el 9dim (bch ma tsirch
          // "0 DT" bla ma3na).
          const price = candidatePriceMap.has(s.serviceId) ? candidatePriceMap.get(s.serviceId) : s.price;
          newTotal += price * petCount;
          return { serviceId: s.serviceId, price };
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
    const booking = await Booking.findById(req.params.id);
    if (!booking) return res.status(404).json({ message: 'Booking not found' });
    if (booking.owner.toString() !== req.userId.toString()) {
      return res.status(403).json({ message: 'Not authorized' });
    }
    if (booking.status !== 'awaiting_confirmation' || !booking.pendingCandidateSitter) {
      return res.status(400).json({ message: 'No pending candidate to confirm' });
    }

    const candidateId = booking.pendingCandidateSitter;

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