// controllers/authController.js
const User = require('../models/user');
const Owner = require('../models/owner');
const Sitter = require('../models/sitter');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
// 🔴 FIX (bug: "compte déjà mawjoud yerja3 lel UserCreateProfileScreen
// bدal ProfileOwnerScreen") - chraht kaملa fel services/onboardingService.js.
const { ensureProfileComplete } = require('../services/onboardingService');
// 🔵 ZID (kifma tlab: "el mails elli nestamlhom mch virtuelle") - email
// 7a9i9i (SMTP), badalna el console.log el TODO 9dim.
const { sendEmail } = require('../services/emailService');
// 🔵 ZID (kifma tlab: "Continue with Google") - njiw n-verifiw el idToken
// eli el Flutter app yeb3athou (mch nethiklou fih w khalas - lezem
// n-verifiwh m3a Google server-side, bla ha ay 7ad ynajjam yeb3ath
// idToken fake w yedkhol b'esm 7ad okhor).
const { OAuth2Client } = require('google-auth-library');
const googleClient = new OAuth2Client(process.env.GOOGLE_WEB_CLIENT_ID);

// 🔴 FIX (kifma tlab: "nahhili el verification mta3 el email... maneha
// famma code zeyed") - buildVerificationEmail()/sendVerificationCode()
// (w exports.verifyEmail/resendVerificationEmail ta7t, w el routes
// mte3hom fel authRoutes.js) tna77aw - el frontend ma3adech ye3ayet
// bihom (signup ma3adech mandatory yverifi email). "Forgot Password"
// (fou9 fel fichier hedha, forgotPassword/verifyPasswordResetCode/
// resetPassword) mazel intact - flow separate, ma tbeddelch.


// ==========================================
// 1. LOGIN (Mo-waḥḥad lil-acteurs el-koll)
// ==========================================
exports.login = async (req, res) => {
  try {
    const { email, password, role } = req.body;

    // 🔴 FIX (kifma tlab: "el compte mta3 sitter ma ynajemch yet7all
    // ken ma el marra jeya ye5tar account type sitter... mch yhellou
    // men owner par exemple") - {email, role} f nefs el filter, NAFS
    // mant9 forgotPassword (fou9, exports.forgotPassword) - el compte
    // ma yet7allch ken el "account type" el mختار (owner/sitter/courier/
    // admin) mch NAFS role el compte fel base.
    // 🔵 .select('+password') LEZEM tzid ba3d ma 7attait select:false
    // fel schema - bla ha, user.password ykoun undefined houni.
    const user = await User.findOne({ email, role }).select('+password');
    if (!user) {
      // 🔵 message 3am (mch "email exists lakin role mch sa7i7" b
      // exemple) - bch ma nzidouch info l'ay wa7ed ye5tabar b'iha
      // (security: email enumeration) - nafs mant9 forgotPassword.
      return res.status(404).json({ message: 'No account found with this email for this account type' });
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
      default:
        console.log(`🟡 [REGISTER] Rjaana 400 (invalid role) - (${Date.now() - startTime}ms)\n`);
        return res.status(400).json({ message: 'Invalid role for registration' });
    }

    await newUser.save();
    console.log(`🟡 [REGISTER] newUser.save() khlas (${Date.now() - startTime}ms) - _id: ${newUser._id}`);

    // 🔴 FIX (kifma tlab: "nahhili el verification mta3 el email... c
    // pas la peine bch ta3mel verification") - ma3adech neb3thou/
    // ne5tajou code el verification fel signup (el SMTP deja mzabet w
    // el mail 7a9i9i - "isEmailVerified" default true tawa fel model,
    // ma nchekkouhach houni). El code yeb9a esta3mel GHIR fel "Forgot
    // Password" (mdp_oublier_1/2/3.dart) - hedhak flow separate w
    // mazel intact.

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
// 2bis. GOOGLE AUTH ("Continue with Google" - Login WELA Signup)
// ==========================================
// 🔵 ZID (kifma tlab: "continuez avec google, tconnecti automatique kifha
// kif Instagram") - route wa7da testa3mel l'el ZOUZ 7alat:
//  - Email deja mawjoud (compte 3adi WELA google) -> LOGIN (role ma
//    yet7ejjch, na5douh mel base).
//  - Email mch mawjoud -> SIGNUP, ama houni lezمna "role" (owner/sitter/
//    courier) - el front lezem yeb3athou GHIR ki el bouton "Continue
//    with Google" fi écran signup mnfassel bel role (user_signin.dart,
//    eli deja ye39ed "role" kel paramètre). Ken jaya mel écran LOGIN
//    (user_login.dart) w el email mch mawjoud, nra7lou 404-style bch
//    el front yeb3thou lel "choisir role" mel bidaya (kifha kif compte
//    3adi mch mawjoud).
exports.googleAuth = async (req, res) => {
  try {
    const { idToken, role } = req.body;
    if (!idToken) {
      return res.status(400).json({ message: 'idToken manquant' });
    }

    // 1. Verifi el idToken m3a Google (signature + audience + expiry) -
    // ken el token fake wela mnte3 app okhra, hedhi tarmi exception w
    // el catch ta7t yeb3ath 401.
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: process.env.GOOGLE_WEB_CLIENT_ID,
    });
    const payload = ticket.getPayload();
    const { sub: googleId, email, name, picture, email_verified } = payload;

    if (!email_verified) {
      return res.status(400).json({ message: "L'email Google n'est pas vérifié" });
    }

    // 2. Email deja mawjoud? -> LOGIN (bla ma ne7taj role)
    let user = await User.findOne({ email });

    if (user) {
      // Link automatique (compte kan 3adi b'email/password, tawa
      // ye39ed connect b'Google zeda - mch confli9).
      if (!user.googleId) {
        user.googleId = googleId;
      }
      // Google deja verifi el email (email_verified true) - manti9i
      // n7ottou isEmailVerified true, bla ma nestennewh yekteb code.
      if (!user.isEmailVerified) {
        user.isEmailVerified = true;
      }
      if (!user.photoUrl && picture) {
        user.photoUrl = picture;
      }
      await user.save({ validateBeforeSave: false });
    } else {
      // 3. Compte jdid - lezمna role (mel écran signup, mch login)
      if (!role) {
        return res.status(404).json({
          message: 'Aucun compte avec cet e-mail. Veuillez créer un compte.',
          code: 'NO_ACCOUNT',
        });
      }

      const userData = {
        email,
        googleId,
        fullName: name || '',
        photoUrl: picture || '',
        isEmailVerified: true, // Google deja verifi
      };

      switch (role) {
        case 'owner':
          user = new Owner(userData);
          break;
        case 'sitter':
          user = new Sitter(userData);
          break;
        default:
          return res.status(400).json({ message: 'Invalid role for registration' });
      }
      await user.save();
    }

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    const isProfileComplete = await ensureProfileComplete(user);

    res.status(200).json({
      message: 'Google auth successful',
      token,
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        phone: user.phone,
        role: user.role,
        city: user.city,
        photoUrl: user.photoUrl,
        isVerified: user.isVerified === true,
        gender: user.gender,
        isProfileComplete,
        isEmailVerified: user.isEmailVerified,
      },
    });
  } catch (error) {
    console.error('❌ GOOGLE AUTH ERROR:', error);
    res.status(401).json({ message: 'Échec de l\'authentification Google', error: error.message });
  }
};

// ==========================================
// 2ter. FACEBOOK AUTH ("Continue with Facebook" - Login WELA Signup)
// ==========================================
// 🔵 ZID (kifma tlab: "kima emes connexion tsir bel google, tawwa
// nhbha bel fb") - NAFS mant9 exports.googleAuth bالضبط (fou9), ghir
// el verification: Facebook mafamouch "idToken" signé kifha kif Google
// - houni n-verifiw el "accessToken" b'appel direct l'Facebook Graph
// API (/me) - ken el token fake/expired, Facebook yrajja3 erreur.
exports.facebookAuth = async (req, res) => {
  try {
    const { accessToken, role } = req.body;
    if (!accessToken) {
      return res.status(400).json({ message: 'accessToken manquant' });
    }

    // 1. Verifi el accessToken m3a Facebook (njibou el profile fi nafs
    // el appel - id, email, name, picture). Node 18+ 3andou "fetch"
    // global (bla dependency zeyda).
    const fbResponse = await fetch(
      `https://graph.facebook.com/me?fields=id,name,email,picture.type(large)&access_token=${encodeURIComponent(accessToken)}`
    );
    const fbData = await fbResponse.json();
    if (fbData.error) {
      return res.status(401).json({ message: 'Token Facebook invalide', error: fbData.error.message });
    }

    const { id: facebookId, name, email, picture } = fbData;
    // 🔴 IMPORTANT: Facebook ynajjam ma yrجja3ch email (compte bla
    // email verified 3and Facebook nafsou, wela l'user rafedh el
    // permission "email" fel dialog) - el schema/logic el kol mabnia
    // 3al email unique, fa bla email ma nnajmouch ne39dou compte.
    if (!email) {
      return res.status(400).json({ message: "Impossible de récupérer l'e-mail Facebook. Vérifiez les autorisations accordées." });
    }

    // 2. Email deja mawjoud? -> LOGIN (bla ma ne7taj role)
    let user = await User.findOne({ email });

    if (user) {
      if (!user.facebookId) {
        user.facebookId = facebookId;
      }
      if (!user.isEmailVerified) {
        user.isEmailVerified = true;
      }
      if (!user.photoUrl && picture && picture.data && picture.data.url) {
        user.photoUrl = picture.data.url;
      }
      await user.save({ validateBeforeSave: false });
    } else {
      // 3. Compte jdid - lezمna role (mel écran signup, mch login)
      if (!role) {
        return res.status(404).json({
          message: 'Aucun compte avec cet e-mail. Veuillez créer un compte.',
          code: 'NO_ACCOUNT',
        });
      }

      const userData = {
        email,
        facebookId,
        fullName: name || '',
        photoUrl: (picture && picture.data && picture.data.url) || '',
        isEmailVerified: true, // Facebook deja verifi (nafs mant9 Google)
      };

      switch (role) {
        case 'owner':
          user = new Owner(userData);
          break;
        case 'sitter':
          user = new Sitter(userData);
          break;
        default:
          return res.status(400).json({ message: 'Invalid role for registration' });
      }
      await user.save();
    }

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    const isProfileComplete = await ensureProfileComplete(user);

    res.status(200).json({
      message: 'Facebook auth successful',
      token,
      user: {
        id: user._id,
        email: user.email,
        fullName: user.fullName,
        phone: user.phone,
        role: user.role,
        city: user.city,
        photoUrl: user.photoUrl,
        isVerified: user.isVerified === true,
        gender: user.gender,
        isProfileComplete,
        isEmailVerified: user.isEmailVerified,
      },
    });
  } catch (error) {
    console.error('❌ FACEBOOK AUTH ERROR:', error);
    res.status(401).json({ message: 'Échec de l\'authentification Facebook', error: error.message });
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