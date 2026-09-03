// controllers/authController.js
const User = require('../models/user');
const Owner = require('../models/owner');
const Sitter = require('../models/sitter');
const Courier = require('../models/courier');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');

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
        // 🔵 ZID (kifma tlab: "el tick... fel home fel pdp mteou") -
        // bch el badge yban direct ba3d login (mch ghir ba3d
        // session-restore mel splash_decider.dart).
        isVerified: user.isVerified === true,
        // 🔵 ZID (kifma tlab: "ken el user homme nkhalliwh vert, keno
        // femme pink") - couleur el sidebar 7asb el gender.
        gender: user.gender,
        // 🔵 ZID (kifma tlab: "idha el creation du compte mch fini ma
        // yethallich el home") - el front (user_login.dart) yestenna
        // 3ala hedha bch ye5tar ykhalliه ykammel el signup, mch home.
        isProfileComplete: user.isProfileComplete === true,
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

// ==========================================
// 3. FORGOT PASSWORD (mdp_oublier_1/2/3.dart) - 3 khtawet
// ==========================================

// 🔵 3a-1: el user yekteb el email -> nchekkou mawjoud W men NEFS
// el role (kifma tlab: "mch ydakhal mail mta3 sitter fel account
// type owner") -> ken sa7i7, ن3امро code (5 ra9mat) + n"eb3thouh"
// (console.log houni - mafamech service email 7a9i9i mrakez tawa,
// TODO lel production).
exports.forgotPassword = async (req, res) => {
  try {
    const { email, role } = req.body;

    if (!email || !role) {
      return res.status(400).json({ message: 'Email and role are required' });
    }

    // 🔴 IMPORTANT: {email, role} f nefs el filter - hedhi bidhabt elli
    // t7a99e9 "el mail lezem ykoun mta3 el account type heka bدأت".
    const user = await User.findOne({ email, role });
    if (!user) {
      // 🔵 message 3am (mch "email exists lakin role mch sa7i7" bل
      // exemple) - bch ma nzidouch info l'ay wa7ed ye5tabar b'iha
      // (security: email enumeration).
      return res.status(404).json({ message: 'No account found with this email for this account type' });
    }

    const code = Math.floor(10000 + Math.random() * 90000).toString(); // 5 ra9mat
    user.passwordResetCode = code;
    user.passwordResetCodeExpiry = new Date(Date.now() + 5 * 60 * 1000); // 5 dqi9a
    await user.save({ validateBeforeSave: false });

    // 🔴 TODO: appel service email 7a9i9i (mathalan nodemailer/SendGrid)
    // - mazel mch mrakez, fa n7ottou el code fel terminal bark (bch
    // tenjjam tjarreb el flow kaملou tawa bla email 7a9i9i).
    console.log(`\n📧 [FORGOT-PASSWORD] Code el verification lel "${email}" (role: ${role}): ${code} (yesse7 5 d9ay9)\n`);

    res.status(200).json({ message: 'Verification code sent' });
  } catch (error) {
    console.error('❌ FORGOT-PASSWORD ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// 🔵 3a-2: el user yekteb el code (5 ra9mat) -> nchekkou sa7i7 W
// mazel s7i9 (5 d9ay9 ma 3addouch) -> ken sa7i7, n3amrou "resetToken"
// mo2a99at (bch el écran el jay - "Set New Password" - ynajjam
// ye5dem bla ma el user y3awad ye5tar el code mel jdid).
exports.verifyPasswordResetCode = async (req, res) => {
  try {
    const { email, code } = req.body;

    const user = await User.findOne({ email }).select('+passwordResetCode +passwordResetCodeExpiry');
    if (!user || !user.passwordResetCode) {
      return res.status(400).json({ message: 'Invalid or expired code' });
    }

    if (user.passwordResetCode !== code) {
      return res.status(400).json({ message: 'Invalid code' });
    }

    if (!user.passwordResetCodeExpiry || user.passwordResetCodeExpiry < new Date()) {
      return res.status(400).json({ message: 'Code expired' });
    }

    // el code sa7i7 - n3amrou token mo2a99at (15 d9i9a), n7ayyدou el
    // code (single-use, ma yetsta3malch marra okhra).
    const resetToken = crypto.randomBytes(32).toString('hex');
    user.passwordResetToken = resetToken;
    user.passwordResetTokenExpiry = new Date(Date.now() + 15 * 60 * 1000);
    user.passwordResetCode = null;
    user.passwordResetCodeExpiry = null;
    await user.save({ validateBeforeSave: false });

    res.status(200).json({ message: 'Code verified', resetToken });
  } catch (error) {
    console.error('❌ VERIFY-RESET-CODE ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// 🔵 3a-3: el user yekteb password jdid (+ confirmation, el front
// ye7e99e9 el zoùj kif kif 9bal el appel) -> nchekkou el resetToken
// (mel écran el 9bali) sa7i7 W mazel s7i9 -> nbaddlou el password.
exports.resetPassword = async (req, res) => {
  try {
    const { email, resetToken, newPassword } = req.body;

    const user = await User.findOne({ email }).select('+passwordResetToken +passwordResetTokenExpiry');
    if (!user || !user.passwordResetToken) {
      return res.status(400).json({ message: 'Invalid or expired reset session' });
    }

    if (user.passwordResetToken !== resetToken) {
      return res.status(400).json({ message: 'Invalid reset session' });
    }

    if (!user.passwordResetTokenExpiry || user.passwordResetTokenExpiry < new Date()) {
      return res.status(400).json({ message: 'Reset session expired' });
    }

    user.password = await bcrypt.hash(newPassword, 10);
    user.passwordResetToken = null;
    user.passwordResetTokenExpiry = null;
    await user.save();

    res.status(200).json({ message: 'Password reset successfully' });
  } catch (error) {
    console.error('❌ RESET-PASSWORD ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};