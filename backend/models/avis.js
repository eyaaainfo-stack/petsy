// models/avis.js
const mongoose = require('mongoose');

// ============================================================================
// Avis (Review)
// ============================================================================
// Kifma fel diagramme: Reservation -- Avis.
// ============================================================================
const avisSchema = new mongoose.Schema(
  {
    reservation: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Reservation',
      required: true,
    },
    rating: { type: Number, min: 1, max: 5, required: true },
    comment: { type: String, default: '' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Avis', avisSchema);