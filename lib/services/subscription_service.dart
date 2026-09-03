import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:homedose/services/login_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:homedose/screens/get_started/get_started_screen.dart';

class SubscriptionService {
  static const String _baseUrl = 'https://homedose.tecclubb.com/api';

  // Helper to handle 401 Unauthorized globally
  static Future<bool> _handleAuthFailure(http.Response response) async {
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
      return true;
    }
    return false;
  }

  // 1. GET /api/plans (Public)
  static Future<Map<String, dynamic>> getPlans() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/plans'),
        headers: {
          'Accept': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'plans': data['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load subscription plans',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // 2. GET /api/subscriptions/active (Requires Auth)
  static Future<Map<String, dynamic>> getActiveSubscription() async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final response = await http.get(
        Uri.parse('$_baseUrl/subscriptions/active'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (await _handleAuthFailure(response)) {
        return {'success': false, 'message': 'Session expired'};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'subscription': data['data'], // Can be null if no subscription exists
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load active subscription',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // 3. POST /api/subscriptions (Requires Auth)
  static Future<Map<String, dynamic>> createSubscription(int planId) async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'plan_id': planId,
        }),
      );

      if (await _handleAuthFailure(response)) {
        return {'success': false, 'message': 'Session expired'};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'subscription': data['subscription'] ?? data['data'],
          'message': data['message'] ?? 'Subscription created successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create subscription',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }

  // 4. GET /api/subscriptions/history (Requires Auth)
  static Future<Map<String, dynamic>> getSubscriptionHistory({int page = 1}) async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final response = await http.get(
        Uri.parse('$_baseUrl/subscriptions/history?page=$page'),
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (await _handleAuthFailure(response)) {
        return {'success': false, 'message': 'Session expired'};
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'history': data['data'] ?? [],
          'meta': data['meta'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load subscription history',
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
