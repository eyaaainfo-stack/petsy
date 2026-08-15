// models/animal.js
const mongoose = require('mongoose');

// ============================================================================
// Animal (Pet)
// ============================================================================
// Kifma fel diagramme: Animal <>-- Proprietaire (aggregation). Fel Mongoose,
// nesta3mlou "owner" (ObjectId, ref: 'User') - kol Animal ye3raf chkoun
// Proprietaire tou3ou.
// ============================================================================
const animalSchema = new mongoose.Schema(
  {
    owner: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User', // ref lel collection 'users' (el Owner discriminator)
      required: true,
    },
    petType: {
      type: String,
      enum: ['dog', 'cat'],
      required: true,
    },
    name: { type: String, required: true },
    // 🔵 ZID: el path/URL tel photo (mch el image nafsha, mel'ma7att
    // fel middleware/upload.js) - chrahtha fel réponse el text.
    photoUrl: { type: String, default: '' },
    age: { type: Number },
    breed: { type: String, default: '' },
    size: { type: String, default: '' },
    gender: { type: String, enum: ['female', 'male'] },

    // behaviors: List (mathalan ['calm', 'friendly'])
    behaviors: { type: [String], default: [] },

    // careInfo: kol wa7ed Boolean wala null (mazel ma jaweb)
    careInfo: {
      microchipped: { type: Boolean, default: null },
      vaccinated: { type: Boolean, default: null },
      neutered: { type: Boolean, default: null },
      medication: { type: Boolean, default: null },
    },

    vetClinicName: { type: String, default: '' },
    vetClinicPhone: { type: String, default: '' },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Animal', animalSchema);