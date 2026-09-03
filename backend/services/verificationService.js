// services/verificationService.js
const Animal = require('../models/animal');
const Booking = require('../models/booking');
const CheckoutQuestionnaire = require('../models/checkoutQuestionnaire');
const VerificationSettings = require('../models/verificationSettings');

// ============================================================================
// verificationService
// ============================================================================
// 🔵 ZID (kifma tlab): "hedhom standards ay 7ad ynajjam yamlhom" - el
// checklist el 9dima (profil kaملa) tawa "critères profil" bark - zedna
// critères 7a9i9iyin (track-record): kadeh services + kadeh clients
// mo5talfin (sitter) + % avis mzyanin (owner/sitter) - MOUCH ay 7ad
// ynajjam ye5tar3houm bark b'ma3loumet el profil.
//
// 🔵 el fichier hedha MECHTAREK bin adminController.js (checklist tel
// Admin, screen "Validation") W userController.js (checklist tel user
// nafsou, screen "Vérification" - sidebar) - bch ma nekteb-ch NEFS el
// mant9 fi 2 blayes (sehla, mahiech complique).
//
// 🔴 IMPORTANT (définition "avis khayeb"): mafamech champ "badReview"
// mnfassel fel CheckoutQuestionnaire - ne5dhou satisfied===false kifha
// kif "avis khayeb" (el binaire el WA7ED el mawjoud déjà, sahel/wadhe7).
// ============================================================================

// 🔵 singleton: dima document WA7ED bark - lowkan mafamech, ne5la9ou
// b'el valeurs "default" tel schema.
async function getVerificationSettings() {
  let settings = await VerificationSettings.findOne();
  if (!settings) {
    settings = await VerificationSettings.create({});
  }
  return settings;
}

// 🔵 % avis mzyanin (mch khayeb) - terja3 null lowkan mafamech avis
// 7atta (mch 0%, bch ma nkhalliwch "0 avis" yeb9a "0% mzyan" = échec
// automatique erroné - lezmou track-record 7a9i9i 9bal ma na7kmou).
async function computeGoodReviewPercent(userId) {
  const reviews = await CheckoutQuestionnaire.find({ reviewee: userId, satisfied: { $ne: null } }).select('satisfied');
  const total = reviews.length;
  if (total === 0) return { percent: null, total: 0 };
  const bad = reviews.filter((r) => r.satisfied === false).length;
  const percent = Math.round(((total - bad) / total) * 1000) / 10; // 1 chiffre ba3d el fasla
  return { percent, total };
}

// ============================================================================
// computeChecklist(user)
// ============================================================================
// terja3 { items, metrics, isComplete }
//   items:   { critère: true/false } - bch el UI twarri ✓/✗.
//   metrics: ar9am 7a9i9iyin (kadeh services/clients/% - w el seuils el
//            mrakzin) - bch el UI (Vérification, sidebar) twarri
//            "progress" (mathalan "45/100"), mch ghir ✓/✗ bla contexte.
//   isComplete: el critères el kol True.
// ============================================================================
async function computeChecklist(user) {
  const items = {
    fullName: !!(user.fullName && user.fullName.trim()),
    phone: !!(user.phone && user.phone.trim()),
    city: !!(user.city && user.city.trim()),
    photo: !!(user.photoUrl && user.photoUrl.trim()),
    // 🔴 FIX (kifma tlab: "sawae el cin mteek men kodem w men telii") -
    // tawa RECTO + VERSO el 2 lezmhom (mch photo wa7da bark).
    cin: !!(user.cinFrontPhotoUrl && user.cinFrontPhotoUrl.trim()) && !!(user.cinBackPhotoUrl && user.cinBackPhotoUrl.trim()),
  };
  const metrics = {};

  if (user.role === 'owner') {
    const petsCount = await Animal.countDocuments({ owner: user._id });
    items.hasPet = petsCount > 0;

    const settings = await getVerificationSettings();
    const servicesCount = await Booking.countDocuments({ owner: user._id, status: 'accepted' });
    const { percent: goodReviewPercent, total: totalReviews } = await computeGoodReviewPercent(user._id);

    items.minServices = servicesCount >= settings.ownerMinServices;
    items.goodReviewPercent = goodReviewPercent !== null && goodReviewPercent >= settings.ownerMinGoodReviewPercent;

    metrics.servicesCount = servicesCount;
    metrics.servicesRequired = settings.ownerMinServices;
    metrics.goodReviewPercent = goodReviewPercent;
    metrics.goodReviewPercentRequired = settings.ownerMinGoodReviewPercent;
    metrics.totalReviews = totalReviews;
  } else if (user.role === 'sitter') {
    items.bio = !!(user.bio && user.bio.trim());
    items.hasService = Array.isArray(user.services) && user.services.length > 0;
    items.residenceType = !!user.residenceType;
    items.transportationAnswered = user.hasTransportation !== null && user.hasTransportation !== undefined;

    const settings = await getVerificationSettings();
    // 🔵 ZID (kifma tlab): "ynajem yaaml 100 services l abd bark ama
    // lezmou ykoun amel service l 40 clients differents" - el 2 el
    // critères (kadeh services TOTAL + kadeh clients DISTINCTS) mnfaslin,
    // el WA7ED ma yghatich el akhor.
    const acceptedBookings = await Booking.find({ sitter: user._id, status: 'accepted' }).select('owner');
    const servicesCount = acceptedBookings.length;
    const distinctClients = new Set(acceptedBookings.map((b) => b.owner.toString())).size;
    const { percent: goodReviewPercent, total: totalReviews } = await computeGoodReviewPercent(user._id);

    items.minServices = servicesCount >= settings.sitterMinServices;
    items.minDistinctClients = distinctClients >= settings.sitterMinDistinctClients;
    items.goodReviewPercent = goodReviewPercent !== null && goodReviewPercent >= settings.sitterMinGoodReviewPercent;

    metrics.servicesCount = servicesCount;
    metrics.servicesRequired = settings.sitterMinServices;
    metrics.distinctClients = distinctClients;
    metrics.distinctClientsRequired = settings.sitterMinDistinctClients;
    metrics.goodReviewPercent = goodReviewPercent;
    metrics.goodReviewPercentRequired = settings.sitterMinGoodReviewPercent;
    metrics.totalReviews = totalReviews;
  } else if (user.role === 'courier') {
    items.vehicleType = !!(user.vehicleType && user.vehicleType.trim());
  }

  const values = Object.values(items);
  const isComplete = values.length > 0 && values.every(Boolean);
  return { items, metrics, isComplete };
}

module.exports = { getVerificationSettings, computeChecklist };