import "package:http/http.dart" as http;

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
}

class Auth {
  const Auth({required http.Client client, required String baseUrl})
    : _client = client,
      _baseUrl = baseUrl;

  final http.Client _client;
  final String _baseUrl;

  Future<void> login(String token) async {
    final response = await _client.post(
      Uri.parse("$_baseUrl/auth"),
      headers: {"Authorization": token},
    );

    switch (response.statusCode) {
      case 201:
        return;
      case 401:
        throw const AuthException("Invalid token");
      default:
        throw const AuthException("Unknown error");
    }
  }
}
