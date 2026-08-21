// controllers/authController.js
const User = require('../models/user');
const Owner = require('../models/owner');
const Sitter = require('../models/sitter');
const Courier = require('../models/courier');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// ==========================================
// 1. LOGIN (Mo-waḥḥad lil-acteurs el-koll)
// ==========================================
exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // 1. Check user b-email (Admin, Owner, Sitter, walla Courier)
    // 🔵 .select('+password') LEZEM tzid ba3d ma 7attait select:false
    // fel schema - bla ha, user.password ykoun undefined houni.
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    // 2. Verifi password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }

    // 3. Taʿmel Token fīh id w role
    // 🔵 7ithneha el fallback 'supersecretkey' - kan khatir: lowkan
    // .env ma yet7amlech, kol token yetsawwar b'secret ma3roufa
    // 3al mala (mawjouda fel code nafsou 3al GitHub mumkin).
    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // 4. Trajjaʿ el-data lil-Front
    res.status(200).json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        phone: user.phone,
        role: user.role, // <-- Hna el-Front-end yaʿref el-role (admin/owner/sitter/courier)
        // 🔴 FIX: kanou na9sin - el front (ProfileOwnerScreen) yesta3melhom
        // direct ba3d login (city fel header, photoUrl fel photo tel owner)
        // w kanou dima undefined/null 7atta lowkan el user 3andou photo
        // mzouda fel base.
        city: user.city,
        photoUrl: user.photoUrl,
      },
    });
  } catch (error) {
    // 🔵 ZID: console.error kan NA9ES - lowkan sar error 7a9i9i, kan
    // ma yban 7ata fel terminal (el front ye5od 500 bess, el backend
    // "yeskot"). Tawa lazem yban.
    console.error('❌ LOGIN ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// ==========================================
// 2. REGISTER (Lil-Owner, Sitter, Courier)
// ==========================================
exports.register = async (req, res) => {
  // 🔵 ZID: timing bel millisecondes - bch nchoufou b'a3yonna WIN
  // bالضبط el wa9t ye5dhou (bcrypt? MongoDB save? jwt?).
  const startTime = Date.now();
  console.log(`\n🟡 [REGISTER] Bda - ${new Date().toISOString()}`);

  try {
    const { email, password, fullName, phone, role, ...otherData } = req.body;
    console.log(`🟡 [REGISTER] Body me9raya (${Date.now() - startTime}ms) - email: ${email}, role: ${role}`);

    // Check user déjà mawjūd walla lā
    const existingUser = await User.findOne({ email });
    console.log(`🟡 [REGISTER] Check existingUser khlas (${Date.now() - startTime}ms) - mawjoud: ${!!existingUser}`);

    if (existingUser) {
      console.log(`🟡 [REGISTER] Rjaana 400 (email already exists) - (${Date.now() - startTime}ms)\n`);
      return res.status(400).json({ message: 'Email already exists' });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);
    console.log(`🟡 [REGISTER] bcrypt.hash khlas (${Date.now() - startTime}ms)`);

    let newUser;
    const userData = {
      email,
      password: hashedPassword,
      fullName,
      phone,
      ...otherData,
    };

    // Discriminator selection
    switch (role) {
      case 'owner':
        newUser = new Owner(userData);
        break;
      case 'sitter':
        newUser = new Sitter(userData);
        break;
      case 'courier':
        newUser = new Courier(userData);
        break;
      default:
        console.log(`🟡 [REGISTER] Rjaana 400 (invalid role) - (${Date.now() - startTime}ms)\n`);
        return res.status(400).json({ message: 'Invalid role for registration' });
    }

    await newUser.save();
    console.log(`🟡 [REGISTER] newUser.save() khlas (${Date.now() - startTime}ms) - _id: ${newUser._id}`);

    // 🔵 ZID: token mel register zadit (kifha kif el login) - bch el
    // app tnajjam testa3mel el routes "protégées" (update profile...)
    // MBACHER ba3d el signup, bla ma te7taj écran login mnfassel.
    const token = jwt.sign(
      { userId: newUser._id, role: newUser.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );
    console.log(`🟡 [REGISTER] jwt.sign khlas (${Date.now() - startTime}ms)`);

    // 🔵 sa77e7t houni: kan yeb3ath "newUser" el kol (fih el password
    // mhashi) lel front - bnina object jdid b'el 7ou9oul el amnin bess,
    // nafs el mant9 elli fel "login" (fou9).
    res.status(201).json({
      message: 'Account created successfully',
      token,
      user: {
        id: newUser._id,
        email: newUser.email,
        fullName: newUser.fullName,
        phone: newUser.phone,
        role: newUser.role,
      },
    });
    console.log(`✅ [REGISTER] res.status(201) mba3atha (${Date.now() - startTime}ms) - KHLAS\n`);
  } catch (error) {
    // 🔵 ZID: console.error kan NA9ES houni zeda - hedhi el ghalta
    // el kbira, ki fama error 7a9i9i (mathalan validation error),
    // kan yeb3ath 500 lel front bess bla ma yban 7ata 7aja fel
    // terminal. Tawa lازem yban kaملou (message + stack).
    console.error(`❌ [REGISTER] ERROR ba3d ${Date.now() - startTime}ms:`, error);
    res.status(500).json({ error: error.message });
  }
};