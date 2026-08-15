// models/service.js
const mongoose = require('mongoose');

// ============================================================================
// Service
// ============================================================================
// Kifma fel diagramme: Proprietaire -- Service. 🔵 TODO: el diagramme
// mazel ma yweri KIFACH el service yerbet lel "provider" (Gardien
// d'animau/Courier elli ye9dem el service) - lezmek tzid "provider"
// (ref: 'User') ki tkoun el fikra wadhe7a aktar fel diagramme.
// ============================================================================
const serviceSchema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User', // Proprietaire elli talab/khla9 el service
      required: true,
    },
    type: { type: String, required: true }, // e.g. 'pet_sitting', 'dog_walking', 'transport'
    description: { type: String, default: '' },
    price: { type: Number, default: 0 },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Service', serviceSchema);