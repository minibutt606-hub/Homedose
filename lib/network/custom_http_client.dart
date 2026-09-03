import 'package:http/http.dart' as http;

class CustomHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['User-Agent'] = 'PostmanRuntime/7.39.0';
    return _inner.send(request);
  }
}
