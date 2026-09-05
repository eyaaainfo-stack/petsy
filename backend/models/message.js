const mongoose = require('mongoose');

// ============================================================================
// Message
// ============================================================================
// 🔵 ZID (messagerie - kifma tlab: "fiha just les message ecrit w camera
// ki tenzel aliha tkhtr ya mel gal ya mel apareil photo") - message
// wa7ed ynajjam ykoun 'text' (chraht bark) wla 'image' (photo, mel
// galerie wla mel caméra - "imageUrl" el path tel fichier fel disque,
// nafs mant9 photoUrl/cinFrontPhotoUrl fel models/user.js).
// ============================================================================
const messageSchema = new mongoose.Schema(
  {
    conversation: { type: mongoose.Schema.Types.ObjectId, ref: 'Conversation', required: true },
    sender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    type: { type: String, enum: ['text', 'image'], default: 'text' },
    text: { type: String, default: '' },
    imageUrl: { type: String, default: '' },
    // 🔵 ZID: liste el users elli déjà 9raw el message hedha - bch
    // nnajjmou n7esbou "unread count" (conversation list) w n3allmou
    // el message "vu" (chraht fel controller, GET /:id/messages).
    readBy: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  },
  { timestamps: true }
);

// 🔵 index (conversation + createdAt) - el query "messages tel conversation
// hedhi, mrattbin b'wa9t" (chat screen) ye5dem b'sur3a.
messageSchema.index({ conversation: 1, createdAt: 1 });

module.exports = mongoose.model('Message', messageSchema);