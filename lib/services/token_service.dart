import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const String _tokenKey = 'career_focus_token';
  static const String _emailKey = 'career_focus_email';

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  static final TokenService _instance =
      TokenService._internal();

  factory TokenService() => _instance;

  TokenService._internal();

  Future<void> saveSession({
    required String token,
    required String email,
  }) async {
    await _storage.write(
      key: _tokenKey,
      value: token,
    );

    await _storage.write(
      key: _emailKey,
      value: email,
    );
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<String?> getEmail() async {
    return _storage.read(key: _emailKey);
  }

  Future<bool> hasSession() async {
    final token = await getToken();

    return token != null &&
        token.trim().isNotEmpty;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
  }

  // Compatibility helpers.
  Future<void> saveToken(String token) async {
    await _storage.write(
      key: _tokenKey,
      value: token,
    );
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();

    return token != null &&
        token.trim().isNotEmpty;
  }
}