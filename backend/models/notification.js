const mongoose = require('mongoose');

// ============================================================================
// Notification
// ============================================================================
// 🔵 ZID: ki el owner yebaath booking request, notification tetzad l'
// SITTER (talab jdid) W l'OWNER (confirmation el talab tab3ath) - nafs
// mant9 el mockup ("Your booking request has been sent to Rami!").
// ============================================================================
const notificationSchema = new mongoose.Schema(
  {
    recipient: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    message: { type: String, required: true },
    // 🔵 type: bch el front ynajjam ye5tar el icon el munasba (✅/💬/❓...)
    // 🔵 ZID (kifma tlab: workflow reject/broadcast/candidate): 3
    // types jdad - 'booking_rejected' (l'owner, actionable: "tebaathha
    // l sitters okhrin?"), 'candidate_accepted' (l'owner, actionable:
    // "ta9bel had sitter?"), 'candidate_declined' (l'sitter candidate,
    // informative: "el owner 5tar sitter okhor").
    // 🔵 ZID (kifma tlab): 'new_review' - ki 7ad ykemmel el questionnaire
    // (rating 4 catégories + avis), notification l'reviewee ("X left
    // you a review!").
    // 🔵 ZID (kifma tlab: "ywalli el compte verifiee nhb tji lel user
    // ntf") - 'account_verified' - ki l'admin ye5tar "Valider" (écran
    // Validation), notification l'user (badge bleu tawa yban lel kol).
    type: {
      type: String,
      enum: ['booking_sent', 'booking_received', 'booking_accepted', 'booking_rejected', 'candidate_accepted', 'candidate_declined', 'new_review', 'message', 'other', 'account_verified'],
      default: 'other',
    },
    isRead: { type: Boolean, default: false },
    // 🔵 ZID: notifications "actionable" (bottons Yes/No fel notification
    // nafsha) - ki el user yjaweb (ay jiha), n7ottouha true bch el
    // bottons ma yban-wch mrra thenya (booking déjà mtaffel/handled).
    isActioned: { type: Boolean, default: false },
    // 🔵 relatedBooking: optionnel - bch el front ynajjam ymchi l'détails
    // el booking direct mel notification (feature future).
    relatedBooking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', default: null },
    // 🔵 ZID (kifma tlab): "new_review" - bch el front ye3raf BALZBOUT
    // chnowa el review el jdida (ki el user 3andou ktar men review
    // wa7da) - bch ywarriha "en gris claire" (highlight, "hedha el jdid").
    relatedReviewId: { type: mongoose.Schema.Types.ObjectId, ref: 'CheckoutQuestionnaire', default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Notification', notificationSchema);