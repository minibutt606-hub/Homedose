import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:homedose/services/cloudinary_service.dart';

class UpdateUserService {
  static const String _url = 'https://homedose.tecclubb.com/api/user';

  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? profileImagePath,
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

      request.fields['_method'] = 'PUT';

      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
      }
      if (email != null && email.isNotEmpty) {
        request.fields['email'] = email;
      }

      if (profileImagePath != null && profileImagePath.isNotEmpty) {
        // Always send the file to the backend
        request.files.add(await http.MultipartFile.fromPath(
          'profile_image',
          profileImagePath,
        ));
        
        final cloudinaryUrl = await CloudinaryService.uploadImage(profileImagePath);
        if (cloudinaryUrl != null) {
          finalCloudinaryUrl = cloudinaryUrl;
          request.fields['profile_image_url'] = cloudinaryUrl;
          // We don't overwrite 'profile_image' field here, since it's already sent as a file
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final userObj = data['user'] as Map<String, dynamic>?;
        if (userObj != null) {
          if (finalCloudinaryUrl != null) {
            final userId = userObj['id'].toString();
            storage.write('custom_avatar_user_$userId', finalCloudinaryUrl);
            userObj['profile_image'] = finalCloudinaryUrl;
            userObj['profile_image_url'] = finalCloudinaryUrl;
          }
          await storage.write('user', userObj);
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'user': userObj,
        };
      } else {
        String errorMessage = data['message'] ?? 'Update failed';
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
