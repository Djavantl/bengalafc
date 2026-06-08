import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  ApiClient._privateConstructor();
  static final ApiClient instance = ApiClient._privateConstructor();

  static const bool useProduction = false; // Mude para false para testar localmente

  String get baseUrl {
    if (useProduction) {
      return 'https://bengalafc-api-production.up.railway.app';
    }
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://127.0.0.1:8000';
    }
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
    return _handleResponse(response);
  }

  Future<http.Response> post(String path, dynamic body, {bool requireAuth = true, bool isJson = true}) async {
    final url = Uri.parse('$baseUrl$path');
    final headers = _headers(requireAuth);
    final serializedBody = isJson ? jsonEncode(body) : body;
    if (!isJson) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }
    final response = await http.post(url, headers: headers, body: serializedBody);
    return _handleResponse(response);
  }

  Future<http.Response> patch(String path, dynamic body, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.patch(url, headers: _headers(requireAuth), body: jsonEncode(body));
    return _handleResponse(response);
  }

  Future<http.Response> delete(String path, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.delete(url, headers: _headers(requireAuth));
    return _handleResponse(response);
  }

  http.Response _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    } else if (response.statusCode == 401) {
      clearToken();
      throw ApiException('Sessão expirada. Faça login novamente.', response.statusCode);
    } else {
      String errorMessage = 'Erro na comunicação com o servidor.';
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
      throw ApiException(errorMessage, response.statusCode);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
