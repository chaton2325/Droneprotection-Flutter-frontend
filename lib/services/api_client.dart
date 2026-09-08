import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import '../config.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _client = http.Client();
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    return Uri.parse('${AppConfig.apiBaseUrl}$path').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, '$value')),
    );
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = (body is Map && body['error'] != null)
        ? body['error'] as String
        : 'Erreur reseau (${response.statusCode}).';
    throw ApiException(message, statusCode: response.statusCode);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final response = await _client.get(_uri(path, query), headers: _headers);
    return _decode(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _decode(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _client.delete(_uri(path), headers: _headers);
    return _decode(response);
  }

  Future<dynamic> postMultipart(
    String path, {
    required String fieldName,
    required List<int> fileBytes,
    required String filename,
    required String mimeType,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(
      http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: filename,
        // Sans ceci, le package http part sur application/octet-stream par
        // defaut : le backend rejette alors TOUJOURS l'upload comme "format
        // non supporte", quelle que soit l'image (galerie ou appareil photo).
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _decode(response);
  }
}
