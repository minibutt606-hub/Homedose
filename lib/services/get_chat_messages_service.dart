import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:homedose/models/chat_message.dart';

class GetChatMessagesService {
  static const String _baseUrl = 'https://homedose.tecclubb.com/api/chats';

  static Future<Map<String, dynamic>> getChatMessages(int chatId) async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final headers = {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/$chatId/messages'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<ChatMessage> messages = [];
        if (data['data'] != null && data['data'] is List) {
          messages = (data['data'] as List)
              .map((item) => ChatMessage.fromJson(item))
              .toList();
        }
        return {
          'success': true,
          'messages': messages,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load messages',
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
