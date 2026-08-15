const mongoose = require('mongoose');
const User = require('./user');

const Sitter = User.discriminator(
  'sitter',
  new mongoose.Schema({
    bio: { type: String, default: '' },
    hourlyRate: { type: Number, default: 0 },
    isAvailable: { type: Boolean, default: true },
    // Ajoute les autres attributs spécifiques du Sitter selon ton diagramme de classe
  })
);

module.exports = Sitter;