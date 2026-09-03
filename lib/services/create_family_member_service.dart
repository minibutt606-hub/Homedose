import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:homedose/models/family_member.dart';
import 'package:homedose/services/cloudinary_service.dart';

class CreateFamilyMemberService {
  static const String _url = 'https://homedose.tecclubb.com/api/family-members';

  static Future<Map<String, dynamic>> createFamilyMember({
    required String name,
    required String gender,
    required String relationship,
    String? threads,
    String? imagePath,
  }) async {
    String? finalCloudinaryUrl;
    try {
      final storage = GetStorage();
      final String? token = storage.read('token');

      final request = http.MultipartRequest('POST', Uri.parse(_url));
      
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.fields['name'] = name;
      request.fields['gender'] = gender.toLowerCase();
      request.fields['relationship'] = relationship;
      
      if (threads != null && threads.isNotEmpty) {
        request.fields['threads'] = threads;
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath(
          'profile_picture',
          imagePath,
        ));
        
        final cloudinaryUrl = await CloudinaryService.uploadImage(imagePath);
        if (cloudinaryUrl != null) {
          finalCloudinaryUrl = cloudinaryUrl;
          request.fields['profile_picture_url'] = cloudinaryUrl;
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final memberData = data['data'] ?? data;
        if (finalCloudinaryUrl != null) {
          final memberId = memberData['id'].toString();
          storage.write('custom_avatar_member_$memberId', finalCloudinaryUrl);
          memberData['profile_picture'] = finalCloudinaryUrl;
        }
        final newMember = FamilyMember.fromJson(memberData);
        return {
          'success': true,
          'member': newMember,
        };
      } else {
        // Parse validation errors
        String errorMessage = data['message'] ?? 'Failed to add family member';
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
