// controllers/checkoutQuestionnaireController.js
const Booking = require('../models/booking');
const CheckoutQuestionnaire = require('../models/checkoutQuestionnaire');
const User = require('../models/user');
const Notification = require('../models/notification');

// ============================================================================
// Helper: njibou (wla nkhalgou lowkan mazel mawjoud) el questionnaire
// tel "req.userId" 3la "bookingId" - w nrajj3ou el role + reviewee zeda
// (bch ma na3awdouch el mant9 fi kol endpoint).
// ============================================================================
async function getOrCreateQuestionnaire(bookingId, userId) {
  const booking = await Booking.findById(bookingId).select('owner sitter status checkOut');
  if (!booking) return { error: 'not_found' };

  const uid = userId.toString();
  const isOwner = booking.owner.toString() === uid;
  const isSitter = booking.sitter && booking.sitter.toString() === uid;
  if (!isOwner && !isSitter) return { error: 'forbidden' };

  const role = isOwner ? 'owner' : 'sitter';
  const revieweeId = isOwner ? booking.sitter : booking.owner;

  let questionnaire = await CheckoutQuestionnaire.findOne({ booking: booking._id, respondent: userId });
  if (!questionnaire) {
    questionnaire = await CheckoutQuestionnaire.create({
      booking: booking._id,
      respondent: userId,
      respondentRole: role,
      reviewee: revieweeId,
      status: 'pending',
    });
  }
  // 🔵 ZID: el front ye7taj esm/photo tel "reviewee" (bch ywarri "Are
  // you satisfied with Rami?" mch "with the sitter") - populate direct
  // houni bch el 3 step-endpoints el kol yerja3ouha automatique (kolhom
  // yesta3maleu had helper).
  await questionnaire.populate('reviewee', 'fullName photoUrl');

  return { booking, questionnaire, role };
}

// ============================================================================
// GET PENDING QUESTIONNAIRES (home screen, owner W sitter - "3andi
// questionnaire l'hin n'jaweb 3lih?")
// ============================================================================
// 🔵 ZID: booking "accepted" + checkOut déjà 3adda + el questionnaire
// tel user el 7ali mazel ma "completed"ch/"stopped"ch, W lowkan
// "awaiting_new_checkout" - el "nextPromptAt" lezem déjà wasel.
// ============================================================================
exports.getPendingQuestionnaires = async (req, res) => {
  try {
    const now = new Date();
    const bookings = await Booking.find({
      status: 'accepted',
      checkOut: { $lte: now },
      $or: [{ owner: req.userId }, { sitter: req.userId }],
    }).select('_id owner sitter checkOut');

    const pending = [];
    for (const booking of bookings) {
      const role = booking.owner.toString() === req.userId.toString() ? 'owner' : 'sitter';
      const questionnaire = await CheckoutQuestionnaire.findOne({ booking: booking._id, respondent: req.userId });

      if (!questionnaire) {
        // 🔵 mazel ma bdach l'questionnaire - eligible direct.
        pending.push({ bookingId: booking._id, role });
        continue;
      }
      if (questionnaire.status === 'completed' || questionnaire.status === 'stopped_service_not_done') continue;
      if (questionnaire.status === 'awaiting_new_checkout' && questionnaire.nextPromptAt && questionnaire.nextPromptAt > now) continue;

      pending.push({ bookingId: booking._id, role });
    }

    res.status(200).json({ pending });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET QUESTIONNAIRE (fetch wla khal9 lowkan mazel mawjoud - bch el
// front ynajjam "yresumi" el wizard mnin we9af)
// ============================================================================
exports.getQuestionnaire = async (req, res) => {
  try {
    const result = await getOrCreateQuestionnaire(req.params.id, req.userId);
    if (result.error === 'not_found') return res.status(404).json({ message: 'Booking not found' });
    if (result.error === 'forbidden') return res.status(403).json({ message: 'Not authorized' });

    res.status(200).json({ questionnaire: result.questionnaire });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// Étape 1: SERVICE DONE?  { done: bool, reason?: string }
// ============================================================================
exports.answerServiceDone = async (req, res) => {
  try {
    const { done, reason } = req.body;
    if (typeof done !== 'boolean') return res.status(400).json({ message: 'done (boolean) is required' });

    const result = await getOrCreateQuestionnaire(req.params.id, req.userId);
    if (result.error === 'not_found') return res.status(404).json({ message: 'Booking not found' });
    if (result.error === 'forbidden') return res.status(403).json({ message: 'Not authorized' });

    const { questionnaire } = result;
    if (questionnaire.serviceDone !== null) {
      return res.status(400).json({ message: 'Already answered' });
    }

    questionnaire.serviceDone = done;
    if (!done) {
      questionnaire.serviceDoneReason = reason || '';
      questionnaire.status = 'stopped_service_not_done';
    }
    await questionnaire.save();

    res.status(200).json({ questionnaire });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// Étape 2: CHECKOUT DONE?  { done: bool, blamedParty?: 'owner'|'sitter',
// newCheckoutTime?: ISOString }
// ============================================================================
// 🔵 ZID: lowkan "done: false" - LEZEM blamedParty + newCheckoutTime
// (chkoun sabab et-ta2khir + el wa9t el jdid eli tfahmou fih). El
// questionnaire ywalli "awaiting_new_checkout" (testanna el wa9t el
// jdid ye9rab 9bal ma tos2al mel jdid - MECH loop direct, kifma tlab).
// ============================================================================
exports.answerCheckoutDone = async (req, res) => {
  try {
    const { done, blamedParty, newCheckoutTime } = req.body;
    if (typeof done !== 'boolean') return res.status(400).json({ message: 'done (boolean) is required' });

    const result = await getOrCreateQuestionnaire(req.params.id, req.userId);
    if (result.error === 'not_found') return res.status(404).json({ message: 'Booking not found' });
    if (result.error === 'forbidden') return res.status(403).json({ message: 'Not authorized' });

    const { questionnaire } = result;
    if (questionnaire.serviceDone !== true) {
      return res.status(400).json({ message: 'Answer service-done first' });
    }
    if (questionnaire.checkoutDone === true) {
      return res.status(400).json({ message: 'Checkout already confirmed' });
    }

    if (done) {
      questionnaire.checkoutDone = true;
      questionnaire.nextPromptAt = null;
      questionnaire.status = 'pending'; // ykomml lel étape "payment"
    } else {
      if (!blamedParty || !['owner', 'sitter'].includes(blamedParty)) {
        return res.status(400).json({ message: 'blamedParty must be "owner" or "sitter"' });
      }
      if (!newCheckoutTime) {
        return res.status(400).json({ message: 'newCheckoutTime is required' });
      }
      questionnaire.checkoutDelays.push({ blamedParty, newCheckoutTime: new Date(newCheckoutTime) });
      questionnaire.nextPromptAt = new Date(newCheckoutTime);
      questionnaire.status = 'awaiting_new_checkout';
    }
    await questionnaire.save();

    res.status(200).json({ questionnaire });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// Étape 3: PAYMENT DONE?  { done: bool, reason?: string }
// ============================================================================
exports.answerPaymentDone = async (req, res) => {
  try {
    const { done, reason } = req.body;
    if (typeof done !== 'boolean') return res.status(400).json({ message: 'done (boolean) is required' });

    const result = await getOrCreateQuestionnaire(req.params.id, req.userId);
    if (result.error === 'not_found') return res.status(404).json({ message: 'Booking not found' });
    if (result.error === 'forbidden') return res.status(403).json({ message: 'Not authorized' });

    const { questionnaire } = result;
    if (questionnaire.checkoutDone !== true) {
      return res.status(400).json({ message: 'Answer checkout-done first' });
    }
    if (questionnaire.paymentDone !== null) {
      return res.status(400).json({ message: 'Already answered' });
    }

    questionnaire.paymentDone = done;
    if (!done) questionnaire.paymentNotDoneReason = reason || '';
    await questionnaire.save();

    res.status(200).json({ questionnaire });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// Étape 4 (final): SATISFIED? + AVIS  { satisfied: bool, review?: string }
// ============================================================================
// 🔵 ZID (kifma tlab): hedha el "avis" ywalli VRAI review (yban 3al
// profile - chrahtha getUserReviews, userController.js).
// ============================================================================
// ============================================================================
// Étape 4 (final): SATISFIED? + AVIS (review) + RATING (4 catégories:
// Trust/Service/Communication/Knowledge, 1-5 el wa7da)
// { satisfied, review?, ratingTrust, ratingService, ratingCommunication,
//   ratingKnowledge }
// ============================================================================
// 🔵 ZID (kifma tlab): "averageRating" = el 4 njoum mجموعين me9soumin
// 3la 4. Hedha el "VRAI review" - yban 3al profile (getUserReviews) +
// notification l'reviewee ("new_review", relatedReviewId - bch el
// front ye3raf ywarriha "en gris claire", "hedha el jdid").
// ============================================================================
exports.answerSatisfaction = async (req, res) => {
  try {
    const { satisfied, review, ratingTrust, ratingService, ratingCommunication, ratingKnowledge } = req.body;
    if (typeof satisfied !== 'boolean') return res.status(400).json({ message: 'satisfied (boolean) is required' });

    const ratings = { ratingTrust, ratingService, ratingCommunication, ratingKnowledge };
    for (const [key, value] of Object.entries(ratings)) {
      if (typeof value !== 'number' || value < 1 || value > 5) {
        return res.status(400).json({ message: `${key} must be a number between 1 and 5` });
      }
    }

    const result = await getOrCreateQuestionnaire(req.params.id, req.userId);
    if (result.error === 'not_found') return res.status(404).json({ message: 'Booking not found' });
    if (result.error === 'forbidden') return res.status(403).json({ message: 'Not authorized' });

    const { questionnaire } = result;
    if (questionnaire.paymentDone === null) {
      return res.status(400).json({ message: 'Answer payment-done first' });
    }
    if (questionnaire.status === 'completed') {
      return res.status(400).json({ message: 'Already completed' });
    }

    questionnaire.satisfied = satisfied;
    questionnaire.review = review || '';
    questionnaire.ratingTrust = ratingTrust;
    questionnaire.ratingService = ratingService;
    questionnaire.ratingCommunication = ratingCommunication;
    questionnaire.ratingKnowledge = ratingKnowledge;
    questionnaire.averageRating = Math.round(((ratingTrust + ratingService + ratingCommunication + ratingKnowledge) / 4) * 10) / 10;
    questionnaire.status = 'completed';
    await questionnaire.save();

    const reviewer = await User.findById(req.userId).select('fullName');
    await Notification.create({
      recipient: questionnaire.reviewee,
      message: `${reviewer?.fullName || 'Someone'} left you a ${questionnaire.averageRating}★ review!`,
      type: 'new_review',
      relatedReviewId: questionnaire._id,
    });

    res.status(200).json({ questionnaire });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};