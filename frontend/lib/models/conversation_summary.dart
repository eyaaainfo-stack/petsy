import '../services/api_service.dart';

// ============================================================================
// ConversationSummary (liste el conversations - messages_list_screen.dart,
// taht el bulles - kifma tlab: "kif nenzel ala messagerie nhbha tjini
// kima messenger... w ththom les cnv")
// ============================================================================
class ConversationSummary {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final String lastMessage;
  final String lastMessageType; // 'text' | 'image'
  final DateTime lastMessageAt;
  final bool lastMessageIsMine;
  final int unreadCount;
  // 🔵 ZID (kifma tlab: "demande de message... kima invitation par
  // message wel user lekher yakhtar yokblou wle yorfodh") - status:
  // 'accepted' (conversation 3adiya) / 'pending' (demande mestanniya
  // Accepter/Refuser) / 'declined' (rafedh). "isInitiator": ana elli
  // bdit el conversation (bark lowkan pending/declined).
  final String status;
  final bool isInitiator;

  const ConversationSummary({
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    required this.lastMessage,
    required this.lastMessageType,
    required this.lastMessageAt,
    required this.lastMessageIsMine,
    required this.unreadCount,
    this.status = 'accepted',
    this.isInitiator = false,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? other = json['otherUser'] as Map<String, dynamic>?;
    final String? rawPhotoUrl = other?['photoUrl'] as String?;

    return ConversationSummary(
      conversationId: json['conversationId'] as String? ?? '',
      otherUserId: other?['userId'] as String? ?? '',
      otherUserName: other?['fullName'] as String? ?? '',
      otherUserPhotoUrl: (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawPhotoUrl' : null,
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageType: json['lastMessageType'] as String? ?? 'text',
      lastMessageAt: DateTime.tryParse(json['lastMessageAt'] as String? ?? '') ?? DateTime.now(),
      lastMessageIsMine: json['lastMessageIsMine'] as bool? ?? false,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'accepted',
      isInitiator: json['isInitiator'] as bool? ?? false,
    );
  }
}