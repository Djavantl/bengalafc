import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._privateConstructor();
  static final ApiClient instance = ApiClient._privateConstructor();

  String get baseUrl {
    final env = dotenv.env['APP_ENV']?.trim().toLowerCase() ?? 'production';
    if (env == 'local') {
      return dotenv.env['API_URL_LOCAL'] ?? 'http://localhost:8000';
    }
    return dotenv.env['API_URL_PRODUCTION'] ??
        'https://bengalafc-api-production.up.railway.app';
  }

  String? _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  bool get isAuthenticated => _token != null;

  String? get token => _token;

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Map<String, String> _headers(bool requireAuth) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (requireAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Future<http.Response> get(String path, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.get(url, headers: _headers(requireAuth));
    return _handleResponse(response, requireAuth: requireAuth);
  }

  Future<http.Response> post(
    String path,
    dynamic body, {
    bool requireAuth = true,
    bool isJson = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = _headers(requireAuth);
    Object? serializedBody = isJson ? jsonEncode(body) : body;
    if (!isJson) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
      if (body is Map) {
        serializedBody = body.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    }
    final response = await http.post(
      url,
      headers: headers,
      body: serializedBody,
    );
    return _handleResponse(response, requireAuth: requireAuth);
  }

  Future<http.Response> patch(
    String path,
    dynamic body, {
    bool requireAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.patch(
      url,
      headers: _headers(requireAuth),
      body: jsonEncode(body),
    );
    return _handleResponse(response, requireAuth: requireAuth);
  }

  Future<http.Response> patchMultipart(
    String path, {
    Map<String, String> fields = const {},
    List<int>? fileBytes,
    String? fileField,
    String? filename,
    bool requireAuth = true,
  }) async {
    final url = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('PATCH', url);
    request.headers.addAll({
      'Accept': 'application/json',
      if (requireAuth && _token != null) 'Authorization': 'Bearer $_token',
    });
    request.fields.addAll(fields);

    if (fileBytes != null && fileField != null && filename != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: filename,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response, requireAuth: requireAuth);
  }

  Future<http.Response> delete(String path, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.delete(url, headers: _headers(requireAuth));
    return _handleResponse(response, requireAuth: requireAuth);
  }

  http.Response _handleResponse(
    http.Response response, {
    required bool requireAuth,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    final errorMessage = _extractErrorMessage(response);

    if (response.statusCode == 401 && requireAuth) {
      clearToken();
      throw ApiException(
        errorMessage == 'Erro na comunicação com o servidor.'
            ? 'Sessão expirada. Faça login novamente.'
            : errorMessage,
        response.statusCode,
      );
    }

    throw ApiException(errorMessage, response.statusCode);
  }

  String _extractErrorMessage(http.Response response) {
    var errorMessage = 'Erro na comunicação com o servidor.';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        if (decoded.containsKey('detail')) {
          errorMessage = decoded['detail'].toString();
        } else if (decoded.containsKey('error_description')) {
          errorMessage = decoded['error_description'].toString();
        } else if (decoded.containsKey('error')) {
          errorMessage = decoded['error'].toString();
        } else {
          final buffer = StringBuffer();
          decoded.forEach((key, value) {
            buffer.write('$key: $value\n');
          });
          errorMessage = buffer.toString().trim();
        }
      }
    } catch (_) {}
    return errorMessage;
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
