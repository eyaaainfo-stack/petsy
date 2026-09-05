import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../widgets/back_button.dart';
import '../../widgets/message_dialog.dart';
import '../../controllers/messages_controller.dart';
import '../../models/chat_message.dart';

// ============================================================================
// ChatScreen ("conversation" - kifma tlab: "nhbk tesnaali interface
// moderne fiha just les message ecrit w camera ki tenzel aliha tkhtr
// ya mel gal ya mel apareil photo")
// ============================================================================
// 🔵 Wsulha mel MessagesListScreen (bulle wla conversation el liste) -
// el conversation déjà mawjouda (conversationId 7a9i9i, twelled 9bal
// ma nefta7ou el écran hedha - chraht fel messages_list_screen.dart).
//
// 🔵 mafamech websocket fel backend (REST bark) - "polling" khfif (kol
// 4 secondes) bch el messages el jdad (mel tarf l'akhor) yban-w bla
// ma el user ye7taj y3awad yefte7 el écran.
// ============================================================================
class ChatScreen extends StatefulWidget {
  // 🔴 FIX (kifma tlab: "nhb el demande ma tkoun envoyee ella ma ykoun
  // fama message tebaath") - "null" = mafamech conversation 7a9i9iya
  // mazel (chat "fresh" - mel recherche/profil/bulle bla conversation
  // mawjouda) - twelled fel base GHIR ki l'user yeb3ath l'AWWEL message
  // (chraht fel _sendText/_pickAndSendImage).
  final String? conversationId;
  // 🔵 ZID: LEZEM l'ID tel tarf l'akhor (mch ghir el conversationId) -
  // bch nnajmou nab3thou l'AWWEL message ("create-on-demand") lowkan
  // mafamech conversation mazel.
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  // 🔵 ZID (kifma tlab: "demande de message... kima invitation par
  // message wel user lekher yakhtar yokblou wle yorfodh") - 'accepted'
  // (chat 3adi) / 'pending' (demande, mestanniya Accepter/Refuser) /
  // 'declined' (rafedh, read-only). "isInitiator": ANA elli bdit el
  // conversation (bark lowkan pending/declined me3na 7a9i9i).
  final String status;
  final bool isInitiator;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    this.status = 'accepted',
    this.isInitiator = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessagesController _controller = MessagesController();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _pollTimer;
  // 🔵 ZID (kifma tlab: "demande de message") - copie locale (mutable) -
  // tetbeddel direct ba3d Accepter/Refuser (bla ma nestanniw refetch).
  late String _status;
  bool _isRespondingToRequest = false;
  // 🔴 FIX (kifma tlab: "nhb el demande ma tkoun envoyee ella ma ykoun
  // fama message tebaath") - copie locale mutable (widget.conversationId
  // ynajjam ykoun null l'wa9t el bidaya, w yetbeddel l'ID 7a9i9i ba3d
  // AWWEL message metba3eth).
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _status = widget.status;
    _conversationId = widget.conversationId;
    if (_conversationId != null) {
      _load(scrollToBottom: true);
      _startPolling();
    } else {
      // 🔵 chat "fresh" (conversationId null) - mafamech messages
      // nel9awhom, el user lissa ma badech ykteb - "no messages yet"
      // direct, bla appel API zeyed.
      _isLoading = false;
    }
  }

  // 🔵 ZID: polling - nafs conversation tetjeddad automatique lowkan
  // el tarf l'akhor yeb3ath message (bla refresh manuel mel user) -
  // testa3mel GHIR ki fama conversationId 7a9i9i (mafamech me3na
  // "polling" 3ala conversation ma twelledetch mazel fel base).
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _load(scrollToBottom: false, silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load({required bool scrollToBottom, bool silent = false}) async {
    if (_conversationId == null) return;
    if (!silent) setState(() => _isLoading = true);
    final messages = await _controller.fetchMessages(_conversationId!);
    if (!mounted) return;

    // 🔵 polling silencieux: n3addlou el liste GHIR ken fama taghyir
    // 7a9i9i (message jdid) - bch ma nkassrouch scroll position tel
    // user (mathalan lowkan 9a3ed ye9ra messages 9dam) bla lezma.
    final bool changed = messages.length != _messages.length ||
        (messages.isNotEmpty && _messages.isNotEmpty && messages.last.id != _messages.last.id);

    if (!silent || changed) {
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    }

    if (scrollToBottom || changed) _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendText() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textController.clear();

    // 🔴 FIX (kifma tlab: "nhb el demande ma tkoun envoyee ella ma ykoun
    // fama message tebaath") - conversationId null ("fresh") -> appel
    // "create-on-demand" (twalled el Conversation + tebaath l'AWWEL
    // message f'appel WA7ED, mch 9bal).
    if (_conversationId == null) {
      final result = await _controller.sendFirstText(widget.otherUserId, text);
      if (!mounted) return;

      if (result != null) {
        setState(() {
          _conversationId = result['conversationId'] as String;
          _status = result['status'] as String? ?? 'accepted';
          _messages = [..._messages, result['message'] as ChatMessage];
          _isSending = false;
        });
        _startPolling();
        _scrollToBottom();
      } else {
        setState(() => _isSending = false);
        showMessageDialog(context, 'chat_send_error'.tr());
      }
      return;
    }

    final sent = await _controller.sendText(_conversationId!, text);
    if (!mounted) return;

    if (sent != null) {
      setState(() {
        _messages = [..._messages, sent];
        _isSending = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isSending = false);
      showMessageDialog(context, 'chat_send_error'.tr());
    }
  }

  // 🔵 ZID (kifma tlab: "demande de message... el user lekher yakhtar
  // yokblou wle yorfodh") - ghir el recipient ynajjam ye5tar (chraht
  // fel backend, "isInitiator" ma yban-lhomch el boutons hedhom khaless).
  // 🔵 "_conversationId!" (bla '?') - Accepter/Refuser ma ynajjmouch
  // yban-w GHIR ki fama conversation 7a9i9iya déjà (chraht fel
  // _buildBottomBar: "pending" + !isInitiator, w chat "fresh" (null)
  // el user ykoun DIMA l'initiator, fa hedha el cas ma yousel-lou 9att).
  Future<void> _onAcceptRequest() async {
    if (_isRespondingToRequest) return;
    setState(() => _isRespondingToRequest = true);
    final success = await _controller.acceptConversation(_conversationId!);
    if (!mounted) return;
    if (success) {
      setState(() {
        _status = 'accepted';
        _isRespondingToRequest = false;
      });
    } else {
      setState(() => _isRespondingToRequest = false);
      showMessageDialog(context, 'chat_send_error'.tr());
    }
  }

  Future<void> _onDeclineRequest() async {
    if (_isRespondingToRequest) return;
    setState(() => _isRespondingToRequest = true);
    final success = await _controller.declineConversation(_conversationId!);
    if (!mounted) return;
    if (success) {
      // 🔵 rafedhna el demande - mafamech me3na nab9aw fel écran (mch
      // ynajjam yeb3ath 7atta) - nerja3ou lel liste conversations.
      Navigator.of(context).pop();
      return;
    }
    setState(() => _isRespondingToRequest = false);
    showMessageDialog(context, 'chat_send_error'.tr());
  }

  void _showAttachmentSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: AppColors.vertpetsy),
                title: Text('gallery_option'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_outlined, color: AppColors.vertpetsy),
                title: Text('camera_option'.tr()),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    if (_isSending) return;
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: source, imageQuality: 80);
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() => _isSending = true);

      // 🔴 FIX (kifma tlab: "nhb el demande ma tkoun envoyee ella ma
      // ykoun fama message tebaath") - nafs mant9 _sendText, lel 7ala
      // elli l'AWWEL message ykoun photo (mch text).
      if (_conversationId == null) {
        final result = await _controller.sendFirstImage(widget.otherUserId, bytes);
        if (!mounted) return;

        if (result != null) {
          setState(() {
            _conversationId = result['conversationId'] as String;
            _status = result['status'] as String? ?? 'accepted';
            _messages = [..._messages, result['message'] as ChatMessage];
            _isSending = false;
          });
          _startPolling();
          _scrollToBottom();
        } else {
          setState(() => _isSending = false);
          showMessageDialog(context, 'chat_send_error'.tr());
        }
        return;
      }

      final sent = await _controller.sendImage(_conversationId!, bytes);
      if (!mounted) return;

      if (sent != null) {
        setState(() {
          _messages = [..._messages, sent];
          _isSending = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _isSending = false);
        showMessageDialog(context, 'chat_send_error'.tr());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      showMessageDialog(context, 'photo_pick_error'.tr());
    }
  }

  void _openFullImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              Center(child: InteractiveViewer(child: Image.network(imageUrl))),
              const CustomBackButton(backgroundColor: Colors.white24, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  String _dayLabel(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diffDays = today.difference(date).inDays;

    if (diffDays == 0) return 'today_label'.tr();
    if (diffDays == 1) return 'yesterday_label'.tr();
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (diffDays < 7) return weekdays[dateTime.weekday - 1];
    return '${date.day}/${date.month}/${date.year}';
  }

  String _timeLabel(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final sizes = AppSizes.of(context);
    final Color mutedTextColor = Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.55) ?? Colors.grey;
    final Color otherBubbleColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFF1F1F3);
    final Color otherBubbleTextColor = Theme.of(context).textTheme.bodyLarge?.color ?? AppColors.textDark;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // ------------------------------------------------------
            // Header: back + avatar + esm tel tarf l'akhor.
            // ------------------------------------------------------
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sizes.chatHeaderPaddingH, vertical: sizes.chatHeaderPaddingV),
              child: Row(
                children: [
                  // 🔵 FIX: kanet SizedBox (placeholder bark, mansiya) -
                  // el bouton "retour" (kifma tlab: "win el back button
                  // fel cnv eli nerjaa biha win kont") ma kanch mawjoud
                  // 7a9i9i - el user ma3andouch 7al ynejjam yerja3 lel
                  // liste conversations. CustomBackButton (Positioned)
                  // ma ye5demch houni - el header f'Row 3adiya (Column,
                  // mch Stack), fa bouton "inline" (nafs style: circle +
                  // arrow_back).
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(50),
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        width: sizes.screenWidth * 0.09,
                        height: sizes.screenWidth * 0.09,
                        decoration: BoxDecoration(color: otherBubbleColor, shape: BoxShape.circle),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: sizes.screenWidth * 0.042, color: otherBubbleTextColor),
                      ),
                    ),
                  ),
                  SizedBox(width: sizes.screenWidth * 0.025),
                  Container(
                    width: sizes.chatHeaderAvatarSize,
                    height: sizes.chatHeaderAvatarSize,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.pinkpetsy.withOpacity(0.18)),
                    child: widget.otherUserPhotoUrl != null
                        ? Image.network(widget.otherUserPhotoUrl!, fit: BoxFit.cover)
                        : Icon(Icons.person, color: AppColors.pinkpetsy, size: sizes.chatHeaderAvatarSize * 0.55),
                  ),
                  SizedBox(width: sizes.screenWidth * 0.03),
                  Expanded(
                    child: Text(
                      widget.otherUserName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: sizes.chatHeaderNameFontSize),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: mutedTextColor.withOpacity(0.15)),

            // ------------------------------------------------------
            // 🔵 ZID (kifma tlab: "demande de message") - banner "en
            // attente" - ghir lel initiator (mch el recipient - houwa
            // 3andou les boutons Accepter/Refuser bدal el banner).
            // ------------------------------------------------------
            if (_status == 'pending' && widget.isInitiator)
              Container(
                width: double.infinity,
                color: const Color(0xFF9575CD).withOpacity(0.12),
                padding: EdgeInsets.symmetric(horizontal: sizes.chatHeaderPaddingH, vertical: sizes.screenHeight * 0.01),
                child: Text(
                  'chat_request_pending_sender_label'.tr(namedArgs: {'name': widget.otherUserName}),
                  style: TextStyle(fontSize: sizes.chatDateSeparatorFontSize, color: const Color(0xFF9575CD), fontWeight: FontWeight.w600),
                ),
              )
            else if (_status == 'declined')
              Container(
                width: double.infinity,
                color: AppColors.error.withOpacity(0.1),
                padding: EdgeInsets.symmetric(horizontal: sizes.chatHeaderPaddingH, vertical: sizes.screenHeight * 0.01),
                child: Text(
                  'chat_request_declined_label'.tr(),
                  style: TextStyle(fontSize: sizes.chatDateSeparatorFontSize, color: AppColors.error, fontWeight: FontWeight.w600),
                ),
              ),

            // ------------------------------------------------------
            // Messages
            // ------------------------------------------------------
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat_bubble_outline, color: mutedTextColor.withOpacity(0.5), size: sizes.chatEmptyStateIcon),
                              SizedBox(height: sizes.screenHeight * 0.015),
                              Text('chat_empty_label'.tr(), style: TextStyle(color: mutedTextColor)),
                            ],
                          ),
                        )
                      : ListView(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(horizontal: sizes.chatListPaddingH, vertical: sizes.chatListPaddingV),
                          children: _buildMessageItems(sizes, otherBubbleColor, otherBubbleTextColor),
                        ),
            ),

            // ------------------------------------------------------
            // Input bar: camera (gal/appareil photo) + texte + envoyer -
            // WALA Accepter/Refuser (kifma tlab: "demande de message"),
            // WALA read-only ("declined") - chraht fel _buildBottomBar.
            // ------------------------------------------------------
            _buildBottomBar(sizes, otherBubbleColor),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildMessageItems(AppSizes sizes, Color otherBubbleColor, Color otherBubbleTextColor) {
    final List<Widget> items = [];
    DateTime? lastDay;

    for (final message in _messages) {
      final local = message.createdAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      if (lastDay == null || day != lastDay) {
        items.add(Padding(
          padding: EdgeInsets.symmetric(vertical: sizes.chatDateSeparatorGap),
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.03, vertical: sizes.screenWidth * 0.012),
              decoration: BoxDecoration(color: otherBubbleColor, borderRadius: BorderRadius.circular(12)),
              child: Text(_dayLabel(local), style: TextStyle(fontSize: sizes.chatDateSeparatorFontSize, fontWeight: FontWeight.w600)),
            ),
          ),
        ));
        lastDay = day;
      }
      items.add(_messageBubble(sizes, message, otherBubbleColor, otherBubbleTextColor));
    }
    return items;
  }

  Widget _messageBubble(AppSizes sizes, ChatMessage message, Color otherBubbleColor, Color otherBubbleTextColor) {
    final bool mine = message.isMine;
    final Color bubbleColor = mine ? AppColors.pinkpetsy : otherBubbleColor;
    final Color textColor = mine ? Colors.white : otherBubbleTextColor;

    return Padding(
      padding: EdgeInsets.only(bottom: sizes.chatBubbleGap),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: sizes.chatBubbleMaxWidth),
            child: Column(
              crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (message.type == ChatMessageType.image && message.imageUrl != null)
                  GestureDetector(
                    onTap: () => _openFullImage(message.imageUrl!),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(sizes.chatBubbleImageRadius),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: sizes.chatBubbleImageMaxWidth),
                        child: Image.network(message.imageUrl!, fit: BoxFit.cover),
                      ),
                    ),
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: sizes.chatBubblePaddingH, vertical: sizes.chatBubblePaddingV),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(mine ? 18 : 4),
                        bottomRight: Radius.circular(mine ? 4 : 18),
                      ),
                    ),
                    child: Text(message.text, style: TextStyle(color: textColor, fontSize: sizes.chatBubbleFontSize)),
                  ),
                SizedBox(height: sizes.screenHeight * 0.003),
                Text(
                  _timeLabel(message.createdAt),
                  style: TextStyle(
                    fontSize: sizes.chatBubbleTimeFontSize,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5) ?? Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // _buildBottomBar (kifma tlab: "demande de message... el user lekher
  // yakhtar yokblou wle yorfodh")
  // ============================================================================
  // 🔵 3 7alet:
  //   1) "pending" + ANA el recipient (mch initiator) -> Accepter/Refuser
  //      BDAL l'input (ma nnajjmch neb3ath 7atta n5tar).
  //   2) "declined" -> mafamech 7aja (read-only, el banner fou9 déjà
  //      ywarri "rafedh" - lel initiator bark, chraht getConversations).
  //   3) el ba9i (accepted, wla pending+ana el initiator) -> input 3adi
  //      (camera + texte + envoyer, kifha kif kanet).
  // ============================================================================
  Widget _buildBottomBar(AppSizes sizes, Color otherBubbleColor) {
    if (_status == 'pending' && !widget.isInitiator) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sizes.chatInputBarPaddingH, vertical: sizes.chatInputBarPaddingV),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isRespondingToRequest ? null : _onDeclineRequest,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.016),
                  ),
                  child: Text('refuse_request_button'.tr(), style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                ),
              ),
              SizedBox(width: sizes.screenWidth * 0.03),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isRespondingToRequest ? null : _onAcceptRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.vertpetsy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.016),
                    elevation: 0,
                  ),
                  child: _isRespondingToRequest
                      ? SizedBox(
                          width: sizes.screenHeight * 0.02,
                          height: sizes.screenHeight * 0.02,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text('accept_request_button'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_status == 'declined') return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sizes.chatInputBarPaddingH, vertical: sizes.chatInputBarPaddingV),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              onPressed: _isSending ? null : _showAttachmentSourceSheet,
              icon: Icon(Icons.camera_alt_outlined, color: AppColors.vertpetsy, size: sizes.chatInputIcon),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: sizes.screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: otherBubbleColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontSize: sizes.chatInputFontSize),
                  decoration: InputDecoration(
                    hintText: 'chat_input_hint'.tr(),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: sizes.screenHeight * 0.015),
                  ),
                  onSubmitted: (_) => _sendText(),
                ),
              ),
            ),
            SizedBox(width: sizes.screenWidth * 0.02),
            Container(
              width: sizes.chatSendButtonSize,
              height: sizes.chatSendButtonSize,
              decoration: BoxDecoration(color: AppColors.pinkpetsy, shape: BoxShape.circle),
              child: IconButton(
                onPressed: _isSending ? null : _sendText,
                icon: _isSending
                    ? SizedBox(
                        width: sizes.chatSendButtonSize * 0.4,
                        height: sizes.chatSendButtonSize * 0.4,
                        child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(Icons.send_rounded, color: Colors.white, size: sizes.chatSendButtonSize * 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}