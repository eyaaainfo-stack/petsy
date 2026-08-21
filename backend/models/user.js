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
  },
  {
    discriminatorKey: 'role', // C'est ici que l'héritage se fait (le champ qui indique le type d'acteur)
    collection: 'users',      // Tous les acteurs vont dans la même table "users"
    timestamps: true,
  }
);

module.exports = mongoose.model('User', userSchema);