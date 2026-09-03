// controllers/adminController.js
const User = require('../models/user');
const Owner = require('../models/owner');
const Sitter = require('../models/sitter');
const Courier = require('../models/courier');
const Admin = require('../models/admin');
const Animal = require('../models/animal');
const Booking = require('../models/booking');
const CheckoutQuestionnaire = require('../models/checkoutQuestionnaire');
const Notification = require('../models/notification');
const bcrypt = require('bcryptjs');
const { getVerificationSettings, computeChecklist } = require('../services/verificationService');

// ==========================================
// GET STATS (dashboard admin - views/user/admin/admin_statistics.dart)
// ==========================================
// 🔵 ZID: route protégée (protect + isAdmin, chrahtha fel adminRoutes.js)
// - terja3 3adad kbir/counts 3ala kol chay behdha el app (owners, sitters,
// pets, bookings b'el status tou3hom, w el moyenne rating mel
// questionnaires "completed"). Kol chay b'Promise.all bch el appels el
// 5amsa/setta yesiro fi nefs el wa9t (mch wa7ed ba3d l'okhor - a سرع).
// ==========================================
exports.getStats = async (req, res) => {
  try {
    const [
      totalOwners,
      totalSitters,
      totalCouriers,
      totalAdmins,
      totalPets,
      totalBookings,
      bookingsByStatusRaw,
      ratingAgg,
    ] = await Promise.all([
      User.countDocuments({ role: 'owner' }),
      User.countDocuments({ role: 'sitter' }),
      User.countDocuments({ role: 'courier' }),
      User.countDocuments({ role: 'admin' }),
      Animal.countDocuments(),
      Booking.countDocuments(),
      Booking.aggregate([{ $group: { _id: '$status', count: { $sum: 1 } } }]),
      CheckoutQuestionnaire.aggregate([
        { $match: { status: 'completed', averageRating: { $ne: null } } },
        { $group: { _id: null, avg: { $avg: '$averageRating' }, count: { $sum: 1 } } },
      ]),
    ]);

    // 🔵 el aggregate tel status yerja3 ghir el status elli 3andhom
    // documents 7a9i9iyin (mathalan lowkan mafamech "rejected" 7atta
    // wa7ed, ma yrja3ch fel liste) - fa nbniw object b'el 5 status el
    // kol=0 el bidaya, mba3d n3amrouh mel résultat.
    const bookingsByStatus = {
      pending: 0,
      accepted: 0,
      rejected: 0,
      open: 0,
      awaiting_confirmation: 0,
    };
    bookingsByStatusRaw.forEach((row) => {
      if (row._id in bookingsByStatus) bookingsByStatus[row._id] = row.count;
    });

    const averageRating = ratingAgg.length > 0 ? ratingAgg[0].avg : null;
    const totalReviews = ratingAgg.length > 0 ? ratingAgg[0].count : 0;

    res.status(200).json({
      totalUsers: totalOwners + totalSitters + totalCouriers + totalAdmins,
      totalOwners,
      totalSitters,
      totalCouriers,
      totalAdmins,
      totalPets,
      totalBookings,
      bookingsByStatus,
      // 🔵 mdawra l'chiffre wa7ed ba3d el fasla (4.666... -> 4.7)
      averageRating: averageRating !== null ? Math.round(averageRating * 10) / 10 : null,
      totalReviews,
    });
  } catch (error) {
    console.error('❌ ADMIN-STATS ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// ==========================================
// GET MONTHLY REGISTRATIONS (Tableau de bord - views/user/admin/admin_dashboard.dart)
// ==========================================
// 🔵 ZID: "Graphique linéaire (Line Chart) - lel users lkol + owners +
// sitters + couriers, W el forsa nbadlou el période (1 -> 12 mois)" -
// houni el backend, ye5dem 3ala "createdAt" (User schema fiha
// timestamps:true déjà).
//
// query param: ?months=6 (période - default 6, min 1, max 12, kifma
// tlab - nafs slider el 9dim).
//
// 🔴 FIX (kifma tlab: "nhebbou yetkassem ala 10 ay période takhtarha") -
// kanet GROUP BY (year, month) - meaning 1 mois mekhtar = 1 point BARK
// (chart fadhi/mch behi), w 12 mois = 12 points. Tawa: mch calendar
// months - el période el kol (mel awel lel lekher, ANY duration) met9asma
// 3ala 10 tranches mtsawyin b'jours (mch b'chhour) - dima 10 points,
// ykounou richi zeda ken el période sghira (1 mois = 10 points, mch
// wa7ed) w concis ken el période kbira (12 mois = 10 points zeda, mch
// 12). El bucketing yesir b'JS (mch $group aggregation) 7it el 7doud
// tel tranches mch mrabbta b'7doud echhour - as-hal w awdha7 heka.
// ==========================================
const REGISTRATIONS_CHART_BUCKET_COUNT = 10;

exports.getMonthlyRegistrations = async (req, res) => {
  try {
    let months = parseInt(req.query.months, 10);
    if (!Number.isFinite(months) || months < 1) months = 6;
    if (months > 12) months = 12;

    const now = new Date();
    const startDate = new Date(now);
    startDate.setMonth(startDate.getMonth() - months);

    const totalMs = now.getTime() - startDate.getTime();
    const bucketCount = REGISTRATIONS_CHART_BUCKET_COUNT;
    const bucketMs = totalMs / bucketCount;

    // 🔵 ghir role+createdAt (lean) - mafamech lezoum n-jibou el document
    // el kol (password, phone...) bark bch na3ddou.
    const users = await User.find(
      { createdAt: { $gte: startDate, $lte: now } },
      { role: 1, createdAt: 1 }
    ).lean();

    const series = {
      total: new Array(bucketCount).fill(0),
      owner: new Array(bucketCount).fill(0),
      sitter: new Array(bucketCount).fill(0),
      courier: new Array(bucketCount).fill(0),
    };

    // 🔵 label kol tranche = date bidayetha ("YYYY-MM-DD") - el frontend
    // ye-formatiha "DD/MM" (mch "MM/YY" kifma 9bal, 7it tawa el tranches
    // mch mrabbta b'chhour, w9tesh el jour asal men el chher).
    const bucketLabels = [];
    for (let i = 0; i < bucketCount; i += 1) {
      const bucketStart = new Date(startDate.getTime() + i * bucketMs);
      bucketLabels.push(bucketStart.toISOString().slice(0, 10));
    }

    users.forEach((u) => {
      const createdAtMs = new Date(u.createdAt).getTime();
      let idx = Math.floor((createdAtMs - startDate.getTime()) / bucketMs);
      if (idx < 0) idx = 0;
      if (idx >= bucketCount) idx = bucketCount - 1;
      series.total[idx] += 1;
      // "admin" role ma3andouch série 5assa (mch mel spec) - lakin
      // ye39od fel "total" fou9.
      if (series[u.role]) series[u.role][idx] += 1;
    });

    res.status(200).json({ months: bucketLabels, series });
  } catch (error) {
    console.error('❌ ADMIN-MONTHLY-REGISTRATIONS ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// ==========================================
// Helper: bch nna7iw "password" (w champs techniques) mel document
//9bal ma nab3thouh lel front - testa3mel fel 4 endpoints el jdad taht.
// ==========================================
// 🔵 ZID (kifma tlab: "el admin principale nhbou y39od fixe") -
// "l'admin principal" = el compte admin el A9DAM (createdAt) - el wa7ed
// elli etkha9 mel script createAdmin.js el awel (chraht fel README).
// getPrincipalAdminId() ye5dem 3ala kol el 4 endpoints (list/create/
// update/detail) bch el front ye5fi Modifier/Supprimer 3lih, W el
// backend ye-enforce (mch ghir cosmétique - ken 7ad 7awel appel API
// direct/Postman, el update/delete tel admin principal MARFOUDHIN
// zeda, chouf updateUser/deleteUser taht).
// ==========================================
async function getPrincipalAdminId() {
  const principal = await Admin.findOne().sort({ createdAt: 1 }).select('_id');
  return principal ? principal._id.toString() : null;
}

function toAdminUserJson(user, principalAdminId) {
  return {
    id: user._id,
    email: user.email,
    fullName: user.fullName,
    phone: user.phone,
    // 🔴 FIX (kifma tlab: "el modification eli ynajem yaamlha el admin
    // nhbha hiya bidha eli todhhor fel données mtaa el user") - city w
    // birthday kanou GHIR fel écran détail (getUserDetail) - mch fel
    // liste/create/update. Tawa houni fel helper el markazi (nafs el
    // 4 endpoints el kol el yesta3malouh) - bch el champs elli ynajjam
    // el admin ye3addel ykounou NAFS el champs elli tban fel détail.
    city: user.city,
    birthday: user.birthday,
    role: user.role,
    photoUrl: user.photoUrl,
    createdAt: user.createdAt,
    isPrincipalAdmin: principalAdminId != null && user._id.toString() === principalAdminId,
    // 🔵 ZID (kifma tlab: "acteur vérifié") - badge "Vérifié" fel
    // front (Gestion des comptes + détail).
    isVerified: user.isVerified === true,
    // 🔴 FIX (kifma tlab: "fazet el cin... tjih fenetre... sawae el cin
    // mteek men kodem w men telii") - el USER nafsou yeb3ath el CIN
    // tawa (mch l'admin) - houni READ-ONLY bark (bch l'admin yechouf/
    // yverifiw 9bal ma ye5tar "Valider", mch ynajjam ye3addel).
    cinFrontPhotoUrl: user.cinFrontPhotoUrl || '',
    cinBackPhotoUrl: user.cinBackPhotoUrl || '',
  };
}

// ==========================================
// LIST / SEARCH USERS ("Gestion des comptes" - admin_accounts.dart)
// ==========================================
// 🔵 ZID: kifma tlab - "recherche par nom [w email]" + "wla yjiwni el
// users lkol" (mafamech search/role -> yerja3hom el kol). query params:
//   ?search=xxx   (fullName WALA email, case-insensitive, partiel)
//   ?role=owner   (owner/sitter/courier/admin - "all" walla ghiyeb =
//                  el actors el kol)
// ==========================================
exports.listUsers = async (req, res) => {
  try {
    const { search, role } = req.query;
    const filter = {};

    if (role && role !== 'all') {
      filter.role = role;
    }

    if (search && search.trim()) {
      const regex = new RegExp(search.trim(), 'i');
      filter.$or = [{ fullName: regex }, { email: regex }];
    }

    const [users, principalAdminId] = await Promise.all([
      User.find(filter).sort({ createdAt: -1 }),
      getPrincipalAdminId(),
    ]);

    // 🔵 ZID (kifma tlab: "el admin fi gerer les profil nhebbou dima
    // awl whd") - el comptes admin dima el AWWALIN fel liste (mch 7asb
    // createdAt bark) - Array.sort() f'Node.js stable (ye7fadh l'ordre
    // el asli - createdAt desc - bin el comptes admin b3adhom, w bin
    // el comptes l'okhrin b3adhom).
    users.sort((a, b) => {
      if (a.role === 'admin' && b.role !== 'admin') return -1;
      if (a.role !== 'admin' && b.role === 'admin') return 1;
      return 0;
    });

    res.status(200).json({
      count: users.length,
      users: users.map((u) => toAdminUserJson(u, principalAdminId)),
    });
  } catch (error) {
    console.error('❌ ADMIN-LIST-USERS ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// ==========================================
// CREATE USER (kifma tlab: "poss eni na3mel création de compte")
// ==========================================
// 🔵 ZID: mch kifha kif POST /auth/register (elli yerfudh role="admin"
// 3ammadan, chraht fel authController.js) - houni el Admin ynajjam
// ye5la9 AY role (7ata "admin" 5ir, ken lezmou team kbir) 7it houwa
// déjà authentifié w vérifié isAdmin (middleware).
// ==========================================
exports.createUser = async (req, res) => {
  try {
    const { email, password, fullName, phone, city, birthday, role } = req.body;

    if (!email || !password || !role) {
      return res.status(400).json({ message: 'email, password et role obligatoires' });
    }
    if (password.length < 8) {
      return res.status(400).json({ message: 'Password doit avoir au moins 8 caractères' });
    }

    const normalizedEmail = email.toLowerCase().trim();
    const existing = await User.findOne({ email: normalizedEmail });
    if (existing) {
      return res.status(400).json({ message: 'Email already exists' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const userData = {
      email: normalizedEmail,
      password: hashedPassword,
      fullName: fullName || '',
      phone: phone || '',
      // 🔴 FIX (rappel: "el modification... nhbha hiya bidha eli
      // todhhor fel données mtaa el user") - city/birthday tawa
      // disponibles zeda dès el création (mch ghir modification).
      city: city || '',
      birthday: birthday || '',
      // 🔵 ZID (kifma tlab: "idha el creation du compte n'esy pas finis
      // ma yetsajelch el compte") - el comptes elli l'admin ye5la9hom
      // mel "Gestion des comptes" (formulaire wa7ed, mch parcours
      // mnfassel) ykounou "complets" MEL AWEL - el cleanup job (chraht
      // fel server.js) ma yemsa7homch b'ghalta.
      isProfileComplete: true,
    };

    let newUser;
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
      case 'admin':
        newUser = new Admin(userData);
        break;
      default:
        return res.status(400).json({ message: 'Invalid role' });
    }

    await newUser.save();

    // 🔵 el compte el jdid mch ynajjam ykoun "principal" (déjà fama
    // wa7ed a9dam minou - ken mch fama 7ata admin 9bal, houwa el awel
    // W bidhet ye39od "principal" automatique mel MARRA el jjaya).
    const principalAdminId = await getPrincipalAdminId();
    res.status(201).json({ user: toAdminUserJson(newUser, principalAdminId) });
  } catch (error) {
    console.error('❌ ADMIN-CREATE-USER ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// ==========================================
// UPDATE USER (fullName/phone/email/city/birthday/password - mch "role")
// ==========================================
// 🔵 ZID: 3ammadan 5allina "role" barra el update - el discriminator
// key ('role') fel MongoDB mch loji9i tbeddlou b'update 3adi (el
// 7ou9oul el 5assa b'kol discriminator "owner"/"sitter"/"courier" mch
// nefshom - update 3al 7ki ynajjam ye5alli data mte3lla9a/inconsistante).
// Ken el Admin ghalet fel role ki 5la9 el compte, el a7sen ye7ذfou
// w ye5la9 wa7ed jdid.
//
// 🔴 GUARD (kifma tlab: "el admin principale nhbou y39od fixe") - el
// compte admin principal (el a9dam) MARFOUDH y-update (403) - hedhi
// enforcement 7a9i9i (mch ghir UI/cosmétique, ken 7ad appel l'API
// direct/Postman zeda marfoudh).
// ==========================================
exports.updateUser = async (req, res) => {
  try {
    const { id } = req.params;
    const { fullName, phone, email, city, birthday, password } = req.body;

    const principalAdminId = await getPrincipalAdminId();
    if (id === principalAdminId) {
      return res.status(403).json({ message: 'The principal admin account cannot be modified' });
    }

    const updates = {};
    if (fullName !== undefined) updates.fullName = fullName;
    if (phone !== undefined) updates.phone = phone;
    // 🔴 FIX (kifma tlab): city/birthday tawa modifiables zeda (kanou
    // ghir affichés fel écran détail, mch modifiables - tawa "les
    // champs modifiables = les champs affichés", nafs l'idée).
    if (city !== undefined) updates.city = city;
    if (birthday !== undefined) updates.birthday = birthday;

    // 🔵 ZID (kifma tlab: "les données mtaa el admin nom mail w mdp
    // num telephone w ville") - password optionnel (fadhi = ma yet-
    // beddelch) - el user ye5tar y-reset password ken lezمou bark.
    if (password !== undefined && password.trim() !== '') {
      if (password.length < 8) {
        return res.status(400).json({ message: 'Password doit avoir au moins 8 caractères' });
      }
      updates.password = await bcrypt.hash(password, 10);
    }

    if (email !== undefined) {
      const normalizedEmail = email.toLowerCase().trim();
      const existing = await User.findOne({ email: normalizedEmail, _id: { $ne: id } });
      if (existing) {
        return res.status(400).json({ message: 'Email already exists' });
      }
      updates.email = normalizedEmail;
    }

    const updatedUser = await User.findByIdAndUpdate(id, updates, {
      new: true,
      runValidators: true,
    });
    if (!updatedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({ user: toAdminUserJson(updatedUser, principalAdminId) });
  } catch (error) {
    console.error('❌ ADMIN-UPDATE-USER ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// ==========================================
// DELETE USER
// ==========================================
// 🔵 ZID: User.findByIdAndDelete() = findOneAndDelete taht - ye39ad el
// hook mawjoud déjà fel models/user.js (cascade delete: ken el compte
// "owner", el pets (Animal) tou3ou yetfassa5ou automatique zeda).
//
// 🔵 guard 1: el Admin ma ynajjamch ye7ذef COMPTOU EL NAFSOU (bch ma
// yel9āch rou7ou barra el session f'nofs el 5edma - "lockout" 5atir).
// 🔴 guard 2 (kifma tlab): el admin principal MARFOUDH ye7ذef zeda -
// enforcement 7a9i9i (mch ghir UI).
// ==========================================
exports.deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    if (id === req.userId) {
      return res.status(400).json({ message: "You can't delete your own account" });
    }

    const principalAdminId = await getPrincipalAdminId();
    if (id === principalAdminId) {
      return res.status(403).json({ message: "You can't delete the principal admin account" });
    }

    const deletedUser = await User.findByIdAndDelete(id);
    if (!deletedUser) {
      return res.status(404).json({ message: 'User not found' });
    }

    res.status(200).json({ message: 'User deleted', id });
  } catch (error) {
    console.error('❌ ADMIN-DELETE-USER ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// ==========================================
// LIST REVIEWS ("Avis" - admin_reviews.dart)
// ==========================================
// 🔵 ZID: kifma tlab - "bouton ekher esmou avis" (m3a Statistics/
// Gestion des comptes) - houni el backend, kol el "avis" (reviews)
// completed fel app el kol (mch per user, kifha kif getUserReviews
// fel userController.js - houni VUE GLOBALE lel Admin).
//
// 🔴 FIX (kifma tlab: "nhb les réponses ala el questionnaire lkol, mch
// ken l avis") - kanet el filtre {averageRating: {$ne: null}} yestebad
// el questionnaires el kol elli ma wselouch l'étape 4 (rating/avis) -
// mathalan "service_not_done" (el service 3ammadan ma sarch, w khlas -
// mafamech avis 7atta) wla "awaiting_new_checkout" (mazelhom fel loop
// tel délais). Tawa: kol el questionnaires (4 étapes el kol: service/
// checkout/paiement/satisfaction) - el front ye5tar kifeh ywarrihom
// (chraht fel admin_reviews.dart).
//
// query param: ?search=xxx (esm el reviewer WALA reviewee, partiel)
// ==========================================
exports.listReviews = async (req, res) => {
  try {
    const { search } = req.query;

    const reviews = await CheckoutQuestionnaire.find({})
      .sort({ createdAt: -1 })
      .populate('respondent', 'fullName photoUrl role')
      .populate('reviewee', 'fullName photoUrl role')
      .limit(200);

    // 🔵 ZID (kifma tlab): "ken el owner w el sitter jewbou aks
    // ba3dhom fel oui/non tjini en rouge" - lezمna kol el 2 avis (mte3
    // el owner + mte3 el sitter) 3ala NEFS el booking mjem3in, bch
    // nnajjmou n9ablou "satisfied" tou3hom - ngroupiw b'"booking".
    const byBooking = new Map();
    reviews.forEach((r) => {
      const key = r.booking ? r.booking.toString() : null;
      if (!key) return;
      if (!byBooking.has(key)) byBooking.set(key, []);
      byBooking.get(key).push(r);
    });

    let mapped = reviews.map((r) => {
      const key = r.booking ? r.booking.toString() : null;
      const siblings = key ? byBooking.get(key) : [];
      // 🔵 "conflit" = el 2 tarfin (owner+sitter) jewbou 3ala NEFS el
      // booking, W satisfied mte3hom MO5TALEF (wa7ed "oui" wel akhor
      // "non"). Automatique false ken wa7ed mel 2 mazel ma wselech
      // l'étape 4 (satisfied null) - mafamech conflit ynajjam yban.
      const hasConflict =
        siblings.length === 2 &&
        siblings[0].satisfied != null &&
        siblings[1].satisfied != null &&
        siblings[0].satisfied !== siblings[1].satisfied;

      // 🔵 ZID (kifma tlab: "kif nenzel ala 1 yjini les réponses ala
      // el questionnaire de les deux, kifkif ou kan") - el "sibling" =
      // el avis el AKHER (l'autre partie) 3ala NEFS el booking - bch
      // el front ynajjam ywarri el 2 réponses mjem3in fi nefs el
      // détail, TOUJOURS (mch ghir ken conflit).
      const siblingDoc = siblings.find((s) => s._id.toString() !== r._id.toString()) || null;
      const siblingReview = siblingDoc
        ? {
            reviewerName: siblingDoc.respondent?.fullName || '',
            reviewerPhotoUrl: siblingDoc.respondent?.photoUrl || '',
            reviewerRole: siblingDoc.respondent?.role || '',
            status: siblingDoc.status,
            serviceDone: siblingDoc.serviceDone,
            serviceDoneReason: siblingDoc.serviceDoneReason,
            checkoutDone: siblingDoc.checkoutDone,
            paymentDone: siblingDoc.paymentDone,
            paymentNotDoneReason: siblingDoc.paymentNotDoneReason,
            satisfied: siblingDoc.satisfied,
            ratingTrust: siblingDoc.ratingTrust,
            ratingService: siblingDoc.ratingService,
            ratingCommunication: siblingDoc.ratingCommunication,
            ratingKnowledge: siblingDoc.ratingKnowledge,
            averageRating: siblingDoc.averageRating,
            review: siblingDoc.review,
            createdAt: siblingDoc.createdAt,
          }
        : null;

      return {
        id: r._id,
        reviewerName: r.respondent?.fullName || '',
        reviewerPhotoUrl: r.respondent?.photoUrl || '',
        reviewerRole: r.respondent?.role || '',
        revieweeName: r.reviewee?.fullName || '',
        revieweePhotoUrl: r.reviewee?.photoUrl || '',
        revieweeRole: r.reviewee?.role || '',
        // 🔵 ZID (kifma tlab): el 3 étapes el oula (service/checkout/
        // paiement) - kanou GHIR fel schema, mch fel réponse.
        status: r.status,
        serviceDone: r.serviceDone,
        serviceDoneReason: r.serviceDoneReason,
        checkoutDone: r.checkoutDone,
        paymentDone: r.paymentDone,
        paymentNotDoneReason: r.paymentNotDoneReason,
        satisfied: r.satisfied,
        ratingTrust: r.ratingTrust,
        ratingService: r.ratingService,
        ratingCommunication: r.ratingCommunication,
        ratingKnowledge: r.ratingKnowledge,
        averageRating: r.averageRating,
        review: r.review,
        createdAt: r.createdAt,
        // 🔵 ZID (kifma tlab): 2 flags bark - el front ye5dhom kifma
        // horesponsable (color rouge) bla ay 7isba/logique zeyda
        // mn jihtou (kifma tlab: "haja sehla, mahiech complique").
        hasConflict,
        isLowRating: typeof r.averageRating === 'number' && r.averageRating < 2,
        siblingReview,
      };
    });

    // 🔵 el "search" (esm el reviewer WALA reviewee) - net9ilha b'JS
    // (mch $match fel query direct) 7it lezمha t-search fel 2 champs
    // MBA3AD el populate (fullName mch mawjoud 9bal el populate).
    if (search && search.trim()) {
      const needle = search.trim().toLowerCase();
      mapped = mapped.filter(
        (r) => r.reviewerName.toLowerCase().includes(needle) || r.revieweeName.toLowerCase().includes(needle)
      );
    }

    res.status(200).json({ reviews: mapped, count: mapped.length });
  } catch (error) {
    console.error('❌ ADMIN-LIST-REVIEWS ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// ==========================================
// GET USER DETAIL ("Utilisateurs" - admin_account_detail.dart)
// ==========================================
// 🔵 ZID: kifma tlab - "ki nenzel 3ala wa7ed mel acteurs [...] esmou
// mail num win yoskon [...] kenou sitter kadeh men service amlou/
// rofdhou [...] kenou owner kdeh 3andou pet/talab/tkbelt/trafdhet".
//
// 🔴 IMPORTANT (limite 7a9i9iya fel data model, mch bug): "refusé" W
// "annulé" (sitter yenni booking déjà accepted) mel 7ala l'a9i9iya
// tel base tetsajjlou b'NAFS el mécanisme (status='rejected' +
// rejectedBy) - Booking schema mafamech status 'cancelled' mnfassel.
// Fa el 7isba houni tjib "Refusées/Annulées" COMBINÉE (mch 2 chiffres
// mnfaslin) - separation 7a9i9iya te7taj tbeddel status model el
// booking el kol (touche plusieurs écrans owner/sitter existants,
// mch ghir el Admin) - mzelt 5arjou 3ammadan mel scope hedhi el marra.
// ==========================================
exports.getUserDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const principalAdminId = await getPrincipalAdminId();
    const result = { user: toAdminUserJson(user, principalAdminId) };
    // 🔵 city/birthday tawa déjà fel toAdminUserJson (helper markazi) -
    // ma3adech me7tejin nzidouhom houni b'rou7hom.

    if (user.role === 'owner') {
      const [petsCount, requestsCount, acceptedCount, refusedCount] = await Promise.all([
        Animal.countDocuments({ owner: id }),
        Booking.countDocuments({ owner: id }),
        Booking.countDocuments({ owner: id, status: 'accepted' }),
        Booking.countDocuments({ owner: id, status: 'rejected' }),
      ]);
      result.ownerStats = { petsCount, requestsCount, acceptedCount, refusedCount };
    }

    if (user.role === 'sitter') {
      // 🔵 "rejectedBy" = source unique w fiable lel refus/annulation
      // (chraht fou9) - direct-reject, cancel-after-accept, w
      // marketplace-decline el 3 el kol yzidou el sitter fiha, bla
      // risque "double count" (countDocuments ye7seb DOCUMENT, mch
      // entrée fel array).
      const [completedCount, refusedCount] = await Promise.all([
        Booking.countDocuments({ sitter: id, status: 'accepted' }),
        Booking.countDocuments({ rejectedBy: id }),
      ]);
      result.sitterStats = { completedCount, refusedCount };
    }

    res.status(200).json(result);
  } catch (error) {
    console.error('❌ ADMIN-USER-DETAIL ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// ==========================================
// Helper: checklist tel vérification (kifma tlab: "chnouma el
// moukawmet eli lezemhom ykouno andou") - 7asb el role, ken el 7ou9oul
// el kol True, el compte "prêt" (proposition tji lel admin fel écran
// "Validation").
//
// 🔴 FIX (kifma tlab: "zid critères track-record - kadeh services/
// clients/% avis, w khalliha configurable") - el logique el kol tawa
// fel services/verificationService.js (MECHTAREK m3a userController.js
// - écran "Vérification" tel user nafsou, sidebar) - houni ghir
// n3ayطou biha.
// ==========================================

// ==========================================
// GET CHECKLIST (compte wa7ed - admin_account_detail.dart, "à
// vérifier" preview)
// ==========================================
exports.getUserChecklist = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }
    const { items, isComplete } = await computeChecklist(user);
    res.status(200).json({ checklist: items, isComplete, isVerified: user.isVerified === true });
  } catch (error) {
    console.error('❌ ADMIN-GET-CHECKLIST ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// ==========================================
// LIST VALIDATIONS ("Validation" - admin_validations.dart)
// ==========================================
// 🔵 ZID: kifma tlab - "wkt el checklist tekmel tjii lel admin
// proposition bch ywalli valider" - kol el comptes (owner/sitter/
// courier, mch verified 3ad) elli el checklist tou3hom KAMLA.
// ==========================================
exports.listValidations = async (req, res) => {
  try {
    const candidates = await User.find({ role: { $in: ['owner', 'sitter', 'courier'] }, isVerified: { $ne: true } });

    const results = [];
    for (const user of candidates) {
      const { items, isComplete } = await computeChecklist(user);
      if (isComplete) {
        results.push({ user: toAdminUserJson(user, null), checklist: items });
      }
    }

    res.status(200).json({ validations: results, count: results.length });
  } catch (error) {
    console.error('❌ ADMIN-LIST-VALIDATIONS ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// ==========================================
// VERIFY / UNVERIFY USER
// ==========================================
// 🔵 ZID: el bouton "Valider" (écran Validation) - el admin bark
// ynajjam ye5tar, W el backend ye-revérifie el checklist (mch ghir el
// front) 9bal ma yaccepti - "proposition" mch "confiance a3ma".
// ==========================================
exports.verifyUser = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findById(id);
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const { isComplete } = await computeChecklist(user);
    if (!isComplete) {
      return res.status(400).json({ message: 'Checklist not complete yet' });
    }

    user.isVerified = true;
    user.verifiedAt = new Date();
    await user.save();

    // 🔵 ZID (kifma tlab: "ywalli el compte verifiee nhb tji lel user
    // ntf") - notification l'user ki l'admin ye5tar "Valider".
    await Notification.create({
      recipient: user._id,
      message: 'Your account has been verified! A blue badge now appears on your profile.',
      type: 'account_verified',
    });

    const principalAdminId = await getPrincipalAdminId();
    res.status(200).json({ user: toAdminUserJson(user, principalAdminId) });
  } catch (error) {
    console.error('❌ ADMIN-VERIFY-USER ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// 🔵 ZID: "annuler" el vérification (erreur, fraude découverte mba3d...)
// - mafamech UI l7in lezmha (bouton mch demandé), lakin endpoint jahez
// bch el feature ma tab9ach "sans retour" ken lezmet.
exports.unverifyUser = async (req, res) => {
  try {
    const { id } = req.params;
    const user = await User.findByIdAndUpdate(id, { isVerified: false, verifiedAt: null }, { new: true });
    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    const principalAdminId = await getPrincipalAdminId();
    res.status(200).json({ user: toAdminUserJson(user, principalAdminId) });
  } catch (error) {
    console.error('❌ ADMIN-UNVERIFY-USER ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

// 🔴 FIX (kifma tlab: "fazet el cin... tsirllk el verification [mel
// user nafsou]") - exports.uploadUserCin (l'admin yeb3ath el CIN 3la
// isem el user) etnaha 3ammadan - tawa POST /users/me/cin
// (userController.js/uploadMyCin, userRoutes.js) - el USER nafsou.

// ==========================================
// GET / UPDATE VERIFICATION SETTINGS (seuils configurables)
// ==========================================
// 🔵 ZID (kifma tlab: "khalli les conditions hedhom yodhhrou 3and el
// admin w ynajem yamlelhom modification") - GET yerja3 el valeurs
// el 7aliyin, PUT ybeddelhom (documenT singleton, chraht fel
// verificationSettings.js model).
// ==========================================
exports.getVerificationSettingsHandler = async (req, res) => {
  try {
    const settings = await getVerificationSettings();
    res.status(200).json({
      sitterMinServices: settings.sitterMinServices,
      sitterMinDistinctClients: settings.sitterMinDistinctClients,
      sitterMinGoodReviewPercent: settings.sitterMinGoodReviewPercent,
      ownerMinServices: settings.ownerMinServices,
      ownerMinGoodReviewPercent: settings.ownerMinGoodReviewPercent,
    });
  } catch (error) {
    console.error('❌ ADMIN-GET-VERIFICATION-SETTINGS ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};

exports.updateVerificationSettingsHandler = async (req, res) => {
  try {
    const {
      sitterMinServices,
      sitterMinDistinctClients,
      sitterMinGoodReviewPercent,
      ownerMinServices,
      ownerMinGoodReviewPercent,
    } = req.body;

    const settings = await getVerificationSettings();

    // 🔵 kol 7a9el optionnel (PATCH-like) - ghir el 7ou9oul elli
    // el admin badel yetbeddlou, el ba39yin ye39dou kifma kanou.
    if (sitterMinServices !== undefined) settings.sitterMinServices = sitterMinServices;
    if (sitterMinDistinctClients !== undefined) settings.sitterMinDistinctClients = sitterMinDistinctClients;
    if (sitterMinGoodReviewPercent !== undefined) settings.sitterMinGoodReviewPercent = sitterMinGoodReviewPercent;
    if (ownerMinServices !== undefined) settings.ownerMinServices = ownerMinServices;
    if (ownerMinGoodReviewPercent !== undefined) settings.ownerMinGoodReviewPercent = ownerMinGoodReviewPercent;

    await settings.save();

    res.status(200).json({
      sitterMinServices: settings.sitterMinServices,
      sitterMinDistinctClients: settings.sitterMinDistinctClients,
      sitterMinGoodReviewPercent: settings.sitterMinGoodReviewPercent,
      ownerMinServices: settings.ownerMinServices,
      ownerMinGoodReviewPercent: settings.ownerMinGoodReviewPercent,
    });
  } catch (error) {
    console.error('❌ ADMIN-UPDATE-VERIFICATION-SETTINGS ERROR:', error);
    res.status(500).json({ error: error.message });
  }
};