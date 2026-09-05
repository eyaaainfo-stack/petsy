const Conversation = require('../models/conversation');
const Message = require('../models/message');
const Booking = require('../models/booking');
const User = require('../models/user');

// 🔵 ZID (kifma tlab: "demande de message" - "invitation" bin 2 nas
// mafamech beynethom booking) - helper: el 2 users "déjà connectés"
// (booking wa7ed 3al a9al beynethom, ay direction: A owner/B sitter
// wla B owner/A sitter) - lowkan houma déjà connectés, "demande" ma
//3andhach me3na (conversation twalled "accepted" direct).
async function areAlreadyConnected(userIdA, userIdB) {
  const booking = await Booking.exists({
    $or: [
      { owner: userIdA, sitter: userIdB },
      { owner: userIdB, sitter: userIdA },
    ],
  });
  return !!booking;
}

// ============================================================================
// GET CONTACTS ("bulles" fel haut tel messages_list_screen.dart - kifma
// tlab: "des acteures eli saret binetna kbal ya cnv ya reservation")
// ============================================================================
// 🔵 njam3ou 2 sources w n-dédupliqui-w (b'userId):
//   1) el conversations el 7a9i9iya (participants) - fama déjà messages
//      metba3thin.
//   2) el bookings (owner<->sitter, kifma tlab "ya reservation") - 7ata
//      ken mazel ma badech conversation, el 2 tarfin déjà "connectés"
//      b'reservation, fa el user ynajjam ybda ye7ki m3ahom direct.
// Tertib: el a5er activité awalan (lastMessageAt lel conversations,
// createdAt tel booking lowkan mazel ma famech conversation).
// ============================================================================
exports.getContacts = async (req, res) => {
  try {
    const myId = req.userId;

    const [conversations, bookingsAsOwner, bookingsAsSitter] = await Promise.all([
      Conversation.find({ participants: myId }),
      Booking.find({ owner: myId, sitter: { $ne: null } }).select('sitter createdAt'),
      Booking.find({ sitter: myId }).select('owner createdAt'),
    ]);

    // Map<otherUserId (string), { lastActivityAt, conversationId }>
    const activityMap = new Map();

    for (const conv of conversations) {
      const otherId = conv.participants.map((p) => p.toString()).find((p) => p !== myId);
      if (!otherId) continue;
      const activityAt = conv.lastMessageAt || conv.updatedAt;
      const existing = activityMap.get(otherId);
      if (!existing || new Date(activityAt) > new Date(existing.lastActivityAt)) {
        activityMap.set(otherId, { lastActivityAt: activityAt, conversationId: conv._id });
      }
    }

    // 🔵 el bookings ma "y-override-w" ch une conversation elli déjà
    // mawjouda (conversationId != null) - ghir yzidou contact JDID
    // (lowkan mazel ma famech ay conversation m3ah).
    for (const b of [...bookingsAsOwner.map((x) => x.sitter), ...bookingsAsSitter.map((x) => x.owner)]) {
      const otherId = b.toString();
      if (!activityMap.has(otherId)) {
        const sourceBooking = bookingsAsOwner.find((x) => x.sitter?.toString() === otherId) || bookingsAsSitter.find((x) => x.owner?.toString() === otherId);
        activityMap.set(otherId, { lastActivityAt: sourceBooking.createdAt, conversationId: null });
      }
    }

    const otherIds = [...activityMap.keys()];
    const users = await User.find({ _id: { $in: otherIds } }).select('fullName photoUrl city role');

    const contacts = users
      .map((u) => {
        const info = activityMap.get(u._id.toString());
        return {
          userId: u._id,
          fullName: u.fullName,
          photoUrl: u.photoUrl,
          city: u.city,
          role: u.role,
          conversationId: info.conversationId,
          lastActivityAt: info.lastActivityAt,
        };
      })
      .sort((a, b) => new Date(b.lastActivityAt) - new Date(a.lastActivityAt));

    res.status(200).json({ contacts });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET CONVERSATIONS (liste principale - messages_list_screen.dart, taht
// el bulles) - GET /api/conversations
// ============================================================================
exports.getConversations = async (req, res) => {
  try {
    const myId = req.userId;

    const conversations = await Conversation.find({ participants: myId })
      .sort({ lastMessageAt: -1 })
      .populate('participants', 'fullName photoUrl city role');

    const results = await Promise.all(
      conversations
        // 🔵 ZID (kifma tlab: "demande de message") - lowkan "declined"
        // W mch ana elli bdit biha (ana el recipient elli rafedht),
        // ma nwarriwhach mrra thenya (tab9a mawjouda l'el initiator bark
        // - "read-only", chraht fel sendMessage/getMessages).
        .filter((conv) => conv.status !== 'declined' || (conv.initiator && conv.initiator.toString() === myId))
        .map(async (conv) => {
          const other = conv.participants.find((p) => p._id.toString() !== myId);
          // 🔵 unread count: messages fel conversation hedhi, mch mabou3thin
          // menni, w mazel ma zidtch fihom (readBy ma fihech myId).
          const unreadCount = await Message.countDocuments({
            conversation: conv._id,
            sender: { $ne: myId },
            readBy: { $ne: myId },
          });

          return {
            conversationId: conv._id,
            otherUser: other
              ? { userId: other._id, fullName: other.fullName, photoUrl: other.photoUrl, city: other.city, role: other.role }
              : null,
            lastMessage: conv.lastMessage,
            lastMessageType: conv.lastMessageType,
            lastMessageAt: conv.lastMessageAt,
            lastMessageIsMine: conv.lastMessageSender ? conv.lastMessageSender.toString() === myId : false,
            unreadCount,
            // 🔵 ZID (kifma tlab: "demande de message") - el front (messages_
            // list_screen.dart/chat_screen.dart) yesta3melhom bch ye5tar
            // ywarri "Demande de message" (Accepter/Refuser) wla "En attente"
            // wla conversation 3adiya.
            status: conv.status,
            isInitiator: conv.initiator ? conv.initiator.toString() === myId : false,
          };
        })
    );

    res.status(200).json({ conversations: results });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// START OR GET CONVERSATION - POST /api/conversations { userId }
// ============================================================================
// 🔵 ki el user y-tapi 3ala bulle (contact) wela y-bda chat jdid m3a
// sitter/owner - lowkan déjà 3andhom conversation, terja3 nafsha (mch
// twalled wa7da jdida b'doublon).
// ============================================================================
exports.startOrGetConversation = async (req, res) => {
  try {
    const myId = req.userId;
    const { userId } = req.body;

    if (!userId) return res.status(400).json({ message: 'userId is required' });
    if (userId === myId) return res.status(400).json({ message: 'Cannot start a conversation with yourself' });

    const otherUser = await User.findById(userId).select('fullName photoUrl city role');
    if (!otherUser) return res.status(404).json({ message: 'User not found' });

    let conversation = await Conversation.findOne({
      participants: { $all: [myId, userId], $size: 2 },
    });

    if (!conversation) {
      // 🔵 ZID (kifma tlab: "demande de message") - lowkan MAFAMECH
      // booking beynethom, hedhi "invitation" jdida - "pending", mestanniya
      // el tarf l'akhor ye5tar Accepter/Refuser 9bal ma ynajjam yjaweb.
      const alreadyConnected = await areAlreadyConnected(myId, userId);
      conversation = await Conversation.create({
        participants: [myId, userId],
        status: alreadyConnected ? 'accepted' : 'pending',
        initiator: alreadyConnected ? null : myId,
      });
    }

    res.status(200).json({
      conversationId: conversation._id,
      otherUser: {
        userId: otherUser._id,
        fullName: otherUser.fullName,
        photoUrl: otherUser.photoUrl,
        city: otherUser.city,
        role: otherUser.role,
      },
      // 🔵 ZID (kifma tlab: "demande de message") - el front (ChatScreen)
      // yesta3melhom bch ye5tar ywarri l'input 3adi, wla Accepter/Refuser.
      status: conversation.status,
      isInitiator: conversation.initiator ? conversation.initiator.toString() === myId : false,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// SEND FIRST MESSAGE (create-on-demand) - POST /api/conversations/messages
// { userId, text }
// ============================================================================
// 🔴 FIX (kifma tlab: "nhb el demande ma tkoun envoyee ella ma ykoun
// fama message tebaath") - 9bal, startOrGetConversation kan yel9a
// Conversation ("pending") direct ki el user GHIR yefte7 el chat
// (mathalan mel recherche/profil) - 7atta lowkan 3omrou ma katab
// 7arf, el tarf l'akhor kan yechouf "demande" fel liste tou3ou! Tawa:
// AY conversation jdida (mafamech déjà) ma tetweledech fel base GHIR
// lowkan fama 7a9i9atan message metba3eth (houni, wla sendFirstImage
// ta7t) - mch mjarrad "fte7 el chat".
// ============================================================================
exports.sendFirstMessage = async (req, res) => {
  try {
    const myId = req.userId;
    const { userId } = req.body;
    const text = (req.body.text || '').trim();

    if (!userId) return res.status(400).json({ message: 'userId is required' });
    if (!text) return res.status(400).json({ message: 'Message text is required' });
    if (userId === myId) return res.status(400).json({ message: 'Cannot start a conversation with yourself' });

    const otherUser = await User.findById(userId).select('fullName photoUrl city role');
    if (!otherUser) return res.status(404).json({ message: 'User not found' });

    let conversation = await Conversation.findOne({ participants: { $all: [myId, userId], $size: 2 } });

    if (!conversation) {
      const alreadyConnected = await areAlreadyConnected(myId, userId);
      conversation = await Conversation.create({
        participants: [myId, userId],
        status: alreadyConnected ? 'accepted' : 'pending',
        initiator: alreadyConnected ? null : myId,
      });
    } else {
      // 🔵 conversation déjà mawjouda (mathalan l'initiator l'oula rafedh
      // w 3awd y7awel) - nafs les règles tel sendMessage el 3adi.
      if (conversation.status === 'declined') {
        return res.status(403).json({ message: 'This conversation has been declined' });
      }
      if (conversation.status === 'pending' && conversation.initiator?.toString() !== myId) {
        return res.status(403).json({ message: 'Accept the message request before replying' });
      }
    }

    const message = await Message.create({
      conversation: conversation._id,
      sender: myId,
      type: 'text',
      text,
      readBy: [myId],
    });

    conversation.lastMessage = text;
    conversation.lastMessageType = 'text';
    conversation.lastMessageAt = message.createdAt;
    conversation.lastMessageSender = myId;
    await conversation.save();

    res.status(201).json({
      conversationId: conversation._id,
      message,
      status: conversation.status,
      isInitiator: conversation.initiator ? conversation.initiator.toString() === myId : false,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// SEND FIRST IMAGE MESSAGE (create-on-demand) - POST /api/conversations/
// messages/image (multipart, fields "userId" + "image")
// ============================================================================
// 🔴 FIX: nafs mant9 sendFirstMessage - lel 7ala elli l'AWWEL message
// (kifma tlab, "awl mra bch nhkiw") ykoun photo (mch text).
// ============================================================================
exports.sendFirstImageMessage = async (req, res) => {
  try {
    const myId = req.userId;
    const { userId } = req.body;
    if (!userId) return res.status(400).json({ message: 'userId is required' });
    if (userId === myId) return res.status(400).json({ message: 'Cannot start a conversation with yourself' });
    if (!req.file) return res.status(400).json({ message: 'Image is required' });

    const otherUser = await User.findById(userId).select('_id');
    if (!otherUser) return res.status(404).json({ message: 'User not found' });

    let conversation = await Conversation.findOne({ participants: { $all: [myId, userId], $size: 2 } });

    if (!conversation) {
      const alreadyConnected = await areAlreadyConnected(myId, userId);
      conversation = await Conversation.create({
        participants: [myId, userId],
        status: alreadyConnected ? 'accepted' : 'pending',
        initiator: alreadyConnected ? null : myId,
      });
    } else {
      if (conversation.status === 'declined') {
        return res.status(403).json({ message: 'This conversation has been declined' });
      }
      if (conversation.status === 'pending' && conversation.initiator?.toString() !== myId) {
        return res.status(403).json({ message: 'Accept the message request before replying' });
      }
    }

    const imageUrl = `/uploads/messages/${req.file.filename}`;

    const message = await Message.create({
      conversation: conversation._id,
      sender: myId,
      type: 'image',
      imageUrl,
      readBy: [myId],
    });

    conversation.lastMessage = '📷 Photo';
    conversation.lastMessageType = 'image';
    conversation.lastMessageAt = message.createdAt;
    conversation.lastMessageSender = myId;
    await conversation.save();

    res.status(201).json({
      conversationId: conversation._id,
      message,
      status: conversation.status,
      isInitiator: conversation.initiator ? conversation.initiator.toString() === myId : false,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET MESSAGES - GET /api/conversations/:id/messages (chat_screen.dart)
// ============================================================================
// 🔵 ki el user yefte7 el chat, njibou el messages el kol (mrattbin
// b'wa9t, el 9dim awalan) W f nafs el wa9t n3allmouhom "vus" (readBy)
// - bch el badge "unread" (conversation list) ye5taفi mel marra el jaya.
// ============================================================================
exports.getMessages = async (req, res) => {
  try {
    const myId = req.userId;
    const conversation = await Conversation.findById(req.params.id);
    if (!conversation) return res.status(404).json({ message: 'Conversation not found' });
    if (!conversation.participants.some((p) => p.toString() === myId)) {
      return res.status(403).json({ message: 'Not a participant of this conversation' });
    }

    const messages = await Message.find({ conversation: conversation._id }).sort({ createdAt: 1 });

    await Message.updateMany(
      { conversation: conversation._id, sender: { $ne: myId }, readBy: { $ne: myId } },
      { $addToSet: { readBy: myId } }
    );

    res.status(200).json({ messages });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// SEND MESSAGE (text) - POST /api/conversations/:id/messages { text }
// ============================================================================
exports.sendMessage = async (req, res) => {
  try {
    const myId = req.userId;
    const text = (req.body.text || '').trim();
    if (!text) return res.status(400).json({ message: 'Message text is required' });

    const conversation = await Conversation.findById(req.params.id);
    if (!conversation) return res.status(404).json({ message: 'Conversation not found' });
    if (!conversation.participants.some((p) => p.toString() === myId)) {
      return res.status(403).json({ message: 'Not a participant of this conversation' });
    }
    // 🔵 ZID (kifma tlab: "demande de message") - "declined": 7ata wa7ed
    // ma ynajjam yeb3ath (conversation meghlou9a). "pending": ghir el
    // initiator ynajjam yeb3ath (el tarf l'akhor lezmou Accepter awalan).
    if (conversation.status === 'declined') {
      return res.status(403).json({ message: 'This conversation has been declined' });
    }
    if (conversation.status === 'pending' && conversation.initiator?.toString() !== myId) {
      return res.status(403).json({ message: 'Accept the message request before replying' });
    }

    const message = await Message.create({
      conversation: conversation._id,
      sender: myId,
      type: 'text',
      text,
      readBy: [myId],
    });

    conversation.lastMessage = text;
    conversation.lastMessageType = 'text';
    conversation.lastMessageAt = message.createdAt;
    conversation.lastMessageSender = myId;
    await conversation.save();

    res.status(201).json({ message });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// SEND IMAGE MESSAGE - POST /api/conversations/:id/messages/image
// (multipart, field "image" - kifma tlab: "camera ki tenzel aliha
// tkhtr ya mel gal ya mel apareil photo")
// ============================================================================
exports.sendImageMessage = async (req, res) => {
  try {
    const myId = req.userId;
    if (!req.file) return res.status(400).json({ message: 'Image is required' });

    const conversation = await Conversation.findById(req.params.id);
    if (!conversation) return res.status(404).json({ message: 'Conversation not found' });
    if (!conversation.participants.some((p) => p.toString() === myId)) {
      return res.status(403).json({ message: 'Not a participant of this conversation' });
    }
    // 🔵 ZID (kifma tlab: "demande de message") - nafs el mant9 tel
    // sendMessage (text) - "declined"/"pending" (mch initiator) mamnou3.
    if (conversation.status === 'declined') {
      return res.status(403).json({ message: 'This conversation has been declined' });
    }
    if (conversation.status === 'pending' && conversation.initiator?.toString() !== myId) {
      return res.status(403).json({ message: 'Accept the message request before replying' });
    }

    const imageUrl = `/uploads/messages/${req.file.filename}`;

    const message = await Message.create({
      conversation: conversation._id,
      sender: myId,
      type: 'image',
      imageUrl,
      readBy: [myId],
    });

    conversation.lastMessage = '📷 Photo';
    conversation.lastMessageType = 'image';
    conversation.lastMessageAt = message.createdAt;
    conversation.lastMessageSender = myId;
    await conversation.save();

    res.status(201).json({ message });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// ACCEPT MESSAGE REQUEST - PATCH /api/conversations/:id/accept (kifma
// tlab: "el user lekher yakhtar yokblou wle yorfodh")
// ============================================================================
// 🔵 ghir el RECIPIENT (mch el initiator - ma3andouch me3na y9bel/yerfudh
// talab houwa nafsou 5al9ou) ynajjam ye5tar - conversation twalli
// "accepted", el 2 tarfin ynajjmou yjaweبou tawa.
// ============================================================================
exports.acceptConversation = async (req, res) => {
  try {
    const myId = req.userId;
    const conversation = await Conversation.findById(req.params.id);
    if (!conversation) return res.status(404).json({ message: 'Conversation not found' });
    if (!conversation.participants.some((p) => p.toString() === myId)) {
      return res.status(403).json({ message: 'Not a participant of this conversation' });
    }
    if (conversation.status !== 'pending') {
      return res.status(400).json({ message: 'This conversation is not a pending request' });
    }
    if (conversation.initiator?.toString() === myId) {
      return res.status(403).json({ message: 'Only the recipient can accept a message request' });
    }

    conversation.status = 'accepted';
    await conversation.save();

    res.status(200).json({ message: 'Message request accepted', status: conversation.status });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// DECLINE MESSAGE REQUEST - PATCH /api/conversations/:id/decline
// ============================================================================
// 🔵 nafs el mant9 (recipient bark) - conversation twalli "declined"
// (meghlou9a, mafamech ynajjam yeb3ath fiha 7atta - w tetkhaba mel liste
// tel recipient mel marra el jaya, chraht fel getConversations).
// ============================================================================
exports.declineConversation = async (req, res) => {
  try {
    const myId = req.userId;
    const conversation = await Conversation.findById(req.params.id);
    if (!conversation) return res.status(404).json({ message: 'Conversation not found' });
    if (!conversation.participants.some((p) => p.toString() === myId)) {
      return res.status(403).json({ message: 'Not a participant of this conversation' });
    }
    if (conversation.status !== 'pending') {
      return res.status(400).json({ message: 'This conversation is not a pending request' });
    }
    if (conversation.initiator?.toString() === myId) {
      return res.status(403).json({ message: 'Only the recipient can decline a message request' });
    }

    conversation.status = 'declined';
    await conversation.save();

    res.status(200).json({ message: 'Message request declined', status: conversation.status });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// SEARCH USERS (kifma tlab: "wkt nlawej ala had f recherche ena nebda
// nekteb w houa yjini des proposition lel asemi eli mawjoudin fel app")
// - GET /api/conversations/search-users?q=...
// ============================================================================
// 🔵 ZID: autocomplete "live" (nafs mant9 searchSitters, search.dart) -
// lakin houni GHIR bch nel9aw NAS bch nab3thoulhom message (owner WALA
// sitter, mch ghir sitters kifma search.dart el 3adi) - mch mrabta b
// ay booking/conversation déjà mawjouda (kifha kif getContacts) - el
// user ynajjam yal9a AY 7add fel app, w ki y-tapi 3lih, startOrGetConversation
// ye5tar wa7dou "pending" (demande) wla "accepted" (kifma tlab: "kif
// nenzel ala chkoun ma kenetch anna reservation en commun... yjih
// comme une invitation soit yokbelha soit yorfedhha").
// ============================================================================
exports.searchUsers = async (req, res) => {
  try {
    const { q } = req.query;
    if (!q || !q.trim()) return res.status(200).json({ users: [] });

    const escaped = q.trim().replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

    const users = await User.find({
      _id: { $ne: req.userId },
      // 🔵 owner/sitter bark (les 2 "acteurs" 7a9i9iyin fel app) - mch
      // admin (ma3andouch me3na l'user y-message-i el admin mel search).
      role: { $in: ['owner', 'sitter'] },
      fullName: { $regex: escaped, $options: 'i' },
    })
      .select('fullName photoUrl city role')
      .limit(15);

    res.status(200).json({
      users: users.map((u) => ({ userId: u._id, fullName: u.fullName, photoUrl: u.photoUrl, city: u.city, role: u.role })),
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ============================================================================
// GET CONVERSATION WITH USER (read-only, mafamech creation) - GET
// /api/conversations/with/:userId
// ============================================================================
// 🔴 FIX (kifma tlab: "nhb el demande ma tkoun envoyee ella ma ykoun
// fama message tebaath") - view_profile_sitter.dart (bouton "Message")
// ma3andouch liste _conversations mel9a (kifha kif messages_list_screen.dart)
// bch ychouf ken déjà fama conversation m3a hedha el sitter - fa
// endpoint "read-only" (mafamech creation, mafamech side-effect) bch
// yal9a el conversation EXISTING lowkan fama, w bla ma ye5le9 wa7da
// jdida lowkan mafamech (ChatScreen tekmel b conversationId=null,
// twalled ghir ki l'user yeb3ath l'AWWEL message 7a9i9i).
// ============================================================================
exports.getConversationWithUser = async (req, res) => {
  try {
    const myId = req.userId;
    const { userId } = req.params;

    const conversation = await Conversation.findOne({ participants: { $all: [myId, userId], $size: 2 } });
    if (!conversation) return res.status(404).json({ message: 'No existing conversation' });

    res.status(200).json({
      conversationId: conversation._id,
      status: conversation.status,
      isInitiator: conversation.initiator ? conversation.initiator.toString() === myId : false,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};