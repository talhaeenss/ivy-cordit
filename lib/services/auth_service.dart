import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/user.dart';

/// Kimlik doğrulama servisi
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Kayıtlı token'ı yükle
  Future<User?> loadStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      final userData = prefs.getString(_userKey);

      if (token != null && userData != null) {
        final userJson = jsonDecode(userData);
        _currentUser = User.fromJson(userJson, token: token);
        return _currentUser;
      }
    } catch (e) {
      // Token geçersiz, temizle
      await clearStoredUser();
    }
    return null;
  }

  /// Token'ı kaydet
  Future<void> _storeUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _currentUser = user;
  }

  /// Kayıtlı kullanıcıyı temizle
  Future<void> clearStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _currentUser = null;
  }

  /// Giriş yap
  Future<({bool success, String? error, User? user})> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final dynamic data = jsonDecode(response.body);
      
      debugPrint('Login Response Status: ${response.statusCode}');
      debugPrint('Login Response Body: ${response.body}');

      if (response.statusCode == 200) {
        if (data is Map<String, dynamic>) {
          // Hem iç içe (user: {}) hem de düz yapıyı destekle
          final Map<String, dynamic> userData = data['user'] is Map<String, dynamic> 
              ? data['user'] as Map<String, dynamic> 
              : data;
          
          final token = data['token']?.toString() ?? userData['token']?.toString();
          
          // ID eksikse username'i ID olarak kullan
          if (userData['id'] == null && userData['username'] != null) {
            userData['id'] = userData['username'];
          }

          if (userData['username'] != null) {
            final user = User.fromJson(userData, token: token);
            await _storeUser(user);
            return (success: true, error: null, user: user);
          }
        }
        return (success: false, error: 'Sunucudan geçersiz veri yapısı döndü.', user: null);
      } else {
        String errorMessage = 'Giriş başarısız';
        if (data is Map<String, dynamic>) {
          errorMessage = data['message']?.toString() ?? data['error']?.toString() ?? errorMessage;
        } else if (data is List && data.isNotEmpty) {
          // Doğrulama hataları dizisi
          final firstError = data.first;
          if (firstError is Map && firstError['message'] != null) {
            errorMessage = firstError['message'].toString();
          }
        }
        return (success: false, error: errorMessage, user: null);
      }
    } catch (e) {
      debugPrint('Login Hatası: $e');
      return (success: false, error: 'Bağlantı hatası: $e', user: null);
    }
  }

  /// Kayıt ol
  Future<({bool success, String? error, User? user})> register({
    required String inviteCode,
    required String username,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'inviteCode': inviteCode,
          'username': username,
          'password': password,
        }),
      );

      final dynamic data = jsonDecode(response.body);
      
      debugPrint('Register Response Status: ${response.statusCode}');
      debugPrint('Register Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (data is Map<String, dynamic>) {
          // Hem iç içe (user: {}) hem de düz yapıyı destekle
          final Map<String, dynamic> userData = data['user'] is Map<String, dynamic> 
              ? data['user'] as Map<String, dynamic> 
              : data;
          
          final token = data['token']?.toString() ?? userData['token']?.toString();
          
          // ID eksikse username'i ID olarak kullan
          if (userData['id'] == null && userData['username'] != null) {
            userData['id'] = userData['username'];
          }

          if (userData['username'] != null) {
            final user = User.fromJson(userData, token: token);
            await _storeUser(user);
            return (success: true, error: null, user: user);
          }
        }
        return (success: false, error: 'Sunucudan geçersiz veri yapısı döndü.', user: null);
      } else {
        String errorMessage = 'Kayıt başarısız';
        if (data is Map<String, dynamic>) {
          errorMessage = data['message']?.toString() ?? data['error']?.toString() ?? errorMessage;
        } else if (data is List && data.isNotEmpty) {
          // Doğrulama hataları dizisi
          final firstError = data.first;
          if (firstError is Map && firstError['message'] != null) {
            errorMessage = firstError['message'].toString();
          }
        }
        return (success: false, error: errorMessage, user: null);
      }
    } catch (e) {
      debugPrint('Register Hatası: $e');
      return (success: false, error: 'Bağlantı hatası: $e', user: null);
    }
  }

  /// Davet kodunu doğrula
  Future<({bool valid, String? error})> validateInviteCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/invite/validate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return (valid: data['valid'] == true, error: null);
      } else {
        return (valid: false, error: (data['error'] ?? 'Kod geçersiz') as String?);
      }
    } catch (e) {
      return (valid: false, error: 'Bağlantı hatası');
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    await clearStoredUser();
  }
}
