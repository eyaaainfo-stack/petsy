const mongoose = require('mongoose');

// ============================================================================
// Conversation
// ============================================================================
// 🔵 ZID (messagerie - kifma tlab: "interface moderne fiha just les
// message... kif nenzel ala messagerie nhbha tjini kima messenger") -
// conversation = 2 participants (owner<->sitter, wla ay 2 users) + un
// "cache" tel a5er message (bch el liste el conversations - messages_
// list_screen.dart - ma te7tejch te3mel populate 3ala kol el messages
// bch twarri el aperçu, ghir tel Conversation document nafsou).
// ============================================================================
const conversationSchema = new mongoose.Schema(
  {
    // 🔵 dima 2 participants bark (chat privé, mch group chat) - el
    // contrainte "$size: 2" met7a99a fel controller (startOrGetConversation),
    // mch houni (Mongoose schema ma3andouch validator native l'hedha).
    participants: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }],

    // 🔵 "cache" tel a5er message - bch el conversation list (search bar
    // + bulles + liste) tban b'appel WA7ED (GET /api/conversations), bla
    // ma te7taj tجيب el message el a5ir tel kol conversation b'appel
    // mnfassel.
    lastMessage: { type: String, default: '' },
    lastMessageType: { type: String, enum: ['text', 'image'], default: 'text' },
    lastMessageAt: { type: Date, default: Date.now },
    lastMessageSender: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },

    // 🔵 ZID (kifma tlab: "wkt naaml recherche ala esl user ma tkounech
    // binetna reservation w nhb nebaathlo message... kima invitation
    // par message wel user lekher yakhtar yokblou wle yorfodh") -
    // "demande de message" (kifha kif Instagram/LinkedIn): lowkan el 2
    // users MAFAMECH booking beynethom (ma3rafouch b3adhom mel workflow
    // 3adi), el conversation el jdida tetweled "pending" (mch "accepted"
    // direct) - el "initiator" (elli bda) ynajjam yeb3ath messages, lakin
    // el tarf l'akhor LEZEM ye5tar "Accepter"/"Refuser" 9bal ma ynajjam
    // yjaweb. Lowkan fama déjà booking beynethom, tetweled "accepted"
    // direct (kifha kif kanet - mafamech me3na l'"demande" bin 2 nas
    // déjà 3andhom relation 7a9i9iya).
    status: { type: String, enum: ['accepted', 'pending', 'declined'], default: 'accepted' },
    // 🔵 chkoun bda el conversation (bark lowkan "pending"/"declined" -
    // "null" lel conversations el "accepted" mel bidaya, mch mهم chkoun
    // bda fihom 7it el 2 déjà "connectés").
    initiator: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  },
  { timestamps: true }
);

// 🔵 index 3al participants - el query "conversations mte3i" (participants
// contains myId) w "3andi déjà conversation m3a hedha el user" (participants
// $all [myId, otherId]) ye5damou b'sur3a, hatta ken el liste tkabber.
conversationSchema.index({ participants: 1 });

module.exports = mongoose.model('Conversation', conversationSchema);