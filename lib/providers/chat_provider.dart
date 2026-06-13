import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/room.dart';
import '../models/message.dart';
import '../services/chat_api_service.dart';
import '../services/socket_service.dart';

/// Chat durumunu yöneten provider
class ChatProvider with ChangeNotifier {
  ChatApiService _apiService;
  final SocketService _socketService;

  List<Room> _rooms = [];
  List<Message> _messages = [];
  Room? _currentRoom;
  bool _isLoadingRooms = false;
  bool _isLoadingMessages = false;
  String? _typingUser;
  String? _error;

  ChatProvider(this._apiService, this._socketService) {
    _setupSocketListeners();
  }

  void updateApiService(ChatApiService newService) {
    final bool tokenChanged = _apiService.token != newService.token;
    _apiService = newService;
    
    // Eğer token değiştiyse veya yeni token geldiyse işlemleri yap
    if (newService.token != null && newService.token!.isNotEmpty) {
      _socketService.connect(newService.token!);
      _setupSocketListeners(); // Dinleyicileri her güncellemede tazele (veya ilk kez kur)
      if (tokenChanged) {
        fetchRooms();
      }
    } else {
      _socketService.disconnect();
    }
  }

  // Getters
  List<Room> get rooms => _rooms;
  List<Message> get messages => _messages;
  Room? get currentRoom => _currentRoom;
  bool get isLoadingRooms => _isLoadingRooms;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get typingUser => _typingUser;
  String? get error => _error;

  /// Socket dinleyicilerini kur
  void _setupSocketListeners() {
    final socket = _socketService.socket;
    if (socket == null) return;

    // Önceki dinleyicileri temizle (mükerrerliği önlemek için)
    socket.off('connect');
    socket.off('joined_room');
    socket.off('room_joined');
    socket.off('joined');
    // Tüm olası mesaj eventlerini temizle
    socket.off('new_message');
    socket.off('message');
    socket.off('sendMessage');
    socket.off('receive_message');
    socket.off('message_deleted');
    socket.off('user_typing');

    socket.on('connect', (_) {
      debugPrint('ChatProvider: Socket (re)connected! Syncing room state...');
      if (_currentRoom != null) {
        _socketService.joinRoom(_currentRoom!.id);
      }
    });

    // Odaya başarıyla katıldığında (backend 'joined_room' gönderiyor)
    socket.on('joined_room', (data) {
      debugPrint('ChatProvider: Successfully joined room: $data');
    });
    
    socket.on('room_joined', (data) {
      debugPrint('ChatProvider: Successfully joined room (alt event): $data');
    });
    
    socket.on('joined', (data) {
      debugPrint('ChatProvider: Successfully joined room (alt event 2): $data');
    });

    // Mesaj alma eventlerini çeşitlendir
    final messageEvents = ['new_message', 'message', 'sendMessage', 'receive_message'];
    for (var event in messageEvents) {
      _socketService.socket?.on(event, (data) {
        try {
          debugPrint('ChatProvider: New message received (Event: $event): $data');
          final newMessage = Message.fromJson(data);
          debugPrint('ChatProvider: Parsed message - id: ${newMessage.id}, roomId: ${newMessage.roomId}, currentRoomId: ${_currentRoom?.id}');
          
          // Mesajın şu anki odaya ait olup olmadığını kontrol et
          if (newMessage.roomId == _currentRoom?.id) {
            // Mükerrer eklemeyi önle
            if (!_messages.any((m) => m.id == newMessage.id)) {
              _messages.add(newMessage);
              debugPrint('ChatProvider: Message added to list, total messages: ${_messages.length}');
              notifyListeners();
            } else {
              debugPrint('ChatProvider: Message already exists in list');
            }
          } else {
            debugPrint('ChatProvider: Message roomId mismatch - message: ${newMessage.roomId}, current: ${_currentRoom?.id}');
          }
        } catch (e) {
          debugPrint('ChatProvider: Error parsing message: $e');
        }
      });
    }

    socket.on('user_typing', (data) {
      if (data['roomId'] == _currentRoom?.id) {
        _typingUser = data['username'];
        notifyListeners();
        
        // 3 saniye sonra typing indicator'ı kaldır
        Future.delayed(const Duration(seconds: 3), () {
          if (_typingUser == data['username']) {
            _typingUser = null;
            notifyListeners();
          }
        });
      }
    });

    // Mesaj silme eventini dinle
    socket.on('message_deleted', (data) {
      debugPrint('ChatProvider: Message deleted: $data');
      final messageId = data['messageId'];
      if (messageId != null) {
        _messages.removeWhere((m) => m.id == messageId);
        notifyListeners();
      }
    });
  }

  /// Odaları getir
  Future<void> fetchRooms() async {
    debugPrint('ChatProvider: fetchRooms() called');
    _isLoadingRooms = true;
    _error = null;
    notifyListeners();

    try {
      _rooms = await _apiService.getRooms();
      debugPrint('ChatProvider: Fetched ${_rooms.length} rooms');
      
      // Son seçilen odayı yükle
      final lastRoomId = await _getLastSelectedRoom();
      
      if (_currentRoom == null && _rooms.isNotEmpty) {
        Room? roomToSelect;
        
        // Önce son seçilen odayı bul
        if (lastRoomId != null) {
          roomToSelect = _rooms.firstWhere(
            (r) => r.id == lastRoomId,
            orElse: () => _rooms.first,
          );
          debugPrint('ChatProvider: Restoring last selected room: ${roomToSelect.name}');
        } else {
          // Son seçilen oda yoksa default odayı seç
          roomToSelect = _rooms.firstWhere(
            (r) => r.name.toLowerCase() == 'default', 
            orElse: () => _rooms.first
          );
          debugPrint('ChatProvider: Selecting default room: ${roomToSelect.name}');
        }
        
        selectRoom(roomToSelect);
      }
    } catch (e) {
      _error = 'Odalar yüklenirken hata oluştu: $e';
    } finally {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  /// Bir odayı seç ve mesajlarını yükle
  Future<void> selectRoom(Room room) async {
    if (_currentRoom?.id == room.id) return;

    // Önceki odadan ayrıl
    if (_currentRoom != null) {
      _socketService.leaveRoom(_currentRoom!.id);
    }

    _currentRoom = room;
    _messages = [];
    _isLoadingMessages = true;
    _error = null;
    notifyListeners();

    // Son seçilen odayı kaydet
    await _saveLastSelectedRoom(room.id);

    // Socket bağlıysa hemen odaya katıl
    if (_socketService.isConnected) {
      _socketService.joinRoom(room.id);
    } else {
      debugPrint('Socket henüz bağlı değil, bağlandığında odaya katılacak');
    }
    
    // Mesaj geçmişini çek
    try {
      _messages = await _apiService.getMessages(room.id);
    } catch (e) {
      _error = 'Mesajlar yüklenirken bir hata oluştu.';
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Son seçilen odayı kaydet
  Future<void> _saveLastSelectedRoom(String roomId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_room_id', roomId);
      debugPrint('Last selected room saved: $roomId');
    } catch (e) {
      debugPrint('Error saving last selected room: $e');
    }
  }

  /// Son seçilen odayı yükle
  Future<String?> _getLastSelectedRoom() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('last_selected_room_id');
    } catch (e) {
      debugPrint('Error getting last selected room: $e');
      return null;
    }
  }

  /// Mevcut odanın mesajlarını yeniden yükle (Pull to refresh için)
  Future<void> refreshMessages() async {
    if (_currentRoom == null) return;
    
    _isLoadingMessages = true;
    _error = null;
    notifyListeners();
    
    try {
      _messages = await _apiService.getMessages(_currentRoom!.id);
    } catch (e) {
      _error = 'Yenilenirken hata oluştu.';
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  /// Mesaj gönder
  void sendMessage(String content, String username) {
    if (_currentRoom == null || content.trim().isEmpty) return;

    // Socket bağlı değilse uyar
    if (!_socketService.isConnected) {
      debugPrint('UYARI: Socket bağlı değil, mesaj gönderilemedi!');
      _error = 'Bağlantı kurulamadı, lütfen tekrar deneyin.';
      notifyListeners();
      return;
    }

    // Backend sadece text ve roomId bekliyor
    final messageData = {
      'text': content,
      'roomId': _currentRoom!.id,
    };

    debugPrint('Sending message with data: $messageData');
    _socketService.sendMessage(messageData);
  }

  /// Yazıyor bilgisini gönder
  void setTyping(bool isTyping) {
    if (_currentRoom == null) return;
    _socketService.sendTyping(_currentRoom!.id, isTyping);
  }

  /// Mesaj sil
  Future<bool> deleteMessage(String messageId) async {
    final success = await _apiService.deleteMessage(messageId);
    if (success) {
      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
    }
    return success;
  }

  @override
  void dispose() {
    _socketService.disconnect();
    super.dispose();
  }
}
