const mongoose = require('mongoose');
const User = require('./user');

const Owner = User.discriminator(
  'owner',
  new mongoose.Schema({
    address: { type: String, default: '' },
    // Ajoute les autres attributs spécifiques de l'Owner selon ton diagramme de classe
  })
);

module.exports = Owner;