import 'dart:convert';
import 'dart:typed_data';
import '../services/api_service.dart';
import 'auth_session.dart';
import '../models/chat_contact.dart';
import '../models/conversation_summary.dart';
import '../models/chat_message.dart';
import '../models/user_search_result.dart';

// ============================================================================
// MessagesController (messagerie - kifma tlab: "interface moderne...
// kima messenger")
// ============================================================================
// 🔵 kol el appels API tel messagerie (bulles/contacts, liste
// conversations, messages tel chat, ba3th text/photo) - nafs mant9
// el controllers l'okhrin (request_controller.dart, favorites_
// controller.dart...): try/catch, terja3 null/liste fadhya lowkan
// erreur (bla ma tarmi exception l'l'écran).
// ============================================================================
class MessagesController {
  // --------------------------------------------------------------------
  // el bulles (fou9 el écran) - "acteurs eli saret binetna kbal ya cnv
  // ya reservation".
  // --------------------------------------------------------------------
  Future<List<ChatContact>> fetchContacts() async {
    try {
      final response = await ApiService.get('/conversations/contacts', token: AuthSession.token);
      if (response.statusCode != 200) return [];
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> raw = data['contacts'] as List<dynamic>? ?? [];
      return raw.map((c) => ChatContact.fromJson(c as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --------------------------------------------------------------------
  // el liste el conversations (taht el bulles).
  // --------------------------------------------------------------------
  Future<List<ConversationSummary>> fetchConversations() async {
    try {
      final response = await ApiService.get('/conversations', token: AuthSession.token);
      if (response.statusCode != 200) return [];
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> raw = data['conversations'] as List<dynamic>? ?? [];
      return raw.map((c) => ConversationSummary.fromJson(c as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  // --------------------------------------------------------------------
  // ki el user y-tapi 3ala bulle wla y-bda chat jdid m3a sitter/owner -
  // terja3 conversation mawjouda lowkan famma, wla twalled wa7da jdida.
  // Terja3 record {conversationId, otherUserId, otherUserName,
  // otherUserPhotoUrl} bch nnajmou nefta7ou el ChatScreen direct.
  // --------------------------------------------------------------------
  Future<Map<String, dynamic>?> startConversation(String userId) async {
    try {
      final response = await ApiService.post('/conversations', {'userId': userId}, token: AuthSession.token);
      if (response.statusCode != 200) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final Map<String, dynamic>? other = data['otherUser'] as Map<String, dynamic>?;
      final String? rawPhotoUrl = other?['photoUrl'] as String?;
      return {
        'conversationId': data['conversationId'] as String? ?? '',
        'otherUserId': other?['userId'] as String? ?? '',
        'otherUserName': other?['fullName'] as String? ?? '',
        'otherUserPhotoUrl': (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawPhotoUrl' : null,
        // 🔵 ZID (kifma tlab: "demande de message") - ChatScreen yesta3melhom
        // bch ye5tar ywarri l'input 3adi, wla Accepter/Refuser.
        'status': data['status'] as String? ?? 'accepted',
        'isInitiator': data['isInitiator'] as bool? ?? false,
      };
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------
  // el messages tel conversation (chat_screen.dart) - GET t3allem el
  // messages "vus" automatique (chraht fel backend).
  // --------------------------------------------------------------------
  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    try {
      final response = await ApiService.get('/conversations/$conversationId/messages', token: AuthSession.token);
      if (response.statusCode != 200) return [];
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> raw = data['messages'] as List<dynamic>? ?? [];
      final String myId = AuthSession.userId ?? '';
      return raw.map((m) => ChatMessage.fromJson(m as Map<String, dynamic>, myUserId: myId)).toList();
    } catch (_) {
      return [];
    }
  }

  // --------------------------------------------------------------------
  // ba3th message ktouba.
  // --------------------------------------------------------------------
  Future<ChatMessage?> sendText(String conversationId, String text) async {
    try {
      final response = await ApiService.post('/conversations/$conversationId/messages', {'text': text}, token: AuthSession.token);
      if (response.statusCode != 201) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final String myId = AuthSession.userId ?? '';
      return ChatMessage.fromJson(data['message'] as Map<String, dynamic>, myUserId: myId);
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------
  // 🔴 FIX (kifma tlab: "nhb el demande ma tkoun envoyee ella ma ykoun
  // fama message tebaath") - "create-on-demand": testa3mel GHIR ki
  // mafamech conversationId 7a9i9i mazel (chat "fresh", mel recherche/
  // profil/bulle bla conversation mawjouda) - twalled el Conversation
  // fel base w tebaath l'AWWEL message f'appel WA7ED.
  // --------------------------------------------------------------------
  Future<Map<String, dynamic>?> sendFirstText(String otherUserId, String text) async {
    try {
      final response = await ApiService.post('/conversations/messages', {'userId': otherUserId, 'text': text}, token: AuthSession.token);
      if (response.statusCode != 201) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final String myId = AuthSession.userId ?? '';
      return {
        'conversationId': data['conversationId'] as String? ?? '',
        'message': ChatMessage.fromJson(data['message'] as Map<String, dynamic>, myUserId: myId),
        'status': data['status'] as String? ?? 'accepted',
        'isInitiator': data['isInitiator'] as bool? ?? true,
      };
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------
  // ba3th photo (mel galerie wla mel caméra - kifma tlab: "camera ki
  // tenzel aliha tkhtr ya mel gal ya mel apareil photo") - uploadPhoto
  // (multipart, nafs mant9 el photos l'okhrin fel app).
  // --------------------------------------------------------------------
  Future<ChatMessage?> sendImage(String conversationId, Uint8List imageBytes) async {
    try {
      final response = await ApiService.uploadPhoto(
        '/conversations/$conversationId/messages/image',
        imageBytes,
        token: AuthSession.token,
        fieldName: 'image',
      );
      if (response.statusCode != 201) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final String myId = AuthSession.userId ?? '';
      return ChatMessage.fromJson(data['message'] as Map<String, dynamic>, myUserId: myId);
    } catch (_) {
      return null;
    }
  }

  // 🔴 FIX (kifma tlab: "nhb el demande ma tkoun envoyee ella ma ykoun
  // fama message tebaath") - nafs mant9 sendFirstText, lel 7ala elli
  // l'AWWEL message ykoun photo (mch text).
  Future<Map<String, dynamic>?> sendFirstImage(String otherUserId, Uint8List imageBytes) async {
    try {
      final response = await ApiService.uploadPhoto(
        '/conversations/messages/image',
        imageBytes,
        token: AuthSession.token,
        fieldName: 'image',
        fields: {'userId': otherUserId},
      );
      if (response.statusCode != 201) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final String myId = AuthSession.userId ?? '';
      return {
        'conversationId': data['conversationId'] as String? ?? '',
        'message': ChatMessage.fromJson(data['message'] as Map<String, dynamic>, myUserId: myId),
        'status': data['status'] as String? ?? 'accepted',
        'isInitiator': data['isInitiator'] as bool? ?? true,
      };
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------------------------
  // "demande de message" (kifma tlab: "el user lekher yakhtar yokblou
  // wle yorfodh") - ghir el recipient ynajjam ye5tar (chraht fel backend).
  // --------------------------------------------------------------------
  // --------------------------------------------------------------------
  // 🔴 FIX (kifma tlab: "nhb el demande ma tkoun envoyee ella ma ykoun
  // fama message tebaath") - "read-only" (mafamech creation) - testa3mel
  // ki mafamech liste conversations mel9a mawjouda déjà (mathalan
  // view_profile_sitter.dart) bch nchoufou ken déjà fama conversation
  // m3a hedha el user 9bal ma nefta7ou ChatScreen (bla ma ne5le9ou
  // conversation jdida ghalta).
  // --------------------------------------------------------------------
  Future<Map<String, dynamic>?> getExistingConversationWith(String otherUserId) async {
    try {
      final response = await ApiService.get('/conversations/with/$otherUserId', token: AuthSession.token);
      if (response.statusCode != 200) return null;
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return {
        'conversationId': data['conversationId'] as String? ?? '',
        'status': data['status'] as String? ?? 'accepted',
        'isInitiator': data['isInitiator'] as bool? ?? false,
      };
    } catch (_) {
      return null;
    }
  }

  Future<bool> acceptConversation(String conversationId) async {
    try {
      final response = await ApiService.patch('/conversations/$conversationId/accept', {}, token: AuthSession.token);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> declineConversation(String conversationId) async {
    try {
      final response = await ApiService.patch('/conversations/$conversationId/decline', {}, token: AuthSession.token);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // --------------------------------------------------------------------
  // "recherche... des proposition lel asemi eli mawjoudin fel app" -
  // autocomplete live (AY user, mch ghir contacts déjà mawjoudin).
  // --------------------------------------------------------------------
  Future<List<UserSearchResult>> searchUsers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final response = await ApiService.get('/conversations/search-users?q=${Uri.encodeQueryComponent(query.trim())}', token: AuthSession.token);
      if (response.statusCode != 200) return [];
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      final List<dynamic> raw = data['users'] as List<dynamic>? ?? [];
      return raw.map((u) => UserSearchResult.fromJson(u as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}