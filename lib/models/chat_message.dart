import 'package:uuid/uuid.dart';
import 'package:get_storage/get_storage.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? attachmentUrl;
  final String? localAttachmentPath;

  ChatMessage({
    String? id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.attachmentUrl,
    this.localAttachmentPath,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final String text = json['content'] ?? json['text'] ?? '';
    
    final String? role = json['role']?.toString().toLowerCase().trim();
    bool isUser = false; // Default to AI

    final String? senderStr = json['sender']?.toString().toLowerCase().trim();

    if (role != null && role.isNotEmpty) {
      isUser = (role == 'user');
    } else if (senderStr != null && senderStr.isNotEmpty) {
      isUser = (senderStr == 'user');
    } else if (json['is_user'] != null) {
      isUser = json['is_user'] == true || json['is_user'] == 1 || json['is_user'] == 'true';
    } else if (json['isUser'] != null) {
      isUser = json['isUser'] == true || json['isUser'] == 1 || json['isUser'] == 'true';
    } else {
      try {
        final storage = GetStorage();
        final user = storage.read('user');
        if (user != null && user['id'] != null) {
          final currentUserId = user['id'].toString();
          if (json['sender_id'] != null) {
            isUser = json['sender_id'].toString() == currentUserId;
          } else if (json['family_member_id'] != null) {
            isUser = false; 
          }
        }
      } catch (_) {}
    }

    final String parsedId = json['id']?.toString() ?? const Uuid().v4();
    final DateTime timestamp = json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : (json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now());
        
    final String? attachmentUrl = json['attachment'] ?? json['attachment_url'];

    // Local fix for AI message roles being lost by the backend
    try {
      final storage = GetStorage();
      final List<dynamic> aiMessageIds = storage.read('ai_message_ids') ?? [];
      if (aiMessageIds.contains(parsedId) || aiMessageIds.contains(int.tryParse(parsedId) ?? -1)) {
        isUser = false;
      }
    } catch (_) {}

    return ChatMessage(
      id: parsedId,
      text: text,
      isUser: isUser,
      timestamp: timestamp,
      attachmentUrl: attachmentUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'attachmentUrl': attachmentUrl,
      'localAttachmentPath': localAttachmentPath,
    };
  }
}
