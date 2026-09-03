import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

void main() async {
  final random = Random().nextInt(100000);
  final email = 'testuser$random@example.com';
  final password = 'password123';
  final newPassword = 'newpassword123';

  print('Registering user: $email');
  final registerRes = await http.post(
    Uri.parse('https://homedose.tecclubb.com/api/register'),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': 'Test User',
      'email': email,
      'password': password,
      'password_confirmation': password,
      'phone': '1234567890',
    }),
  );

  if (registerRes.statusCode != 200 && registerRes.statusCode != 201) return;
  final token = jsonDecode(registerRes.body)['token'] ?? jsonDecode(registerRes.body)['access_token'];

  final endpoints = [
    'https://homedose.tecclubb.com/api/user/password',
    'https://homedose.tecclubb.com/api/user/change-password',
    'https://homedose.tecclubb.com/api/password/change',
    'https://homedose.tecclubb.com/api/password/update',
    'https://homedose.tecclubb.com/api/profile/password',
  ];

  for (var url in endpoints) {
    print('\\nTesting $url');
    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'current_password': password,
        'old_password': password,
        'password': newPassword,
        'password_confirmation': newPassword,
      }),
    );
    print('Status: ${res.statusCode}');
    if (res.statusCode != 404) {
       print('Body: ${res.body}');
    }
  }
}
