const mongoose = require('mongoose');
const User = require('./user');

const Admin = User.discriminator(
  'admin',
  new mongoose.Schema({
    // Ajoute ici des attributs spécifiques à l'Admin si ton diagramme en a, sinon laisse vide
  })
);

module.exports = Admin;