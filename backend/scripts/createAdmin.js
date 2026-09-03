// scripts/createAdmin.js
//
// ============================================================================
// Kifech nesta3mlouh (comment l'utiliser)
// ============================================================================
// 🔵 El route POST /auth/register (authController.js) tarfudh el role
// "admin" 3ammadan ('default: return 400 Invalid role for registration')
// - mch bug, 3ammadan heka bnyet: mch loji9i ay wa7ed ynajjam ye5tar
// "Admin" mel signup el 3adi w yemchi. El seul tari9a bch ykhla9 compte
// admin houwa el script hedha (yestaghel direct 3al base, barra el app).
//
// Testa3melha (mel terminal, jowa "backend/"):
//
//   node scripts/createAdmin.js "admin@petsy.com" "MotDePasse123" "Admin Petsy"
//
// El 3 arguments:
//   1) email      (obligatoire)
//   2) password   (obligatoire - 3ala l'a9al 8 caractères)
//   3) fullName   (optionnel - "Admin" b'default lowkan ma7otithch)
//
// Lowkan fama déjà admin b'nefs el email, el script ma ye5la9ch wa7ed
// jdid (ma yfaسedch/yekteb fou9 el 9dim) - ghir ywarri message w yo5roj.
// ============================================================================

require('dotenv').config();
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const Admin = require('../models/admin');

async function main() {
  const [, , email, password, fullNameArg] = process.argv;

  if (!email || !password) {
    console.error('❌ Usage: node scripts/createAdmin.js <email> <password> [fullName]');
    process.exit(1);
  }

  if (password.length < 8) {
    console.error("❌ El password lezemha 3ala l'a9al 8 caractères.");
    process.exit(1);
  }

  if (!process.env.MONGO_URI) {
    console.error('❌ MONGO_URI mch mawjouda fel .env.');
    process.exit(1);
  }

  await mongoose.connect(process.env.MONGO_URI);
  console.log('✅ Connecté lel MongoDB.');

  try {
    const existing = await Admin.findOne({ email: email.toLowerCase().trim() });
    if (existing) {
      console.log(`⚠️  Fama déjà compte b'el email "${email}" (role: ${existing.role}) - ma khla9tech wa7ed jdid.`);
      return;
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const admin = new Admin({
      email: email.toLowerCase().trim(),
      password: hashedPassword,
      fullName: fullNameArg || 'Admin',
      // 🔵 ZID (kifma tlab: "idha el creation du compte n'esy pas
      // finis ma yetsajelch el compte") - script CLI, mafamech
      // "parcours mnfassel" - complet mel awel (cleanup job, server.js).
      isProfileComplete: true,
    });

    await admin.save();
    console.log('✅ Compte admin etkhala9 b\'najja7:');
    console.log(`   email: ${admin.email}`);
    console.log(`   id:    ${admin._id}`);
    console.log('\nTawa tنجم ted5el bih mel AdminLoginView fel app.');
  } finally {
    await mongoose.disconnect();
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ ERROR:', error);
    process.exit(1);
  });