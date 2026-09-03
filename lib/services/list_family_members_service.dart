import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:homedose/models/family_member.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:homedose/services/login_service.dart';
import 'package:homedose/screens/get_started/get_started_screen.dart';

class ListFamilyMembersService {
  static const String _url = 'https://homedose.tecclubb.com/api/family-members';

  static Future<Map<String, dynamic>> listFamilyMembers() async {
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

      if (response.statusCode == 200) {
        List<FamilyMember> members = [];
        if (data['data'] != null && data['data'] is List) {
          members = (data['data'] as List)
              .map((item) => FamilyMember.fromJson(item))
              .toList();
        }
        return {
          'success': true,
          'members': members,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load family members',
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
