// models/animal.js
const mongoose = require('mongoose');

// ============================================================================
// Animal (Pet)
// ============================================================================
// Kifma fel diagramme: Animal ◆-- Proprietaire (composition - el pet
// life-cycle marboutin b'el owner, chrahtha fel models/user.js: cascade
// delete). Fel Mongoose,
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
    // 🔵 ZID (feature "compatibilite entre animaux"): categorie mte3
    // securite/scheduling - MCH nafs 7aja "petType". El chat ykoun
    // dima 'cat' (auto, chraht fel petController.js). El dogs y5tarou
    // el owner binethom 'small_dog' (calme, jaez ye5dem group) wela
    // 'guard_dog' (garde/attaque, DIMA solo, ma yetla9ach m3a categorie
    // okhra fel nefs el creneau 3and NAFS el sitter).
    category: {
      type: String,
      enum: ['small_dog', 'guard_dog', 'cat'],
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