const mongoose = require('mongoose');
const User = require('./user');

// 🔵 ZID: el 7ou9oul el jdad (services, residence, transportation, pet
// tel sitter) - kanou na9sin khaless, l'écrans Flutter (create_sitter_
// profile.dart / create_sitter_profile_2.dart) kanou "yban bark" (UI
// bla appel API 7a9i9i). Tawa nkhazzenhom fel Sitter document.
const sitterServiceSchema = new mongoose.Schema(
  {
    serviceId: { type: String, required: true }, // mathalan 'grooming_full_bath', 'walking_daily_walk', 'custom'...
    price: { type: Number, required: true },
    petType: { type: String, enum: ['cat', 'dog', 'both'], required: true },
    // 🔵 ZID (kifma tlab: "ken yhb yzid service ekher") - esm el service
    // "Autre" (custom, serviceId === 'custom') - el sitter kteb b ydik
    // (chraht fel frontend, models/sitter_service_catalog.dart).
    customLabel: { type: String, default: null },
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
    // 🔵 ZID (kifma tlab): "disponibilité" - ayemet el sitter MA
    // yekhdemch fihom.
    // - recurringDaysOff: ayemet fixa fel jom3a (1=Mon...7=Sun, nafs
    //   convention DateTime.weekday el Flutter/sitter_calender.dart).
    // - specificDatesOff: dates mo7addda (a3yed, jours fériés, wela
    //   ayemet zadhom el sitter b'rou7ou mel calendrier).
    recurringDaysOff: { type: [Number], default: [] },
    specificDatesOff: { type: [Date], default: [] },
    // Ajoute les autres attributs spécifiques du Sitter selon ton diagramme de classe
  })
);

module.exports = Sitter;