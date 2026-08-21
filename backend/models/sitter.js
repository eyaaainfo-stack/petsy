const mongoose = require('mongoose');
const User = require('./user');

// 🔵 ZID: el 7ou9oul el jdad (services, residence, transportation, pet
// tel sitter) - kanou na9sin khaless, l'écrans Flutter (create_sitter_
// profile.dart / create_sitter_profile_2.dart) kanou "yban bark" (UI
// bla appel API 7a9i9i). Tawa nkhazzenhom fel Sitter document.
const sitterServiceSchema = new mongoose.Schema(
  {
    serviceId: { type: String, required: true }, // mathalan 'house_sitting', 'dog_walking'...
    price: { type: Number, required: true },
    petType: { type: String, enum: ['cat', 'dog', 'both'], required: true },
  },
  { _id: false }
);

const Sitter = User.discriminator(
  'sitter',
  new mongoose.Schema({
    bio: { type: String, default: '' },
    hourlyRate: { type: Number, default: 0 },
    isAvailable: { type: Boolean, default: true },
    // 🔵 ZID: écran "create_sitter_profile.dart" (services + prix + pet type)
    services: { type: [sitterServiceSchema], default: [] },
    // 🔵 ZID: écran "create_sitter_profile_2.dart" (home & transport)
    residenceType: { type: String, enum: ['apartment', 'house', 'countryHouse'], default: null },
    hasTransportation: { type: Boolean, default: null },
    hasPetAtHome: { type: Boolean, default: null },
    ownedPetTypes: { type: [String], default: [] }, // 'dog' / 'cat'
    // Ajoute les autres attributs spécifiques du Sitter selon ton diagramme de classe
  })
);

module.exports = Sitter;