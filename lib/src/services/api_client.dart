import 'dart:convert';
import 'dart:developer' as developer;

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  void _log(String message) {
    developer.log(message, name: 'PhotoDukan.ApiClient');
  }

  Future<Map<String, dynamic>> syncUser(
    String idToken, {
    String? phoneNumber,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/sync');
    final payload = <String, dynamic>{
      'phoneNumber': phoneNumber,
    };
    _log(
      'syncUser start uri=$uri tokenLength=${idToken.length} tokenPrefix=${idToken.substring(0, idToken.length < 12 ? idToken.length : 12)} phoneNumber=${phoneNumber ?? 'none'}',
    );

    final response = await _client.post(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );

    _log(
      'syncUser response status=${response.statusCode} body=${response.body.length > 600 ? '${response.body.substring(0, 600)}...' : response.body}',
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      _log('syncUser failure error=${json['error']}');
      throw ApiException(json['error']?.toString() ?? 'Failed to sync user.');
    }

    _log('syncUser success keys=${json.keys.join(',')}');

    return json;
  }
}

class ApiException implements Exception {
  ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}