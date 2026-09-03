import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:homedose/models/chat_model.dart';

class ListChatsService {
  static const String _url = 'https://homedose.tecclubb.com/api/chats';

  static Future<Map<String, dynamic>> listChats() async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final headers = {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse(_url),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<ChatModel> chats = [];
        if (data['data'] != null && data['data'] is List) {
          chats = (data['data'] as List)
              .map((item) => ChatModel.fromJson(item))
              .toList();
        }
        return {
          'success': true,
          'chats': chats,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load chats',
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
