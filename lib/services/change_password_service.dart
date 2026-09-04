import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class ChangePasswordService {
  static const String _url = 'https://xpanel.tecclub.site/api/v1/me/password';

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.put(
        Uri.parse(_url),
        headers: headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Password updated successfully.',
          'data': data,
        };
      } else {
        String errorMessage = data['message'] ?? 'Failed to update password';
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstKey = errors.keys.first;
            final firstVal = errors[firstKey];
            if (firstVal is List && firstVal.isNotEmpty) {
              errorMessage = firstVal.first.toString();
            } else if (firstVal is String) {
              errorMessage = firstVal;
            }
          }
        }
        return {
          'success': false,
          'message': errorMessage,
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
