// models/checkoutQuestionnaire.js
const mongoose = require('mongoose');

// ============================================================================
// CheckoutQuestionnaire
// ============================================================================
// 🔵 ZID (kifma tlab): questionnaire ba3d el checkout - kol wa7ed
// (owner W sitter) yjaweb 3la 7dhou (document mnfassel per person per
// booking, chrahtha l'index unique tahet). El "reviewee" houwa el
// jiha l'okhra (lowkan respondent=owner, reviewee=sitter, w l'3aks).
//
// 🔵 el "workflow" (état machine):
//   pending -> (service_done?) 
//     NO  -> stopped_service_not_done (khlas, reason mahfoudha)
//     YES -> (checkout_done?)
//       NO -> awaiting_new_checkout (delay mahfoudh, nextPromptAt =
//             el wa9t el jdid - el app tos2al mel jdid "checkout_done?"
//             ghir ki el wa9t heka ywasel)
//       YES -> (payment_done?) -> (satisfied? + avis) -> completed
// ============================================================================
const checkoutQuestionnaireSchema = new mongoose.Schema(
  {
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true },
    respondent: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    respondentRole: { type: String, enum: ['owner', 'sitter'], required: true },
    // 🔵 el jiha l'okhra tel booking - "avis" el respondent ykoun 3liha.
    reviewee: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },

    // -------- Étape 1: service fait? --------
    serviceDone: { type: Boolean, default: null },
    serviceDoneReason: { type: String, default: '' }, // lowkan serviceDone===false

    // -------- Étape 2: checkout fait? (m3a loop el delay) --------
    checkoutDone: { type: Boolean, default: null },
    checkoutDelays: [
      {
        blamedParty: { type: String, enum: ['owner', 'sitter'] },
        newCheckoutTime: { type: Date },
        recordedAt: { type: Date, default: Date.now },
      },
    ],

    // -------- Étape 3: paiement fait? --------
    paymentDone: { type: Boolean, default: null },
    paymentNotDoneReason: { type: String, default: '' },

    // -------- Étape 4: content? (satisfied) + avis (review) + rating
    // (4 catégories: Trust/Service/Communication/Knowledge) --------
    // 🔵 ZID (kifma tlab): ordre el 7a9i9i - "est-ce que satisfait?"
    // (Yes/No) -> "a7kilna 3la l'expérience" (review, text) -> RATING
    // (njoum, 4 catégories) - el 3 flu fi nafs el étape.
    satisfied: { type: Boolean, default: null },
    review: { type: String, default: '' },
    ratingTrust: { type: Number, min: 1, max: 5, default: null },
    ratingService: { type: Number, min: 1, max: 5, default: null },
    ratingCommunication: { type: Number, min: 1, max: 5, default: null },
    ratingKnowledge: { type: Number, min: 1, max: 5, default: null },
    averageRating: { type: Number, default: null },

    status: {
      type: String,
      enum: ['pending', 'awaiting_new_checkout', 'stopped_service_not_done', 'completed'],
      default: 'pending',
    },
    // 🔵 lowkan status=="awaiting_new_checkout" - el wa9t elli lezem
    // el app terja3 tos2al mel jdid "checkout_done?" mba3dou (mch 9bal).
    nextPromptAt: { type: Date, default: null },
  },
  { timestamps: true }
);

// 🔵 wa7ed bark per (booking, respondent) - bch ma yenajjamch y3awed
// yekhala9 questionnaire jdid kol marra.
checkoutQuestionnaireSchema.index({ booking: 1, respondent: 1 }, { unique: true });

module.exports = mongoose.model('CheckoutQuestionnaire', checkoutQuestionnaireSchema);