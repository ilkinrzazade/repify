import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'workout_store.dart';

/// Error with a message that can be shown to the user.
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

/// Talks to the Django REST backend.
/// Keeps the server address and the login token on the phone.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// 10.0.2.2 is how the Android emulator reaches the laptop it runs on.
  static const String defaultBaseUrl = 'http://10.0.2.2:8000';
  static const Duration _timeout = Duration(seconds: 8);

  static const String _urlKey = 'server_url';
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'auth_email';

  String baseUrl = defaultBaseUrl;
  String? token;
  String? email;

  bool get isLoggedIn => token != null;

  Future<void> loadSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      baseUrl = prefs.getString(_urlKey) ?? defaultBaseUrl;
      token = prefs.getString(_tokenKey);
      email = prefs.getString(_emailKey);
    } catch (_) {
      // Keep the defaults if local storage is not available.
    }
  }

  Future<void> setBaseUrl(String url) async {
    var cleaned = url.trim();
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    if (!cleaned.startsWith('http://') && !cleaned.startsWith('https://')) {
      cleaned = 'http://$cleaned';
    }
    baseUrl = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_urlKey, cleaned);
  }

  // ---------- Auth ----------

  Future<void> login(String email, String password) async {
    final data = await _send('POST', '/api/auth/login/', body: {
      'email': email,
      'password': password,
    });
    await _saveSession(data);
  }

  Future<void> register(String email, String password) async {
    final data = await _send('POST', '/api/auth/register/', body: {
      'email': email,
      'password': password,
    });
    await _saveSession(data);
  }

  Future<void> logout() async {
    try {
      await _send('POST', '/api/auth/logout/');
    } catch (_) {
      // Even if the server is offline, the user is logged out on the phone.
    }
    token = null;
    email = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
  }

  Future<void> _saveSession(dynamic data) async {
    if (data is! Map || data['token'] == null) {
      throw ApiException('Unexpected answer from the server.');
    }
    token = '${data['token']}';
    email = '${data['email'] ?? ''}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token!);
    await prefs.setString(_emailKey, email!);
  }

  // ---------- Workouts ----------

  Future<List<Workout>> fetchWorkouts() async {
    final data = await _send('GET', '/api/workouts/');
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((w) => Workout.fromJson(Map<String, dynamic>.from(w)))
        .toList();
  }

  Future<Workout> createWorkout(Workout workout) async {
    final data = await _send('POST', '/api/workouts/', body: workout.toJson());
    if (data is! Map) throw ApiException('Unexpected answer from the server.');
    return Workout.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> deleteWorkout(String id) async {
    await _send('DELETE', '/api/workouts/$id/');
  }

  /// True when the server answers.
  Future<bool> ping() async {
    try {
      await _send('GET', '/api/health/');
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------- HTTP ----------

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      };

  Future<dynamic> _send(String method, String path, {Object? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final encoded = body == null ? null : jsonEncode(body);
    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: _headers).timeout(_timeout);
        case 'POST':
          response = await http
              .post(uri, headers: _headers, body: encoded)
              .timeout(_timeout);
        case 'DELETE':
          response = await http.delete(uri, headers: _headers).timeout(_timeout);
        default:
          throw ApiException('Unsupported method $method');
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Cannot reach the server at $baseUrl');
    }

    if (response.statusCode == 401) {
      throw ApiException('Session expired. Please log in again.');
    }
    if (response.statusCode >= 400) {
      throw ApiException(_errorMessage(response));
    }
    if (response.body.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  /// Turns a Django REST error like {"email": ["Enter a valid email."]}
  /// into a readable sentence.
  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map) {
        if (data['detail'] != null) return '${data['detail']}';
        for (final value in data.values) {
          if (value is List && value.isNotEmpty) return '${value.first}';
          if (value is String) return value;
        }
      }
    } catch (_) {
      // Not JSON: fall through to the generic message.
    }
    return 'Server error (${response.statusCode})';
  }
}
