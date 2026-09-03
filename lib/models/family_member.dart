import 'package:uuid/uuid.dart';

class FamilyMember {
  final String id;
  final String name;
  final String? profilePicture;
  final String gender;
  final String relationship;
  final String? threadsDetail;
  final int? chatId;
  final String? lastMessage;
  final DateTime? updatedAt;

  FamilyMember({
    String? id,
    required this.name,
    this.profilePicture,
    required this.gender,
    required this.relationship,
    this.threadsDetail,
    this.chatId,
    this.lastMessage,
    this.updatedAt,
  }) : id = id ?? const Uuid().v4();

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      profilePicture: json['profile_picture'] ?? json['profile_image'] ?? json['profile_image_url'] ?? json['profilePicture'],
      gender: json['gender'] ?? 'male',
      relationship: json['relationship'] ?? '',
      threadsDetail: json['threads'] ?? json['threadsDetail'],
      chatId: json['chat_id'] is int ? json['chat_id'] : int.tryParse(json['chat_id']?.toString() ?? ''),
      lastMessage: json['last_message']?.toString(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profile_image': profilePicture,
      'gender': gender,
      'relationship': relationship,
      'threads': threadsDetail,
      'chat_id': chatId,
      'last_message': lastMessage,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }
}
