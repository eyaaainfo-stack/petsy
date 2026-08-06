// models/Admin.js
const User = require('./user');

const Admin = User.discriminator(
  'admin',
  new mongoose.Schema({})
);

module.exports = Admin;