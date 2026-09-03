import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';

class LoginService {
  static const String _url = 'https://homedose.tecclubb.com/api/login';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save session details to local storage
        final storage = GetStorage();
        await storage.write('isLoggedIn', true);
        
        if (data['token'] != null) {
          await storage.write('token', data['token']);
        } else if (data['access_token'] != null) {
          await storage.write('token', data['access_token']);
        }
        
        if (data['user'] != null) {
          await storage.write('user', data['user']);
        }

        return {
          'success': true,
          'data': data,
        };
      } else {
        // Handle validation errors or custom message
        String errorMessage = data['message'] ?? 'Login failed';
        if (data['errors'] != null && data['errors'] is Map) {
          final errors = data['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstKey = errors.keys.first;
            final firstVal = errors[firstKey];
            if (firstVal is List && firstVal.isNotEmpty) {
              errorMessage = firstVal.first.toString();
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

  static Future<void> logout() async {
    final storage = GetStorage();
    await storage.remove('isLoggedIn');
    await storage.remove('token');
    await storage.remove('user');
    await storage.remove('activeSubscription');
  }
}
