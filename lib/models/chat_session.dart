import 'package:homedose/models/chat_message.dart';
import 'package:uuid/uuid.dart';

class ChatSession {
  final String id;
  final String memberId;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  DateTime updatedAt;

  ChatSession({
    String? id,
    required this.memberId,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      memberId: json['memberId'],
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get title {
    if (messages.isEmpty) return "New Chat";
    // Usually the title is derived from the first message
    final firstUserMsg = messages.firstWhere((m) => m.isUser, orElse: () => messages.first);
    if (firstUserMsg.text.length > 50) {
      return "${firstUserMsg.text.substring(0, 50)}...";
    }
    return firstUserMsg.text;
  }
}
