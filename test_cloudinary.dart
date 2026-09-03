import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

void main() async {
  String cloudName = 'dyqwodji3';
  String apiKey = '887399943938898';
  String apiSecret = 'czCIwq8wcz1BdqbY1CIFhVjH76E';

  // Create a dummy image
  File testFile = File('test_image.jpg');
  await testFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00]);

  int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  String strToSign = "timestamp=$timestamp$apiSecret";
  String signature = sha1.convert(utf8.encode(strToSign)).toString();

  final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
  final request = http.MultipartRequest('POST', url)
    ..fields['api_key'] = apiKey
    ..fields['timestamp'] = timestamp.toString()
    ..fields['signature'] = signature;
  
  request.files.add(await http.MultipartFile.fromPath('file', testFile.path));

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();
  print("Status: ${response.statusCode}");
  print("Body: $responseBody");
}
