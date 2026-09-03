import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:homedose/models/chat_message.dart';
import 'package:homedose/services/cloudinary_service.dart';

class SendMessageService {
  static const String _url = 'https://homedose.tecclubb.com/api/messages';

  static Future<Map<String, dynamic>> sendMessage({
    required String content,
    int? familyMemberId,
    int? chatId,
    String? role,
    String? attachmentPath,
  }) async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final request = http.MultipartRequest('POST', Uri.parse(_url));

      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.fields['content'] = content;
      if (familyMemberId != null) request.fields['family_member_id'] = familyMemberId.toString();
      if (chatId != null) request.fields['chat_id'] = chatId.toString();
      if (role != null) request.fields['role'] = role;

      if (attachmentPath != null && attachmentPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'attachment',
          attachmentPath,
        ));
        
        final cloudinaryUrl = await CloudinaryService.uploadImage(attachmentPath);
        if (cloudinaryUrl != null) {
          request.fields['attachment_url'] = cloudinaryUrl;
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final chatData = data['chat'] as Map<String, dynamic>?;
        final messageData = data['message'] as Map<String, dynamic>?;
        
        ChatMessage? message;
        if (messageData != null) {
          message = ChatMessage.fromJson(messageData);
        }

        return {
          'success': true,
          'chatId': chatData != null ? chatData['id'] : null,
          'message': message,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send message',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
}
