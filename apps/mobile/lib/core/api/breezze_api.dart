import 'dart:convert';

import 'package:http/http.dart' as http;

/// Breezze backend API client — thin transport for /api/v1.
///
/// No secrets: the backend is Breezze's own; JWT access + refresh tokens
/// are stored by the session controller, never hardcoded.
class BreezzeApi {
  BreezzeApi({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  String? accessToken;

  Uri _uri(String path) => Uri.parse('$baseUrl/api/v1$path');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await _client.get(_uri(path), headers: _headers);
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final error = body['error'];
      throw BreezzeApiException(
        code: error is Map && error['code'] is String
            ? error['code'] as String
            : 'HTTP_${response.statusCode}',
        message: error is Map && error['message'] is String
            ? error['message'] as String
            : 'Request failed',
      );
    }
    final data = body['data'];
    return data is Map<String, dynamic> ? data : body;
  }

  // ---- auth ----

  Future<AuthResponse> register(
    String email,
    String password, {
    String? displayName,
  }) async {
    final data = await _post('/auth/register', {
      'email': email,
      'password': password,
      if (displayName != null) 'displayName': displayName,
    });
    return AuthResponse.fromJson(data);
  }

  Future<AuthResponse> login(String email, String password) async {
    final data = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    return AuthResponse.fromJson(data);
  }

  Future<AuthResponse> refresh(String refreshToken) async {
    final data = await _post('/auth/refresh', {
      'refreshToken': refreshToken,
    });
    return AuthResponse.fromJson(data);
  }

  Future<void> logout(String refreshToken) async {
    await _post('/auth/logout', {'refreshToken': refreshToken});
  }

  Future<Map<String, dynamic>> me() async => _get('/auth/me');
}

class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String email;

  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return AuthResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      userId: user is Map ? (user['id'] as String? ?? '') : '',
      email: user is Map ? (user['email'] as String? ?? '') : '',
    );
  }
}

class BreezzeApiException implements Exception {
  final String code;
  final String message;
  const BreezzeApiException({required this.code, required this.message});

  @override
  String toString() => '$code: $message';
}
