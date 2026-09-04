import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

void main() async {
  const baseUrl = 'https://xpanel.tecclub.site/api/v1';
  final random = Random().nextInt(100000);
  final email = 'testuser$random@example.com';
  final password = 'password123';
  final newPassword = 'newpassword123';

  print('1. Registering user: $email');
  final registerRes = await http.post(
    Uri.parse('$baseUrl/signup'),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    body: jsonEncode({
      'name': 'Test User',
      'email': email,
      'password': password,
      'password_confirmation': password,
    }),
  );

  print('Register Status: ${registerRes.statusCode}');
  print('Register Body: ${registerRes.body}');
  if (registerRes.statusCode != 200 && registerRes.statusCode != 201) return;

  print('\n2. Logging in to obtain bearer token:');
  final loginRes = await http.post(
    Uri.parse('$baseUrl/login'),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'password': password,
      'device': {
        'fingerprint': 'test_fp_$random',
        'name': 'Test Device',
      },
    }),
  );

  print('Login Status: ${loginRes.statusCode}');
  final loginData = jsonDecode(loginRes.body);
  final token = loginData['data']['token'];
  print('Token: $token');

  print('\n3. Testing Password Update (PUT $baseUrl/me/password)');
  final updatePassRes = await http.put(
    Uri.parse('$baseUrl/me/password'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'current_password': password,
      'password': newPassword,
      'password_confirmation': newPassword,
    }),
  );

  print('Status: ${updatePassRes.statusCode}');
  print('Body: ${updatePassRes.body}');
}
