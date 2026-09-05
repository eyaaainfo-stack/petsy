import '../services/api_service.dart';

enum ChatMessageType { text, image }

// ============================================================================
// ChatMessage (chat_screen.dart - kifma tlab: "interface moderne fiha
// just les message ecrit w camera")
// ============================================================================
class ChatMessage {
  final String id;
  final String senderId;
  final ChatMessageType type;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isMine;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.type,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    required this.isMine,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, {required String myUserId}) {
    final String? rawImageUrl = json['imageUrl'] as String?;
    final String senderId = json['sender'] as String? ?? '';

    return ChatMessage(
      id: json['_id'] as String? ?? '',
      senderId: senderId,
      type: (json['type'] as String?) == 'image' ? ChatMessageType.image : ChatMessageType.text,
      text: json['text'] as String? ?? '',
      imageUrl: (rawImageUrl != null && rawImageUrl.isNotEmpty) ? '${ApiService.mediaBaseUrl}$rawImageUrl' : null,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      isMine: senderId == myUserId,
    );
  }
}