import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';

class LoginService {
  static const String _baseUrl = 'https://xpanel.tecclub.site/api/v1';
  static const String _url = '$_baseUrl/login';

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    final storage = GetStorage();
    String? fingerprint = storage.read('device_fingerprint');
    if (fingerprint == null || fingerprint.isEmpty) {
      fingerprint = const Uuid().v4();
      await storage.write('device_fingerprint', fingerprint);
    }

    String deviceName = 'Flutter Device';
    String? model;
    String? platform;
    String? os;

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        deviceName = webInfo.browserName.name;
        platform = 'web';
        os = webInfo.platform;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceName = '${androidInfo.manufacturer} ${androidInfo.model}';
        model = androidInfo.model;
        platform = 'android';
        os = 'Android ${androidInfo.version.release}';
        if (androidInfo.id.isNotEmpty) {
          fingerprint = androidInfo.id;
          await storage.write('device_fingerprint', fingerprint);
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
        model = iosInfo.model;
        platform = 'ios';
        os = '${iosInfo.systemName} ${iosInfo.systemVersion}';
        if (iosInfo.identifierForVendor != null && iosInfo.identifierForVendor!.isNotEmpty) {
          fingerprint = iosInfo.identifierForVendor!;
          await storage.write('device_fingerprint', fingerprint);
        }
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        deviceName = macInfo.computerName;
        model = macInfo.model;
        platform = 'macos';
        os = 'macOS ${macInfo.osRelease}';
      } else if (Platform.isWindows) {
        final winInfo = await deviceInfo.windowsInfo;
        deviceName = winInfo.computerName;
        model = winInfo.productName;
        platform = 'windows';
        os = 'Windows';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        deviceName = linuxInfo.prettyName;
        model = linuxInfo.name;
        platform = 'linux';
        os = 'Linux';
      }
    } catch (_) {}

    return {
      'fingerprint': fingerprint,
      'name': deviceName,
      'model': model,
      'platform': platform,
      'os': os,
      'app_version': '1.0.0',
    };
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final deviceData = await _getDeviceInfo();

      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'device': deviceData,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save session details to local storage
        final storage = GetStorage();
        await storage.write('isLoggedIn', true);

        // Support both direct and nested data structure from X Panel API
        final resData = data['data'] is Map ? data['data'] : data;
        final token = resData['token'] ?? data['token'] ?? data['access_token'];
        final user = resData['user'] ?? data['user'];

        if (token != null) {
          await storage.write('token', token);
        }
        if (user != null) {
          await storage.write('user', user);
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

  static Future<void> logout() async {
    final storage = GetStorage();
    final token = storage.read('token');

    if (token != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {}
    }

    await storage.remove('isLoggedIn');
    await storage.remove('token');
    await storage.remove('user');
    await storage.remove('activeSubscription');
  }
}
