import 'dart:convert';
import 'package:crypto/crypto.dart';

void main() {
  int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  String apiSecret = "czCIwq8wcz1BdqbY1CIFhVjH76E";
  String strToSign = "timestamp=$timestamp$apiSecret";
  String signature = sha1.convert(utf8.encode(strToSign)).toString();
  print(signature);
}
