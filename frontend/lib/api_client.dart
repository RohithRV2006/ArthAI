import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // ── Single source of truth for base URL ──────────────────────────────────
  static const String _baseUrl = 'http://10.132.185.222:8000';

  final http.Client _client = http.Client();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<dynamic> get(String endpoint) async {
    try {
      final response = await _client
          .get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 60));
      return _handleResponse(response);
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> post(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    try {
      final response = await _client
          .post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 60));
      return _handleResponse(response);
    } on TimeoutException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    String errorMsg = 'Something went wrong';
    if (decoded is Map) {
      errorMsg = decoded['message'] ?? decoded['detail'] ?? errorMsg;
    }
    throw ApiException(errorMsg, statusCode: response.statusCode);
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}