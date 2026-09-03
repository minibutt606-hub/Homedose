import 'dart:convert';

void main() async {
  final body = jsonEncode({
    'content': 'Test AI message',
    'chat_id': 1,
    'role': 'assistant'
  });
  
  print(body);
}
