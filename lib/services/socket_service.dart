import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';

/// Socket.IO bağlantısını ve eventlerini yöneten servis
class SocketService {
  io.Socket? _socket;

  io.Socket? get socket => _socket;
  bool get isConnected => _socket?.connected ?? false;

  /// Socket bağlantısını kur
  void connect(String token) {
    if (_socket != null) {
      if (_socket!.connected) return;
      _socket!.connect();
      return;
    }

    debugPrint('Socket başlatılıyor: token=${token.substring(0, 5)}...');
    _socket = io.io(AppConfig.socketUrl, {
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {'token': token},
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
    });

    _socket!.connect();

    _socket!.on('connect', (_) {
      debugPrint('Socket BAĞLANDI ✔');
    });
    
    _socket!.on('disconnect', (_) => debugPrint('Socket BAĞLANTI KESİLDİ ❌'));
    _socket!.on('connect_error', (data) => debugPrint('Socket bağlantı hatası: $data'));
    _socket!.on('error', (data) => debugPrint('Socket hatası: $data'));
    
    _socket!.onAny((event, data) {
      debugPrint('SOCKET EVENT ALINDI: $event -> $data');
    });
  }

  /// Odaya katıl
  void joinRoom(String roomId) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('Socket bağlı değil, odaya katılamıyor: $roomId');
      return;
    }
    debugPrint('Socket: joining room -> $roomId');
    // Backend farklı event adları bekliyor olabilir, hepsini deneyelim
    _socket?.emit('join_room', {'roomId': roomId});
    // Alternatif: direkt roomId string olarak
    // _socket?.emit('joinRoom', roomId);
  }

  /// Odadan ayrıl
  void leaveRoom(String roomId) {
    debugPrint('Socket: leaving room -> $roomId');
    _socket?.emit('leave_room', {'roomId': roomId});
  }

  /// Mesaj gönder
  void sendMessage(Map<String, dynamic> messageData) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('Socket bağlı değil, mesaj gönderilemiyor');
      return;
    }
    debugPrint('Socket: sending message -> $messageData');
    
    // Backend'in beklediği event adını bul
    // Önce send_message deneyelim (en yaygın)
    _socket?.emit('send_message', messageData);
    
    // Eğer çalışmazsa, diğer olası event adlarını da ekleyebiliriz:
    // _socket?.emit('message', messageData);
    // _socket?.emit('sendMessage', messageData);
    // _socket?.emit('new_message', messageData);
  }

  /// Yazıyor bilgisini gönder
  void sendTyping(String roomId, bool isTyping) {
    if (isTyping) {
      _socket?.emit('typing_start', roomId);
    } else {
      _socket?.emit('typing_stop', roomId);
    }
  }

  /// Socket bağlantısını kapat
  void disconnect() {
    debugPrint('Socket kapatılıyor...');
    _socket?.disconnect();
    _socket = null;
  }
}
