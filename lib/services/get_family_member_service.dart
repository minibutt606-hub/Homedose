import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:homedose/models/family_member.dart';

class GetFamilyMemberService {
  static const String _baseUrl = 'https://homedose.tecclubb.com/api/family-members';

  static Future<Map<String, dynamic>> getFamilyMember(String id) async {
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final headers = {
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/$id'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final member = FamilyMember.fromJson(data['data'] ?? data);
        return {
          'success': true,
          'member': member,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load details',
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
