import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/room.dart';
import '../models/message.dart';

/// Chat ile ilgili API işlemlerini yöneten servis
class ChatApiService {
  final String? token;

  ChatApiService({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  /// Tüm odaları getir
  Future<List<Room>> getRooms() async {
    try {
      debugPrint('Fetching rooms from primary: ${AppConfig.baseUrl}/room');
      
      var response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/room'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      debugPrint('GetRooms (/room) Status: ${response.statusCode}');
      
      // Eğer /room 404 dönerse veya boş dönerse /rooms dene (fallback)
      if (response.statusCode == 404 || (response.statusCode == 200 && response.body == '[]')) {
        debugPrint('Trying fallback endpoint: ${AppConfig.baseUrl}/rooms');
        response = await http.get(
          Uri.parse('${AppConfig.baseUrl}/rooms'),
          headers: _headers,
        ).timeout(const Duration(seconds: 10));
        debugPrint('GetRooms (/rooms) Status: ${response.statusCode}');
      }

      debugPrint('Final GetRooms Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is Map ? (decoded['rooms'] ?? []) : decoded;
        return data.map((json) => Room.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('GetRooms hatası: $e');
      return [];
    }
  }

  /// Bir odanın mesajlarını getir
  Future<List<Message>> getMessages(String roomId) async {
    try {
      debugPrint('Fetching messages for room: $roomId');
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/message/room/$roomId'),
        headers: _headers,
      );

      debugPrint('GetMessages Status: ${response.statusCode}');
      debugPrint('GetMessages Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        // Backend bazen direkt liste bazen {messages: [...]} dönebilir
        final List<dynamic> data = decoded is Map 
            ? (decoded['messages'] ?? decoded['data'] ?? []) 
            : decoded;
        return data.map((json) => Message.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('GetMessages hatası: $e');
      return [];
    }
  }

  /// Bir odaya katıl ve LiveKit token'ı al (sesli odalar için)
  Future<String?> joinRoom(String roomId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/room/$roomId/join'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['token']; // LiveKit token
      }
      return null;
    } catch (e) {
      debugPrint('JoinRoom hatası: $e');
      return null;
    }
  }

  /// Mesaj sil
  Future<bool> deleteMessage(String messageId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/message/$messageId'),
        headers: _headers,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('DeleteMessage hatası: $e');
      return false;
    }
  }
}
