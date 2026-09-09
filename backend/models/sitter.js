const mongoose = require('mongoose');
const User = require('./user');

// 🔵 ZID: el 7ou9oul el jdad (services, residence, transportation, pet
// tel sitter) - kanou na9sin khaless, l'écrans Flutter (create_sitter_
// profile.dart / create_sitter_profile_2.dart) kanou "yban bark" (UI
// bla appel API 7a9i9i). Tawa nkhazzenhom fel Sitter document.
// 🔵 ZID (feature "compatibilite entre animaux"): badalna "petType"
// (cat/dog/both) + "price" WA7DA b prix MNFASSEL l'KOL category
// (small_dog/guard_dog/cat) - el sitter ynajjam y7ott price mختلف
// l'kol category (kifma tlab: "guard_dog momken ykoun akther
// expensive"). "prices" fih GHIR el categories elli el sitter 5tarhom
// (acceptedPetCategories, Sitter.acceptedPetCategories).
const servicePriceSchema = new mongoose.Schema(
  {
    category: { type: String, enum: ['small_dog', 'guard_dog', 'cat'], required: true },
    price: { type: Number, required: true },
  },
  { _id: false }
);

const sitterServiceSchema = new mongoose.Schema(
  {
    serviceId: { type: String, required: true }, // mathalan 'grooming_full_bath', 'walking_daily_walk', 'custom'...
    prices: { type: [servicePriceSchema], required: true },
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
    // 🔵 ZID (feature "compatibilite entre animaux"): GHIR el categories
    // (small_dog/guard_dog/cat) elli had sitter ye9bel ye5dem m3ahom -
    // BLA prix houni (el prix el tarif houwa PER-SERVICE, chraht fel
    // sitterServiceSchema.prices fou9 - ye5taj category, mch ye5taj
    // wa7ed flat 3al kol categorie). Ye5tarhom fel inscription (écran 1,
    // create_sitter_profile.dart, 9BAL el services - "Services Offered"
    // ye3taمد 3lihom bch ywarri prix l'kol category). Ken booking
    // mte3ou category MAHOUCH fel liste hedhi, el owner 7atta ma
    // ychoufouch fel recherche/matching.
    acceptedPetCategories: { type: [String], default: [] },
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