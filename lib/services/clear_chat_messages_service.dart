import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ClearChatMessagesService {
  static const String _baseUrl = 'https://homedose.tecclubb.com/api/chats';

  static Future<Map<String, dynamic>> clearChatMessages(int chatId) async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final headers = {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.delete(
        Uri.parse('$_baseUrl/$chatId/messages'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Chat cleared successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to clear chat messages',
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
