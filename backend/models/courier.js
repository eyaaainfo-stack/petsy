const mongoose = require('mongoose');
// 🔵 rej3ineha: Courier yerith mel User direct (mch mel Sitter) - el
// courier khadmtou (na9el el 7ayawan) mo5tlfa 3an el sitter (yer3aa
// el 7ayawan), fa ma3andouch ma3na ye5dhou nafs el 7ou9oul (bio,
// hourlyRate...).
const User = require('./user');

const Courier = User.discriminator(
  'courier',
  new mongoose.Schema({
    vehicleType: { type: String, default: '' },
    // Ajoute les autres attributs spécifiques du Courier selon ton diagramme de classe
  })
);

module.exports = Courier;