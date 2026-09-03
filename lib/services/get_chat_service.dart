import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:homedose/models/chat_model.dart';

class GetChatService {
  static const String _baseUrl = 'https://homedose.tecclubb.com/api/chats';

  static Future<Map<String, dynamic>> getChat(int chatId) async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final headers = {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/$chatId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final chat = ChatModel.fromJson(data['data'] ?? data);
        return {
          'success': true,
          'chat': chat,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load chat details',
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
