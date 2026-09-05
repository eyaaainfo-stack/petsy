import '../services/api_service.dart';

// ============================================================================
// ChatContact ("bulle" - messages_list_screen.dart)
// ============================================================================
// 🔵 ZID (messagerie - kifma tlab: "des acteures eli saret binetna kbal
// ya cnv ya reservation, w ththom les bull... tnaajem teswipihom aala
// jnab") - acteur (owner/sitter) elli déjà 3andna m3ah conversation
// wla reservation. "conversationId" null lowkan mazel ma badech
// conversation (chat ynajjam yetweled lowkan el user y-tapi 3al bulle).
// ============================================================================
class ChatContact {
  final String userId;
  final String fullName;
  final String? photoUrl;
  final String? city;
  final String? role;
  final String? conversationId;
  final DateTime lastActivityAt;

  const ChatContact({
    required this.userId,
    required this.fullName,
    this.photoUrl,
    this.city,
    this.role,
    this.conversationId,
    required this.lastActivityAt,
  });

  factory ChatContact.fromJson(Map<String, dynamic> json) {
    final String? rawPhotoUrl = json['photoUrl'] as String?;
    return ChatContact(
      userId: json['userId'] as String? ?? '',
      fullName: (json['fullName'] as String?)?.trim().isNotEmpty == true ? json['fullName'] as String : '',
      photoUrl: (rawPhotoUrl != null && rawPhotoUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawPhotoUrl' : null,
      city: json['city'] as String?,
      role: json['role'] as String?,
      conversationId: json['conversationId'] as String?,
      lastActivityAt: DateTime.tryParse(json['lastActivityAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}