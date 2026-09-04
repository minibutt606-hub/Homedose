import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class DeleteUserService {
  static const String _baseUrl = 'https://xpanel.tecclub.site/api/v1';
  static const String _deleteUrl = '$_baseUrl/me/delete';
  static const String _cancelUrl = '$_baseUrl/me/delete/cancel';

  static Future<Map<String, dynamic>> deleteAccount({
    String? password,
    String? reason,
  }) async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse(_deleteUrl),
        headers: headers,
        body: jsonEncode({
          'reason': reason ?? (password != null && password.isNotEmpty ? 'User requested deletion' : null),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': data['message'] ?? 'Account deletion scheduled.',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to schedule account deletion',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> cancelAccountDeletion() async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse(_cancelUrl),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Account deletion cancelled.',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to cancel account deletion',
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
