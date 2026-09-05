// routes/conversationRoutes.js
const express = require('express');
const router = express.Router();
const conversationController = require('../controllers/conversationController');
const { protect } = require('../middleware/auth');
const { messageUpload } = require('../middleware/upload');

// 🔵 ZID (messagerie - kifma tlab: interface kima Messenger, bulles +
// recherche + liste conversations, w camera fel chat lel photos).

// "GET /contacts" LEZEM 9BAL "GET /:id/messages" (mnghir Express
// ye5altha b'ID) - nafs convention bookingRoutes.js ("urgent" 9bal ":id").
router.get('/contacts', protect, conversationController.getContacts);
// 🔵 ZID (kifma tlab: "recherche... des proposition lel asemi eli
// mawjoudin fel app") - autocomplete live, AY user (mch ghir contacts).
router.get('/search-users', protect, conversationController.searchUsers);
// 🔴 FIX (kifma tlab: "nhb el demande ma tkoun envoyee ella ma ykoun
// fama message tebaath") - "read-only" (mafamech creation) - view_
// profile_sitter.dart testa3melha (bouton "Message") bch tchouf ken
// déjà fama conversation m3a hedha el user 9bal ma tefte7 ChatScreen.
router.get('/with/:userId', protect, conversationController.getConversationWithUser);
router.get('/', protect, conversationController.getConversations);
router.post('/', protect, conversationController.startOrGetConversation);

// 🔴 FIX (kifma tlab: "nhb el demande ma tkoun envoyee ella ma ykoun
// fama message tebaath") - "create-on-demand": mafamech Conversation
// twelled fel base GHIR ki fama 7a9i9atan AWWEL message metba3eth
// (mch mjarrad "fte7 el chat"). LEZEM 9BAL "/:id/messages" (nafs
// mant9 "/contacts" fou9 - Express ma yel5altohomch, segments 3adad
// mo5talef, lakin nzidouhom houni bch yeb9aw METJAM3IN loجikiyan).
router.post('/messages', protect, conversationController.sendFirstMessage);
router.post('/messages/image', protect, messageUpload.single('image'), conversationController.sendFirstImageMessage);

router.get('/:id/messages', protect, conversationController.getMessages);
router.post('/:id/messages', protect, conversationController.sendMessage);
router.post('/:id/messages/image', protect, messageUpload.single('image'), conversationController.sendImageMessage);

// 🔵 ZID (kifma tlab: "demande de message" - invitation, Accepter/Refuser)
router.patch('/:id/accept', protect, conversationController.acceptConversation);
router.patch('/:id/decline', protect, conversationController.declineConversation);

module.exports = router;