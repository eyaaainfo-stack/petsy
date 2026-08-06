// models/Courier.js
const mongoose = require('mongoose');
const User = require('./user');

const Courier = User.discriminator(
  'courier',
  new mongoose.Schema({
    vehicleType: { type: String, default: '' },
  })
);

module.exports = Courier;