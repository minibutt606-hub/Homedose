import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class DeleteUserService {
  static const String _url = 'https://homedose.tecclubb.com/api/user';

  static Future<Map<String, dynamic>> deleteAccount({
    required String password,
  }) async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.delete(
        Uri.parse(_url),
        headers: headers,
        body: jsonEncode({
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': data['message'] ?? 'Account deleted successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete account',
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
