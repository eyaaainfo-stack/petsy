// models/verificationSettings.js
const mongoose = require('mongoose');

// ============================================================================
// VerificationSettings
// ============================================================================
// 🔵 ZID (kifma tlab): "khalli les conditions hedhom yodhhrou 3and el
// admin w ynajem yamlelhom modification" - documenT WA7ED bark (singleton,
// mafamech besoin l "kol admin 3andou settings tou3ou") - el seuils
// (kadeh services/clients/% avis lezمهم) l'admin ynajjam ybadelhom mel
// écran "Validation" (bouton réglages).
// ============================================================================
const verificationSettingsSchema = new mongoose.Schema(
  {
    // -------- Sitter --------
    sitterMinServices: { type: Number, default: 100 },
    sitterMinDistinctClients: { type: Number, default: 40 },
    sitterMinGoodReviewPercent: { type: Number, default: 90 },
    // -------- Owner --------
    ownerMinServices: { type: Number, default: 30 },
    ownerMinGoodReviewPercent: { type: Number, default: 95 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('VerificationSettings', verificationSettingsSchema);