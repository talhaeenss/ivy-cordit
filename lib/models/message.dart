import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Mesaj modeli
class Message {
  final String id;
  final String content;
  final String username;
  final String roomId;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.content,
    required this.username,
    required this.roomId,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      content: json['content'] ?? json['text'] ?? json['message'] ?? json['msg'] ?? '',
      username: json['username'] ?? (json['user'] is Map ? json['user']['username'] : 'Bilinmeyen'),
      roomId: json['roomId'] ?? json['room'] ?? json['room_id'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']).toLocal() 
          : DateTime.now(),
    );
  }

  /// Neobrutalizm tasarımı için her kullanıcıya farklı bir mesaj rengi döner
  Color get bubbleColor {
    final int hash = username.hashCode.abs();
    return AppColors.messageColors[hash % AppColors.messageColors.length];
  }

  bool isOwner(String currentUsername) => username == currentUsername;
}
