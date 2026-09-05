import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/back_button.dart';
import '../../controllers/messages_controller.dart';
import '../../models/chat_contact.dart';
import '../../models/conversation_summary.dart';
import '../../models/user_search_result.dart';
import 'chat_screen.dart';

// ============================================================================
// MessagesListScreen ("Messages" - kifma tlab: "nhbk tesnaali interface
// moderne fiha just les message ecrit w camera... kif nenzel ala
// messagerie nhbha tjini kima messenger barre de recherche w ththa les
// bull (cercle fihom tsawel pdp w tnaajem teswipihom aala jnab) des
// acteures eli saret binetna kbal ya cnv ya reservation w ththom les cnv")
// ============================================================================
// 🔵 Wsulha mel sidebar (owner/sitter, item "Messages") - GET /api/
// conversations/contacts (bulles) + GET /api/conversations (liste) f
// nafs el wa9t. Barre de recherche: filtre local (bla appel API zeyed)
// 3al esm, tban 3al bulles W el liste f nafs el wa9t.
// ============================================================================
class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({super.key});

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  final MessagesController _controller = MessagesController();
  final TextEditingController _searchController = TextEditingController();

  List<ChatContact> _contacts = [];
  List<ConversationSummary> _conversations = [];
  bool _isLoading = true;
  String _searchQuery = '';
  // 🔵 ZID (kifma tlab: "wkt nlawej ala had f recherche... yjini des
  // proposition lel asemi eli mawjoudin fel app") - autocomplete live,
  // AY user fel app (mch ghir contacts/conversations mawjoudin déjà).
  List<UserSearchResult> _searchResults = [];
  bool _isSearchingUsers = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      final query = _searchController.text.trim();
      setState(() => _searchQuery = query.toLowerCase());
      // 🔵 "debounce" (350ms) - bch ma nab3thouch appel API 3ala kol
      // 7arf (kif el user mazel ye9ra), ghir ki y-wa9af chwaya.
      _searchDebounce?.cancel();
      if (query.isEmpty) {
        setState(() => _searchResults = []);
        return;
      }
      _searchDebounce = Timer(const Duration(milliseconds: 350), () => _runUserSearch(query));
    });
  }

  Future<void> _runUserSearch(String query) async {
    setState(() => _isSearchingUsers = true);
    final results = await _controller.searchUsers(query);
    if (!mounted || _searchController.text.trim() != query) return; // el user badel el query mel wa9t elli l'appel jari
    setState(() {
      _searchResults = results;
      _isSearchingUsers = false;
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([_controller.fetchContacts(), _controller.fetchConversations()]);
    if (!mounted) return;
    setState(() {
      _contacts = results[0] as List<ChatContact>;
      _conversations = results[1] as List<ConversationSummary>;
      _isLoading = false;
    });
  }

  List<ChatContact> get _filteredContacts {
    if (_searchQuery.isEmpty) return _contacts;
    return _contacts.where((c) => c.fullName.toLowerCase().contains(_searchQuery)).toList();
  }

  List<ConversationSummary> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    return _conversations.where((c) => c.otherUserName.toLowerCase().contains(_searchQuery)).toList();
  }

  // 🔴 FIX (kifma tlab: "nhb el demande ma tkoun envoyee ella ma ykoun
  // fama message tebaath") - MAFAMECH appel API/creation houni khaless
  // (kanet startConversation twalled Conversation "pending" fel base
  // GHIR ki el user y-tapi 3al bulle - 9bal 7atta ma ykteb 7arf!). Tawa:
  // lowkan fama déjà conversation (contact.conversationId mawjoud),
  // nel9awha mel liste _conversations (déjà 3andna, bla appel zeyed).
  // Lowkan le, nemchiw l'ChatScreen b conversationId=null direct (el
  // conversation ma twelledetch fel base GHIR ki l'AWWEL message
  // metba3eth - chraht fel ChatScreen/_sendText).
  void _openContact(ChatContact contact) {
    if (contact.conversationId != null) {
      final existing = _conversations.where((c) => c.conversationId == contact.conversationId);
      final ConversationSummary? match = existing.isEmpty ? null : existing.first;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: contact.conversationId,
            otherUserId: contact.userId,
            otherUserName: contact.fullName,
            otherUserPhotoUrl: contact.photoUrl,
            status: match?.status ?? 'accepted',
            isInitiator: match?.isInitiator ?? false,
          ),
        ),
      ).then((_) => _load());
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: null,
          otherUserId: contact.userId,
          otherUserName: contact.fullName,
          otherUserPhotoUrl: contact.photoUrl,
          isInitiator: true,
        ),
      ),
    ).then((_) => _load());
  }

  // 🔵 ZID (kifma tlab: "wkt nlawej ala had f recherche... kif nenzel
  // ala chkoun ma kenetch anna reservation en commun w awl mra bch
  // nhkiw el msg yjih comme une invitation") - search results dima
  // dédupliqui-w mel conversations mawjoudin déjà (chraht fou9,
  // "otherSearchResults") - fa conversationId dima null houni.
  void _openSearchResult(UserSearchResult user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: null,
          otherUserId: user.userId,
          otherUserName: user.fullName,
          otherUserPhotoUrl: user.photoUrl,
          isInitiator: true,
        ),
      ),
    ).then((_) => _load());
  }

  void _openConversation(ConversationSummary conv) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          conversationId: conv.conversationId,
          otherUserId: conv.otherUserId,
          otherUserName: conv.otherUserName,
          otherUserPhotoUrl: conv.otherUserPhotoUrl,
          status: conv.status,
          isInitiator: conv.isInitiator,
        ),
      ),
    ).then((_) => _load());
  }

  String _timeLabel(DateTime dateTimeRaw) {
    final dateTime = dateTimeRaw.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diffDays = today.difference(date).inDays;

    if (diffDays == 0) return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    if (diffDays == 1) return 'yesterday_label'.tr();
    if (diffDays < 7) {
      const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return weekdays[dateTime.weekday - 1];
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  String _previewFor(ConversationSummary conv) {
    // 🔵 ZID (kifma tlab: "demande de message... invitation") - lel
    // conversations "pending"/"declined", nwarriw el status BDAL el
    // dernier message (mch mehem "chnowa 9al", mehem l'action el
    // mestanniya).
    if (conv.status == 'pending' && !conv.isInitiator) return 'chat_message_request_label'.tr();
    if (conv.status == 'pending' && conv.isInitiator) return 'chat_request_sent_label'.tr();
    if (conv.status == 'declined') return 'chat_request_declined_label'.tr();

    final String body = conv.lastMessageType == 'image' ? 'chat_photo_preview_label'.tr() : conv.lastMessage;
    if (conv.lastMessage.isEmpty && conv.lastMessageType != 'image') return 'chat_no_messages_yet_label'.tr();
    return conv.lastMessageIsMine ? '${'chat_you_prefix_label'.tr()}$body' : body;
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6) ?? Colors.grey;
    final Color searchBg = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFF1F1F3);

    final contacts = _filteredContacts;
    final conversations = _filteredConversations;
    // 🔵 ZID (kifma tlab: "demande de message... el user lekher yakhtar
    // yokblou wle yorfodh") - "requests" (ANA el recipient, mestanni
    // n5tar) mfarzin f'section 5assa fou9, bch el user ma yfout-hach.
    final requestConversations = conversations.where((c) => c.status == 'pending' && !c.isInitiator).toList();
    final regularConversations = conversations.where((c) => !(c.status == 'pending' && !c.isInitiator)).toList();
    // 🔵 ZID (kifma tlab: "recherche... des proposition lel asemi eli
    // mawjoudin fel app") - user mn app el kol (mch ghir contacts/
    // conversations mawjoudin déjà) - n-dédupliqui-w m3a conversations
    // (bch ma yban-ch nafs el 7add zouz mrat).
    final existingConvUserIds = conversations.map((c) => c.otherUserId).toSet();
    final otherSearchResults = _searchQuery.isEmpty ? <UserSearchResult>[] : _searchResults.where((u) => !existingConvUserIds.contains(u.userId)).toList();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _load,
              color: AppColors.pinkpetsy,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: EdgeInsets.symmetric(horizontal: sizes.messagesHorizontalPadding),
                      children: [
                        SizedBox(height: sizes.messagesTopGap),
                        Center(
                          child: Text(
                            'messages_label'.tr(),
                            style: TextStyle(color: AppColors.pinkpetsy, fontWeight: FontWeight.bold, fontSize: sizes.messagesTitleFontSize),
                          ),
                        ),
                        SizedBox(height: sizes.messagesSectionGap),

                        // ------------------------------------------------
                        // Barre de recherche (kifma Messenger)
                        // ------------------------------------------------
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: sizes.messagesSearchPaddingH),
                          decoration: BoxDecoration(color: searchBg, borderRadius: BorderRadius.circular(24)),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: mutedTextColor, size: sizes.messagesSearchIcon),
                              SizedBox(width: sizes.screenWidth * 0.02),
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: TextStyle(fontSize: sizes.messagesSearchFontSize),
                                  decoration: InputDecoration(
                                    hintText: 'messages_search_hint'.tr(),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: sizes.messagesSearchPaddingV),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: sizes.messagesSectionGap),

                        // ------------------------------------------------
                        // Bulles ("stories") - acteurs (conversation wla
                        // reservation) - tnaajem teswipihom aala jnab.
                        // ------------------------------------------------
                        if (contacts.isNotEmpty && _searchQuery.isEmpty) ...[
                          SizedBox(
                            height: sizes.messagesBubbleSize + sizes.messagesBubbleNameGap + sizes.messagesBubbleNameFontSize * 2.4,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: contacts.length,
                              separatorBuilder: (_, __) => SizedBox(width: sizes.messagesBubbleGap),
                              itemBuilder: (context, index) => _contactBubble(sizes, contacts[index]),
                            ),
                          ),
                          SizedBox(height: sizes.messagesSectionGap),
                        ],

                        // ------------------------------------------------
                        // 🔵 ZID (kifma tlab: "demande de message") -
                        // "Message requests" (ANA el recipient, mestanni
                        // n5tar Accepter/Refuser) - section 5assa fou9.
                        // ------------------------------------------------
                        if (requestConversations.isNotEmpty) ...[
                          Row(
                            children: [
                              Icon(Icons.mail_outline, size: sizes.messagesConvNameFontSize, color: const Color(0xFF9575CD)),
                              SizedBox(width: sizes.screenWidth * 0.015),
                              Text(
                                'chat_message_requests_section_label'.tr(namedArgs: {'count': '${requestConversations.length}'}),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.messagesConvNameFontSize * 0.9, color: const Color(0xFF9575CD)),
                              ),
                            ],
                          ),
                          SizedBox(height: sizes.messagesConvGap),
                          for (final conv in requestConversations) ...[
                            _conversationRow(sizes, conv, mutedTextColor),
                            SizedBox(height: sizes.messagesConvGap),
                          ],
                          SizedBox(height: sizes.messagesSectionGap * 0.6),
                        ],

                        // ------------------------------------------------
                        // Liste des conversations
                        // ------------------------------------------------
                        if (regularConversations.isEmpty && requestConversations.isEmpty && contacts.isEmpty && _searchQuery.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: sizes.messagesEmptyStateVerticalPad),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.chat_bubble_outline, color: mutedTextColor.withOpacity(0.5), size: sizes.messagesEmptyStateIcon),
                                  SizedBox(height: sizes.screenHeight * 0.015),
                                  Text('no_conversations_yet_label'.tr(), textAlign: TextAlign.center, style: TextStyle(color: mutedTextColor)),
                                ],
                              ),
                            ),
                          )
                        else if (regularConversations.isEmpty &&
                            requestConversations.isEmpty &&
                            otherSearchResults.isEmpty &&
                            !_isSearchingUsers &&
                            _searchQuery.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: sizes.messagesEmptyStateVerticalPad * 0.5),
                            child: Center(child: Text('search_no_results_error'.tr(), style: TextStyle(color: mutedTextColor))),
                          )
                        else
                          for (final conv in regularConversations) ...[
                            _conversationRow(sizes, conv, mutedTextColor),
                            SizedBox(height: sizes.messagesConvGap),
                          ],

                        // ------------------------------------------------
                        // 🔵 ZID (kifma tlab: "recherche... des proposition
                        // lel asemi eli mawjoudin fel app... kif nenzel
                        // ala chkoun ma kenetch anna reservation en
                        // commun... yjih comme une invitation") - AY
                        // user fel app (autocomplete live), mch ghir
                        // contacts/conversations mawjoudin déjà.
                        // ------------------------------------------------
                        if (_searchQuery.isNotEmpty) ...[
                          if (_isSearchingUsers)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.02),
                              child: const Center(child: CircularProgressIndicator()),
                            )
                          else if (otherSearchResults.isNotEmpty) ...[
                            SizedBox(height: sizes.messagesSectionGap * 0.6),
                            Text(
                              'chat_other_users_section_label'.tr(),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.messagesConvNameFontSize * 0.9, color: mutedTextColor),
                            ),
                            SizedBox(height: sizes.messagesConvGap),
                            for (final user in otherSearchResults) ...[
                              _searchResultRow(sizes, user, mutedTextColor),
                              SizedBox(height: sizes.messagesConvGap),
                            ],
                          ],
                        ],

                        SizedBox(height: sizes.myProfileBottomGap),
                      ],
                    ),
            ),
            const CustomBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _contactBubble(AppSizes sizes, ChatContact contact) {
    return GestureDetector(
      onTap: () => _openContact(contact),
      child: SizedBox(
        width: sizes.messagesBubbleNameWidth,
        child: Column(
          children: [
            Container(
              width: sizes.messagesBubbleSize,
              height: sizes.messagesBubbleSize,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.pinkpetsy, AppColors.vertpetsy]),
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).scaffoldBackgroundColor),
                child: ClipOval(
                  child: contact.photoUrl != null
                      ? Image.network(contact.photoUrl!, fit: BoxFit.cover)
                      : Container(
                          color: AppColors.pinkpetsy.withOpacity(0.18),
                          child: Icon(Icons.person, color: AppColors.pinkpetsy, size: sizes.messagesBubbleSize * 0.5),
                        ),
                ),
              ),
            ),
            SizedBox(height: sizes.messagesBubbleNameGap),
            Text(
              contact.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: sizes.messagesBubbleNameFontSize),
            ),
          ],
        ),
      ),
    );
  }

  Widget _conversationRow(AppSizes sizes, ConversationSummary conv, Color mutedTextColor) {
    final bool unread = conv.unreadCount > 0;
    // 🔵 ZID (kifma tlab: "demande de message") - "isRequest" (ANA el
    // recipient, mestanni n5tar) - preview b'loun/gras 5ass (violet)
    // bch ma tfout-hach, nafs mant9 "unread" lakin loun mkhtalef.
    final bool isRequest = conv.status == 'pending' && !conv.isInitiator;
    final Color previewColor = isRequest
        ? const Color(0xFF9575CD)
        : (unread ? (Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textDark) : mutedTextColor);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openConversation(conv),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.messagesConvPaddingV),
        child: Row(
          children: [
            Container(
              width: sizes.messagesConvAvatarSize,
              height: sizes.messagesConvAvatarSize,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.vertpetsy.withOpacity(0.18)),
              child: conv.otherUserPhotoUrl != null
                  ? Image.network(conv.otherUserPhotoUrl!, fit: BoxFit.cover)
                  : Icon(Icons.person, color: AppColors.vertpetsy, size: sizes.messagesConvAvatarSize * 0.5),
            ),
            SizedBox(width: sizes.messagesConvRowGap * 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.otherUserName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: sizes.messagesConvNameFontSize, fontWeight: (unread || isRequest) ? FontWeight.bold : FontWeight.w600),
                  ),
                  SizedBox(height: sizes.messagesConvGap),
                  Text(
                    _previewFor(conv),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: sizes.messagesConvPreviewFontSize,
                      color: previewColor,
                      fontWeight: (unread || isRequest) ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: sizes.messagesConvRowGap),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_timeLabel(conv.lastMessageAt), style: TextStyle(fontSize: sizes.messagesConvTimeFontSize, color: mutedTextColor)),
                if (unread) ...[
                  SizedBox(height: sizes.messagesConvGap),
                  Container(
                    constraints: BoxConstraints(minWidth: sizes.messagesUnreadBadgeMinWidth),
                    padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.015, vertical: sizes.screenWidth * 0.008),
                    decoration: BoxDecoration(color: AppColors.pinkpetsy, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${conv.unreadCount}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: sizes.messagesUnreadBadgeFontSize, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // _searchResultRow (kifma tlab: "recherche... des proposition lel
  // asemi eli mawjoudin fel app... yjih comme une invitation")
  // ============================================================================
  // 🔵 user mn app el kol (mch contact/conversation déjà mawjouda) -
  // tap -> _openSearchResult -> startConversation (backend ye5tar
  // wa7dou "pending"/"accepted" 7asb ken fama booking beynethom).
  // ============================================================================
  Widget _searchResultRow(AppSizes sizes, UserSearchResult user, Color mutedTextColor) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openSearchResult(user),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: sizes.messagesConvPaddingV),
        child: Row(
          children: [
            Container(
              width: sizes.messagesConvAvatarSize,
              height: sizes.messagesConvAvatarSize,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.vertpetsy.withOpacity(0.18)),
              child: user.photoUrl != null
                  ? Image.network(user.photoUrl!, fit: BoxFit.cover)
                  : Icon(Icons.person, color: AppColors.vertpetsy, size: sizes.messagesConvAvatarSize * 0.5),
            ),
            SizedBox(width: sizes.messagesConvRowGap * 2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: sizes.messagesConvNameFontSize, fontWeight: FontWeight.w600),
                  ),
                  if (user.city != null && user.city!.isNotEmpty) ...[
                    SizedBox(height: sizes.messagesConvGap),
                    Text(
                      user.city!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: sizes.messagesConvPreviewFontSize, color: mutedTextColor),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.send_outlined, color: AppColors.vertpetsy, size: sizes.messagesConvNameFontSize),
          ],
        ),
      ),
    );
  }
}