// middleware/upload.js
const multer = require('multer');
const path = require('path');
const fs = require('fs');

// ============================================================================
// createUploader(subfolder)
// ============================================================================
// Factory: terja3 instance multer mo3ayen 3ala 7sab el "subfolder"
// (mathalan 'pets' wala 'users') - bch kol noue3 image tetzid f folder
// mnfassel (uploads/pets/, uploads/users/...), mch kolhom metla9tin
// f nefs el folder (kan ysabbeb lakhbata).
//
// 🔵 el code (storage, filter, limits) MECHTAREK bin el 2 (pets w
// users) - ghir el folder elli yetbeddel. Hedhi el fikra tel "factory
// function": nekteb el mant9 marra wa7da, w n3awdou nesta3malouh
// b parametres mo5telfin.
// ============================================================================
function createUploader(subfolder) {
  const uploadDir = path.join(__dirname, '..', 'uploads', subfolder);

  // n5al9ou el folder lowkan mch mawjoud (multer ma ye5dhach automatique)
  if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
  }

  const storage = multer.diskStorage({
    destination: (req, file, cb) => {
      cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
      // esm unique: timestamp + random + extension el 7a9i9i (jpg/png...)
      const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
      cb(null, `${uniqueSuffix}${path.extname(file.originalname)}`);
    },
  });

  // filter: images bess (jpg, png, webp...) - manna3 ay type okhor
  // (mathalan .exe wala .pdf ma3andhomch ma3na houni)
  const fileFilter = (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'), false);
    }
  };

  return multer({
    storage,
    fileFilter,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB max
  });
}

// 👉 2 instances jahzin, kol wa7da 3andha el folder tou3ha
module.exports = {
  petUpload: createUploader('pets'),
  userUpload: createUploader('users'),
  // 🔵 ZID (kifma tlab: "ajoute l'upload CIN au système") - folder
  // mnfassel ('uploads/cin/') - documents identité, mch photos profil
  // 3adiya, a7sen tab9a mfarza mn jihet l'organisation.
  cinUpload: createUploader('cin'),
  // 🔵 ZID (messagerie - kifma tlab: "camera ki tenzel aliha tkhtr ya
  // mel gal ya mel apareil photo") - folder mnfassel ('uploads/messages/')
  // lel photos elli yetba3thou fel conversations (chat).
  messageUpload: createUploader('messages'),
};