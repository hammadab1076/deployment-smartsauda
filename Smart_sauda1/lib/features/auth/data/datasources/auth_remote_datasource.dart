import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_sauda1/core/api_config.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  static const _tokenKey = 'auth_token';
  static const _base = ApiConfig.baseUrl;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  Future<UserModel> login(String email, String password,
      {String selectedRole = 'customer'}) async {
    final res = await http.post(
      Uri.parse('$_base/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password, 'role': selectedRole}),
    );
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) {
      throw Exception(body['error'] ?? 'Login failed');
    }
    await _saveToken(body['token'] as String);
    debugPrint('[AuthDataSource] Login OK, token saved');
    return UserModel.fromApiMap(body['user'] as Map<String, dynamic>);
  }

  Future<UserModel> signup(String name, String email, String password,
      String role) async {
    final res = await http.post(
      Uri.parse('$_base/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'email': email, 'password': password, 'role': role}),
    );
    final body = json.decode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 201) {
      throw Exception(body['error'] ?? 'Registration failed');
    }
    await _saveToken(body['token'] as String);
    debugPrint('[AuthDataSource] Signup OK, token saved');
    return UserModel.fromApiMap(body['user'] as Map<String, dynamic>);
  }

  Future<UserModel?> getCurrentUser() async {
    final token = await _loadToken();
    if (token == null) return null;

    final userId = _decodeUserIdFromJwt(token);
    if (userId == null) return null;

    final res = await http.get(
      Uri.parse('$_base/users/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 404) return null;
    return UserModel.fromApiMap(json.decode(res.body) as Map<String, dynamic>);
  }

  Future<void> updateProfile(String name, String phone) async {
    final token = await _loadToken();
    if (token == null) throw Exception('Not authenticated');
    final userId = _decodeUserIdFromJwt(token);
    if (userId == null) throw Exception('Invalid token');

    final res = await http.put(
      Uri.parse('$_base/users/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'name': name, 'phone': phone}),
    );
    if (res.statusCode != 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Update failed');
    }
  }

  Future<void> resetPassword(String email, String newPassword) async {
    final res = await http.post(
      Uri.parse('$_base/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'newPassword': newPassword}),
    );
    if (res.statusCode != 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Password reset failed');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final token = await _loadToken();
    if (token == null) throw Exception('Not authenticated');
    final userId = _decodeUserIdFromJwt(token);
    if (userId == null) throw Exception('Invalid token');

    // Get email from stored profile to pass to change-password endpoint
    final userRes = await http.get(Uri.parse('$_base/users/$userId'));
    if (userRes.statusCode != 200) throw Exception('User not found');
    final email = (json.decode(userRes.body) as Map<String, dynamic>)['email'] as String;

    final res = await http.post(
      Uri.parse('$_base/auth/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );
    if (res.statusCode != 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      throw Exception(body['error'] ?? 'Password change failed');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    debugPrint('[AuthDataSource] Token removed, logged out');
  }

  // -------------------------------------------------------------------------
  // Token helpers
  // -------------------------------------------------------------------------

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Decodes the JWT payload (base64url) without verifying signature.
  /// Only used client-side to extract `id` for fetching the user profile.
  String? _decodeUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      // base64url → base64 padding
      String payload = parts[1];
      payload += '=' * ((4 - payload.length % 4) % 4);
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = json.decode(decoded) as Map<String, dynamic>;
      return map['id'] as String?;
    } catch (e) {
      debugPrint('[AuthDataSource] JWT decode error: $e');
      return null;
    }
  }
}
