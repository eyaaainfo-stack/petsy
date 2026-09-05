// server.js
const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const connectDB = require('./config/db');
const User = require('./models/user');
const authRoutes = require('./routes/authRoutes');
const petRoutes = require('./routes/petRoutes');
const userRoutes = require('./routes/userRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const adminRoutes = require('./routes/adminRoutes');
// 🔵 ZID (messagerie - kifma tlab: interface kima Messenger)
const conversationRoutes = require('./routes/conversationRoutes');

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
app.use('/api/admin', adminRoutes);
// 🔵 ZID (messagerie - kifma tlab: interface kima Messenger)
app.use('/api/conversations', conversationRoutes);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});

// ==========================================
// CLEANUP: comptes incomplets (kifma tlab: "idha el creation du compte
// n'esy pas finis ma yetsajelch el compte f base de donnes")
// ==========================================
// 🔵 el compte ye5la9 mel signup (email+password bark, "isProfileComplete:
// false") - ken el user ma kammelch el parcours el kol (fullName, pet/
// services...) fi 9adr 2 sa3at, ye7ذef rou7ou automatique - "grace
// period" behya bch el user elli ghir 3andou lag/réseau ما3andouch
// khsara, lakin el comptes el "fantômes" (email+password bla 7aja
// okhra, l'admin 5arjou 3ammadan - createUser/createAdmin.js) ma
// yeb9awch mkadsin l'lel abad.
//
// 🔵 deleteMany() (mch findByIdAndDelete lel kol wa7ed wa7ed) - el
// hooks cascade-delete (models/user.js) ma yetsajlouch m3a deleteMany
// (Mongoose limitation loji9iya) - lakin compte "incomplet" (ma
// kammelch el parcours) mel awel MA3ANDOUCH Animal/Booking mrtabtin
// bih (el pets ytzadou GHIR ba3d el parcours), fa mafamech data
// "orphelina" tetrek mn wara.
const CLEANUP_INTERVAL_MS = 30 * 60 * 1000; // kol 30 minute
const INCOMPLETE_ACCOUNT_GRACE_PERIOD_MS = 2 * 60 * 60 * 1000; // 2 sa3at

setInterval(async () => {
  try {
    const cutoff = new Date(Date.now() - INCOMPLETE_ACCOUNT_GRACE_PERIOD_MS);
    const result = await User.deleteMany({
      isProfileComplete: false,
      role: { $ne: 'admin' },
      createdAt: { $lt: cutoff },
    });
    if (result.deletedCount > 0) {
      console.log(`🧹 Cleanup: ${result.deletedCount} compte(s) incomplet(s) supprimé(s) (parcours d'inscription jamais terminé).`);
    }
  } catch (error) {
    console.error('❌ CLEANUP-INCOMPLETE-ACCOUNTS ERROR:', error);
  }
}, CLEANUP_INTERVAL_MS);