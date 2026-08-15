// config/db.js
const mongoose = require('mongoose');
// 🔵 ZID: n7ottou el User houni bch nbniw el indexes tou3ou (w tou3
// Owner/Sitter/Courier/Admin - kolhom nafs el collection "users")
// MBACHER wa9t el connexion.
const User = require('../models/user');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGO_URI);
    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);

    // 🔵 "Model.init()": el fonction el rasmiya tel Mongoose bch tبني
    // el indexes (mathalan "unique: true" 3al email) w testanaha
    // KAMLA 9bal ma el server ybda ye5dem. Bla ha, MongoDB tبني el
    // index 3al document el WA7ED (el request el loula), w hedha
    // ynajjam ye5od wa9t mla77edh w ysabbeb "connection error" mte3
    // el user (el response yت2akhar barcha).
    await User.init();
    console.log('✅ Indexes synced');
  } catch (error) {
    console.error(`❌ DB Error: ${error.message}`);
    // 🔵 rej3ineha: el server ma3nach ye5dem bla database - a7sen
    // yeqef direct (fail-fast) bدل ما ye5dem w kol requête tefchel
    // b'erreur mo5tefa mch mfahma.
    process.exit(1);
  }
};

module.exports = connectDB;