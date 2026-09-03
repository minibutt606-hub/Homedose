class ChatModel {
  final int chatId;
  final String title;
  final String name;
  final String? avatar;
  final int? familyMemberId;
  final String? lastMessage;
  final DateTime updatedAt;

  ChatModel({
    required this.chatId,
    required this.title,
    required this.name,
    this.avatar,
    this.familyMemberId,
    this.lastMessage,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      chatId: json['chat_id'] is int ? json['chat_id'] : int.parse(json['chat_id'].toString()),
      title: json['title'] ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      familyMemberId: json['family_member_id'] is int?
          ? json['family_member_id']
          : (json['family_member_id'] != null ? int.tryParse(json['family_member_id'].toString()) : null),
      lastMessage: json['last_message'],
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_id': chatId,
      'title': title,
      'name': name,
      'avatar': avatar,
      'family_member_id': familyMemberId,
      'last_message': lastMessage,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
