import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:homedose/services/login_service.dart';
import 'package:homedose/screens/get_started/get_started_screen.dart';

class SubmitFeedbackService {
  static const String _url = 'https://homedose.tecclubb.com/api/feedback';

  static Future<Map<String, dynamic>> submitFeedback({
    required String subject,
    required String email,
    required String message,
  }) async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final body = jsonEncode({
        'subject': subject,
        'email': email,
        'message': message,
      });

      final response = await http.post(
        Uri.parse(_url),
        headers: headers,
        body: body,
      );

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        await LoginService.logout();
        await Get.deleteAll(force: true);
        Get.offAll(() => const GetStartedScreen());
        Get.snackbar(
          'Session Expired',
          'Please login again to continue.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          margin: const EdgeInsets.all(15),
        );
        return {
          'success': false,
          'message': 'Session expired',
        };
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Feedback submitted successfully',
        };
      } else {
        // Parse validation errors
        String errorMessage = data['message'] ?? 'Failed to submit feedback';
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
}
