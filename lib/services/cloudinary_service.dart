import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dyqwodji3';
  static const String _apiKey = '887399943938898';
  static const String _apiSecret = 'czCIwq8wcz1BdqbY1CIFhVjH76E';

  /// Uploads a file to Cloudinary and returns the secure URL
  static Future<String?> uploadImage(String filePath) async {
    try {
      int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      // Signature string requires timestamp and apiSecret
      String strToSign = "timestamp=$timestamp$_apiSecret";
      String signature = sha1.convert(utf8.encode(strToSign)).toString();

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['api_key'] = _apiKey
        ..fields['timestamp'] = timestamp.toString()
        ..fields['signature'] = signature;

      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['secure_url'];
      } else {
        print("Cloudinary Upload Error: $responseBody");
        return null;
      }
    } catch (e) {
      print("Cloudinary Exception: $e");
      return null;
    }
  }
}
