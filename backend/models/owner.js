// models/Owner.js
const mongoose = require('mongoose');
const User = require('./user');

const Owner = User.discriminator(
  'owner',
  new mongoose.Schema({
    address: { type: String, default: '' },
  })
);

module.exports = Owner;