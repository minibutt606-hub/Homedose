import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  // We need the token. Since GetStorage uses a file, let's read the file directly.
  final path = '/Users/sohaib/Documents/Muneeb/homedose/.get_storage/GetStorage.gs';
  final file = File(path);
  if (!file.existsSync()) {
    print("Storage file not found.");
    return;
  }
  
  final content = file.readAsStringSync();
  final data = jsonDecode(content);
  final token = data['token'];
  
  if (token == null) {
    print("Token not found.");
    return;
  }
  
  final response = await http.get(
    Uri.parse('https://homedose.tecclubb.com/api/chats'),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  
  print("Status: ${response.statusCode}");
  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    // Print the first chat's messages
    if (body['data'] != null && body['data'].isNotEmpty) {
      print(jsonEncode(body['data'][0]));
    } else if (body['chats'] != null && body['chats'].isNotEmpty) {
      print(jsonEncode(body['chats'][0]));
    } else {
      print(body);
    }
  } else {
    print(response.body);
  }
}
