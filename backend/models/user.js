const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    email: { 
      type: String, 
      required: [true, 'Email is required'], 
      unique: true,
      lowercase: true,
      trim: true
    },
    password: { 
      type: String, 
      required: [true, 'Password is required'] 
    },
    // 🔵 badalna: mch required tawa - 7it el flow tel app yesta3mel
    // el email/password fel signup, w el fullName/phone yet3amrou
    // BA3D fi écran mnfassel (UserCreateProfileScreen). Ken lezmek
    // ye5tejou fel écran mte3hom, chek houni b'el code (controller),
    // mch b'el schema.
    fullName: { 
      type: String, 
      default: ''
    },
    phone: { 
      type: String, 
      default: ''
    },
    // 🔵 ZID: photoUrl 3ala mستوى el User el asasi (mch Owner/Sitter
    // wa7dhom) - bفضل el discriminator pattern, el 4 adwar (Admin,
    // Owner, Sitter, Courier) yerthou hedha el 7a9el automatique.
    photoUrl: { type: String, default: '' },
    // 🔴 FIX: kanou na9sin - el front (UserCreateProfileScreen) yekteb
    // fihom (birthday date picker, "About you" textarea) lakin el
    // backend ma3andouch 7ou9oul lihom (TODO mawjoud déjà fel controller
    // Flutter) - fa el data kanet tetzeya3 (ma tetsajjelch 7atta).
    birthday: { type: String, default: '' }, // format "DD/MM/YYYY" (kifma el front yeb3ath)
    bio: { type: String, default: '' }, // "About you" / "About me"
    // 🔵 ZID: field jdid (my_profile_owner.dart/update_profile_owner.dart)
    gender: { type: String, enum: ['male', 'female', ''], default: '' },
    // 🔵 ZID: esm el blasa (reverse-geocoding, mch ghir lat/lng) - my
    // "location" (lat/lng) déjà mawjouda taht, hedhi zeyda text bark.
    locationName: { type: String, default: '' },
    // 🔵 ZID: city (w location - lat/lng, mel map picker) 3ala mستوى
    // el User el asasi - kol el 4 adwar yerthouha. HEDHA el 7a9el
    // elli bch ykhalli el "sitters men nefs el ville" ye5dem 7a9i9i.
    city: { type: String, default: '' },
    location: {
      lat: { type: Number, default: null },
      lng: { type: Number, default: null },
    },
    // 🔵 ZID: "Forgot Password" flow (mdp_oublier_1/2/3.dart) - code el
    // verification (5 ra9mat) + expiry, mba3d token mo2a99at (ba3d ma
    // el code yet2akked, bch el user ynajjam ye5dem "Set New Password"
    // bla ma y3awad ye5tar el code mel jdid). "select: false" - ma
    // yban-ch fel queries el 3adiya (bch ma yetsarrabch bel ghalta).
    passwordResetCode: { type: String, select: false, default: null },
    passwordResetCodeExpiry: { type: Date, select: false, default: null },
    passwordResetToken: { type: String, select: false, default: null },
    passwordResetTokenExpiry: { type: Date, select: false, default: null },
    // 🔵 ZID: "My Favourites" (my_favourites_screen.dart, owner) - liste
    // el sitters elli el owner 3ajbouh (heart icon 3al card).
    favorites: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],

    // 🔵 ZID (kifma tlab: "acteur vérifié - checklist tekmel, tji lel
    // admin proposition bch ywalli valider, w zid CIN") - vérification
    // d'identité: l'admin ynajjam ye5tar "Valider" ghir ken el checklist
    // (chraht fel adminController.js/computeChecklist) kaملa.
    isVerified: { type: Boolean, default: false },
    // 🔵 ZID (kifma tlab: "idha el creation du compte n'esy pas finis
    // ma yetsajelch el compte f base de donnes") - false ki el compte
    // yetkha9 (email+password bark, mel signup), True ghir ki el user
    // ykammel el parcours el kol (fullName, pet/services...) - chraht
    // fel userController.js/completeOnboarding + server.js (cleanup
    // job ye7ذef el comptes elli 9a3dou "false" 3lech mch kammlou).
    isProfileComplete: { type: Boolean, default: false },
    verifiedAt: { type: Date, default: null },
    // 🔵 photo tel CIN (carte d'identité) - RECTO + VERSO (kifma tlab:
    // "sawae el cin mteek men kodem w men telii" - front + back) - tawa
    // el USER nafsou yeb3ath biha (mch l'admin, chraht fel
    // verification_status_screen.dart + userController.js/uploadMyCin).
    cinFrontPhotoUrl: { type: String, default: '' },
    cinBackPhotoUrl: { type: String, default: '' },
  },
  {
    discriminatorKey: 'role', // C'est ici que l'héritage se fait (le champ qui indique le type d'acteur)
    collection: 'users',      // Tous les acteurs vont dans la même table "users"
    timestamps: true,
  }
);

// ============================================================================
// Index "fullName" UNIQUE (kifma tlab: "el esm ykoun unique kima el
// insta") - case-insensitive (collation strength:2 -> "Rami"/"rami"
// nafs 7aja), w "partialFilterExpression" bch el docs elli fullName
// tou3hom mazel fadhi ('', el user 3omrou ma 3adda UserCreateProfile-
// Screen) MA yed5louch fel contrainte unique (bla ha, EL WA7ED bark
// mel signups el jdad ynajjam ye5ou "" - el b39yin kolhom ye7osbou
// "duplicate").
// ============================================================================
userSchema.index(
  { fullName: 1 },
  {
    unique: true,
    collation: { locale: 'en', strength: 2 },
    partialFilterExpression: { fullName: { $type: 'string', $gt: '' } },
  }
);

// ============================================================================
// Cascade delete: Animal ◆-- User (composition, kifma el conception/
// class diagram) - ki el User (owner) yetfassa5, el Animal (pets) tou3ou
// yetfassa5ou automatique zeda.
//
// 🔴 IMPORTANT: hedha "hook" mستوى Mongoose (application) - ye5dem GHIR
// ki el delete ysir MEL KOD (mathalan route future "delete account",
// wela script Node.js yesta3mel el model). Ken ta7ذef document direct
// mel MongoDB Compass/mongo shell (barra el app), el hook hedha MA
// YETFA33ALCH - MongoDB nafsou (NoSQL) ma3andouch "ON DELETE CASCADE"
// native kifha kif SQL, el cascade DIMA lezmha code (houni bark).
//
// 2 hooks (bch yghatou el 2 tri9at el aktar common lel delete):
//  1. "findOneAndDelete" (query middleware) - covers User.findByIdAndDelete()
//     w User.findOneAndDelete() zeda.
//  2. "deleteOne" (document middleware) - covers userInstance.deleteOne()
//     (ki el document mjabed déjà, w ta7ذefou b rou7ou).
// ============================================================================
// 🔴 FIX ("TypeError: next is not a function" - crash 7a9i9i ki el
// admin ye7ذef compte, chrahtha kaملa fel error trace): kanou el 2
// hooks (pre findOneAndDelete + pre deleteOne) declarés "async
// function(next)" - mzoughin bin 2 styles (async/await W callback
// next()) - Mongoose/Kareem ki yel9a el fonction "async", ma yeb3ethch
// "next" 7a9i9i (yestenna el promise tou3ha automatique) - fa "next"
// jowa el fonction ye39od "undefined", w "next()" y-crashi. El fix:
// nna77iw "next" mel paramètres W el appel tou3ou (async pur, bla
// callback - Mongoose yestenna el promise wa7dou).
userSchema.pre('findOneAndDelete', async function () {
  // n7ottou el _id el document elli bch yetfassa5 (9bal el delete 7a9i9i)
  // bch nnajjmou nesta3mlouh fel "post" (ba3d ma el delete ye9das).
  const docToDelete = await this.model.findOne(this.getFilter());
  this._deletedUserId = docToDelete ? docToDelete._id : null;
});

userSchema.post('findOneAndDelete', async function () {
  if (this._deletedUserId) {
    // mongoose.model('Animal') (bel esm, mch require direct) - bch
    // najjmou n7aynou "circular require" bin user.js w animal.js.
    await mongoose.model('Animal').deleteMany({ owner: this._deletedUserId });
  }
});

userSchema.pre('deleteOne', { document: true, query: false }, async function () {
  await mongoose.model('Animal').deleteMany({ owner: this._id });
});

module.exports = mongoose.model('User', userSchema);