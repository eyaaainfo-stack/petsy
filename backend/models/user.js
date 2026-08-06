// models/User.js
const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    email: { 
      type: String, 
      required: [true, 'Email is required'], 
      unique: true 
    },
    password: { 
      type: String, 
      required: [true, 'Password is required'] 
    },
    fullName: { 
      type: String, 
      required: [true, 'Full name is required'] // Obligatoire lil-nās koll (Admin inclued)
    },
    phone: { 
      type: String, 
      required: [true, 'Phone number is required'] // Obligatoire lil-nās koll
    },
  },
  {
    discriminatorKey: 'role',
    collection: 'users',
    timestamps: true,
  }
);

module.exports = mongoose.model('User', userSchema);