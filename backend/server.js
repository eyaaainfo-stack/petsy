// server.js
const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const connectDB = require('./config/db');
const authRoutes = require('./routes/authRoutes');
const petRoutes = require('./routes/petRoutes');
const userRoutes = require('./routes/userRoutes');
const bookingRoutes = require('./routes/bookingRoutes');

const app = express();

// 🔵 zdineha: bما إن 7ithna el fallback mte3 JWT_SECRET (kan khatir),
// lezemna net2akkdou belli .env fih JWT_SECRET 9bal ma el server ye5dem
// - fail-fast a7sen men ma server ye5dem w kol login ta3ti erreur ghalta.
if (!process.env.JWT_SECRET) {
  console.error('❌ JWT_SECRET mch mawjouda fel .env - el server ma ynajjamch ye5dem bla ha.');
  process.exit(1);
}

app.use(cors());
app.use(express.json());

// 🔵 ZID: bch el images el mheddin (uploads/pets/...) ynajjmou yet3ardhou
// mel front b'URL direct (mathalan http://localhost:5000/uploads/pets/xxx.jpg)
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Connexion Database
connectDB();

// Endpoints
app.use('/api/auth', authRoutes);
app.use('/api/pets', petRoutes);
app.use('/api/users', userRoutes);
app.use('/api/bookings', bookingRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});