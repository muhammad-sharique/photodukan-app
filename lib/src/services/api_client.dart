import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiMultipartFile {
  const ApiMultipartFile({
    required this.fieldName,
    required this.filename,
    required this.bytes,
    this.contentType,
  });

  final String fieldName;
  final String filename;
  final Uint8List bytes;
  final MediaType? contentType;
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  void _log(String message) {
    developer.log(message, name: 'PhotoDukan.ApiClient');
  }

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalizedPath').replace(
      queryParameters: queryParameters,
    );
  }

  Future<Map<String, dynamic>> _decodeResponse(http.Response response) async {
    final bodyText = response.body;
    _log(
      'response status=${response.statusCode} body=${bodyText.length > 600 ? '${bodyText.substring(0, 600)}...' : bodyText}',
    );

    final dynamic decoded = bodyText.isEmpty ? <String, dynamic>{} : jsonDecode(bodyText);
    final json = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{'data': decoded};

    if (response.statusCode >= 400) {
      throw ApiException(
        json['error']?.toString() ?? 'Request failed.',
        statusCode: response.statusCode,
        code: json['code']?.toString(),
        userMessage: json['userMessage']?.toString(),
        requestId: json['requestId']?.toString(),
      );
    }

    return json;
  }

  Map<String, String> _authorizedHeaders(String idToken, {bool isJson = true}) {
    final headers = <String, String>{
      'Authorization': 'Bearer $idToken',
    };
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  Future<Map<String, dynamic>> getJsonAuthorized(
    String path, {
    required String idToken,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    _log('getJsonAuthorized uri=$uri');
    final response = await _client.get(
      uri,
      headers: _authorizedHeaders(idToken, isJson: false),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postJsonAuthorized(
    String path, {
    required String idToken,
    required Map<String, dynamic> payload,
  }) async {
    final uri = _buildUri(path);
    _log('postJsonAuthorized uri=$uri payloadKeys=${payload.keys.join(',')}');
    final response = await _client.post(
      uri,
      headers: _authorizedHeaders(idToken),
      body: jsonEncode(payload),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> patchJsonAuthorized(
    String path, {
    required String idToken,
    required Map<String, dynamic> payload,
  }) async {
    final uri = _buildUri(path);
    _log('patchJsonAuthorized uri=$uri payloadKeys=${payload.keys.join(',')}');
    final response = await _client.patch(
      uri,
      headers: _authorizedHeaders(idToken),
      body: jsonEncode(payload),
    );
    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> postMultipartAuthorized(
    String path, {
    required String idToken,
    Map<String, String> fields = const {},
    required List<ApiMultipartFile> files,
  }) async {
    final uri = _buildUri(path);
    _log('postMultipartAuthorized uri=$uri fieldCount=${fields.length} fileCount=${files.length}');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(_authorizedHeaders(idToken, isJson: false))
      ..fields.addAll(fields);

    for (final file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          file.fieldName,
          file.bytes,
          filename: file.filename,
          contentType: file.contentType,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _decodeResponse(response);
  }

  String resolveUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalizedPath';
  }

  Future<Map<String, dynamic>> syncUser(
    String idToken, {
    String? phoneNumber,
  }) async {
    final uri = _buildUri('/auth/sync');
    final payload = <String, dynamic>{
      'phoneNumber': phoneNumber,
    };
    _log(
      'syncUser start uri=$uri tokenLength=${idToken.length} tokenPrefix=${idToken.substring(0, idToken.length < 12 ? idToken.length : 12)} phoneNumber=${phoneNumber ?? 'none'}',
    );

    final response = await _client.post(
      uri,
      headers: _authorizedHeaders(idToken),
      body: jsonEncode(payload),
    );

    final json = await _decodeResponse(response);

    _log('syncUser success keys=${json.keys.join(',')}');

    return json;
  }
}

class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.code,
    String? userMessage,
    this.requestId,
  }) : userMessage = userMessage ?? message;

  final String message;
  final int? statusCode;
  final String? code;
  final String userMessage;
  final String? requestId;

  @override
  String toString() => userMessage;
}