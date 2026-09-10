// controllers/authController.js
const User = require('../models/user');
const Owner = require('../models/owner');
const Sitter = require('../models/sitter');
const Courier = require('../models/courier');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
// 🔴 FIX (bug: "compte déjà mawjoud yerja3 lel UserCreateProfileScreen
// bدal ProfileOwnerScreen") - chraht kaملa fel services/onboardingService.js.
const { ensureProfileComplete } = require('../services/onboardingService');
// 🔵 ZID (kifma tlab: "el mails elli nestamlhom mch virtuelle") - email
// 7a9i9i (SMTP), badalna el console.log el TODO 9dim.
const { sendEmail } = require('../services/emailService');

// 🔵 ZID (kifma tlab: "el email ykoun réellement mawjoud - vérification
// bloquante") - nafs mant9 "code 5 ra9mat" tel forgot-password, ghir
// houni l'confirmation el email nafsou (mch reset password).
function buildVerificationEmail(code) {
  return {
    subject: 'Petsy - Confirmez votre e-mail',
    text: `Votre code de vérification Petsy est : ${code}\n\nCe code expire dans 15 minutes.`,
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px;">
        <h2 style="color: #EC407A;">Petsy</h2>
        <p>Bienvenue ! Voici votre code pour confirmer votre e-mail :</p>
        <p style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #EC407A; text-align: center; padding: 16px 0;">${code}</p>
        <p style="color: #888;">Ce code expire dans 15 minutes.</p>
      </div>
    `,
  };
}

async function sendVerificationCode(user) {
  const code = Math.floor(10000 + Math.random() * 90000).toString(); // 5 ra9mat
  user.emailVerificationCode = code;
  user.emailVerificationCodeExpiry = new Date(Date.now() + 15 * 60 * 1000); // 15 d9i9a
  await user.save({ validateBeforeSave: false });

  const emailSent = await sendEmail({ to: user.email, ...buildVerificationEmail(code) });
  if (!emailSent) {
    console.log(`\n📧 [VERIFY-EMAIL] (dev fallback) Code el verification lel "${user.email}": ${code} (yesse7 15 d9i9a)\n`);
  }
}

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

    // 🔴 FIX (bug: "compte déjà mawjoud yerja3 lel UserCreateProfileScreen"):
    // nchekkou/nsalliw el flag 9bal ma nab3thouh l'el front (self-heal,
    // chraht fel onboardingService.js).
    const isProfileComplete = await ensureProfileComplete(user);

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
        isProfileComplete,
        // 🔵 ZID (kifma tlab: "el email ykoun réellement mawjoud -
        // vérification bloquante") - "?? true" fel front (mch "?? false")
        // - comptes 9dam (undefined) grandfathered, mch متبلوكيين ghalat.
        isEmailVerified: user.isEmailVerified,
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

    // 🔵 ZID (kifma tlab: "el email ykoun réellement mawjoud - vérification
    // bloquante") - neb3thou code el verification MBACHER (bla ha, el
    // user ynajjam ye39od b email fake w ma yerja3ch abadan yconfirmih).
    await sendVerificationCode(newUser);
    console.log(`🟡 [REGISTER] sendVerificationCode khlas (${Date.now() - startTime}ms)`);

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
        // 🔵 ZID (kifma tlab): "vérification bloquante" - el front
        // (user_signin.dart) yestenna 3ala hedha, dima "false" mbacher
        // ba3d signup (el code mba3outh déjà, chraht fou9).
        isEmailVerified: newUser.isEmailVerified,
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
// type owner") -> ken sa7i7, ن3امро code (5 ra9mat) + neb3thouh
// 7a9i9atan (emailService.js, SMTP) - lowkan mafamech config .env
// mazal, yban fel terminal (dev fallback, chraht fel emailService.js).
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

    // 🔴 FIX (kifma tlab: "el mails elli nestamlhom mch virtuelle") -
    // email 7a9i9i (SMTP, emailService.js) bدal el console.log el TODO
    // el 9dim. Lowkan el .env mazal ma fihech EMAIL_HOST/USER/PASS,
    // sendEmail() rajja3 "false" w ykammel yban fel terminal (dev
    // fallback) - el flow ma yertimch (forgot-password ye5dem dima,
    // 7ata 9bal ma tzid el config SMTP).
    const emailSent = await sendEmail({
      to: email,
      subject: 'Petsy - Code de vérification',
      text: `Votre code de vérification Petsy est : ${code}\n\nCe code expire dans 5 minutes. Si vous n'avez pas demandé cette réinitialisation, ignorez cet e-mail.`,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 24px;">
          <h2 style="color: #EC407A;">Petsy</h2>
          <p>Voici votre code de vérification pour réinitialiser votre mot de passe :</p>
          <p style="font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #EC407A; text-align: center; padding: 16px 0;">${code}</p>
          <p style="color: #888;">Ce code expire dans 5 minutes. Si vous n'avez pas demandé cette réinitialisation, ignorez cet e-mail.</p>
        </div>
      `,
    });
    if (!emailSent) {
      console.log(`\n📧 [FORGOT-PASSWORD] (dev fallback) Code el verification lel "${email}" (role: ${role}): ${code} (yesse7 5 d9ay9)\n`);
    }

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

// ==========================================
// 4. VERIFY EMAIL (kifma tlab: "el email ykoun réellement mawjoud" -
// vérification bloquante ba3d el signup, écran jdid ba3d
// user_signin.dart, 9BAL UserCreateProfileScreen)
// ==========================================
// 🔵 nafs mant9 verifyPasswordResetCode (fou9) - ghir houni "isEmail
// Verified = true" direct (mafamech resetToken mo2a99at, mafamech
// écran ekher yeji ba3dha - "confirmation" bark, mch "reset").
exports.verifyEmail = async (req, res) => {
  try {
    const { email, code } = req.body;

    const user = await User.findOne({ email }).select('+emailVerificationCode +emailVerificationCodeExpiry');
    if (!user || !user.emailVerificationCode) {
      return res.status(400).json({ message: 'Invalid or expired code' });
    }

    if (user.emailVerificationCode !== code) {
      return res.status(400).json({ message: 'Invalid code' });
    }

    if (!user.emailVerificationCodeExpiry || user.emailVerificationCodeExpiry < new Date()) {
      return res.status(400).json({ message: 'Code expired' });
    }

    user.isEmailVerified = true;
    user.emailVerificationCode = null;
    user.emailVerificationCodeExpiry = null;
    await user.save({ validateBeforeSave: false });

    res.status(200).json({ message: 'Email verified' });
  } catch (error) {
    console.error('❌ VERIFY-EMAIL ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// ==========================================
// 5. RESEND VERIFICATION EMAIL (bouton "Resend" fel écran, nafs mant9
// forgotPassword - code jdid, expiry jdida)
// ==========================================
exports.resendVerificationEmail = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'No account found with this email' });
    }

    if (user.isEmailVerified) {
      return res.status(200).json({ message: 'Email already verified' });
    }

    await sendVerificationCode(user);

    res.status(200).json({ message: 'Verification code sent' });
  } catch (error) {
    console.error('❌ RESEND-VERIFICATION-EMAIL ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};