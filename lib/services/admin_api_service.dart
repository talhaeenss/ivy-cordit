import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/invite.dart';
import '../models/user.dart';

/// Admin yetkisi gerektiren API işlemlerini yöneten servis
class AdminApiService {
  final String? token;

  AdminApiService({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  /// Tüm davet kodlarını getir
  Future<List<Invite>> getInviteCodes() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/invite'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is Map ? (decoded['invites'] ?? []) : decoded;
        return data.map((json) => Invite.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('GetInviteCodes hatası: $e');
      return [];
    }
  }

  /// Yeni davet kodu oluştur
  Future<Invite?> createInviteCode({
    required int maxUses,
    DateTime? expiresAt,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/invite'),
        headers: _headers,
        body: jsonEncode({
          'maxUses': maxUses,
          'expiresAt': expiresAt?.toIso8601String(),
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Invite.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('CreateInviteCode hatası: $e');
      return null;
    }
  }

  /// Davet kodunu sil
  Future<bool> deleteInviteCode(String code) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/invite/$code'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('DeleteInviteCode hatası: $e');
      return false;
    }
  }

  /// Tüm kullanıcıları getir
  Future<List<User>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/user'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is Map ? (decoded['users'] ?? []) : decoded;
        return data.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('GetUsers hatası: $e');
      return [];
    }
  }

  /// Kullanıcıyı sil
  Future<bool> deleteUser(String username) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/user/username/$username'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('DeleteUser hatası: $e');
      return false;
    }
  }
}
