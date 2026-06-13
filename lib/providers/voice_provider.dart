import 'package:flutter/foundation.dart';
import '../services/voice_service.dart';
import '../services/chat_api_service.dart';
import '../config/app_config.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceProvider extends ChangeNotifier {
  final VoiceService _voiceService;
  ChatApiService _apiService;

  VoiceProvider(this._voiceService, this._apiService) {
    _voiceService.addListener(_onServiceUpdate);
  }

  void updateApiService(ChatApiService newService) {
    _apiService = newService;
  }

  bool _isLoading = false;
  String? _error;

  // Getter'lar
  bool get isLoading => _isLoading;
  bool get isConnected => _voiceService.isConnected;
  bool get isMicEnabled => _voiceService.isMicEnabled;
  String? get error => _error;
  List<dynamic> get participants => _voiceService.participants;
  List<dynamic> get activeSpeakers => _voiceService.activeSpeakers;
  // LiveKit'in kendi Room sınıfı veya benzeri bir yapı
  dynamic get room => _voiceService.room;

  @override
  void dispose() {
    _voiceService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    notifyListeners();
  }



  /// Odaya katıl
  Future<void> joinRoom(String roomId) async {
    if (_voiceService.isConnected) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 0. İzinleri kontrol et
      var status = await Permission.microphone.status;
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
           _error = 'Mikrofon izni gerekli';
           _isLoading = false;
           notifyListeners();
           return;
        }
      }

      // 1. Backend'den token al
      final token = await _apiService.joinRoom(roomId);
      
      if (token == null) {
        _error = 'Odaya giriş izni alınamadı (Token yok)';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 2. LiveKit'e bağlan
      await _voiceService.connect(AppConfig.livekitUrl, token);
      
    } catch (e) {
      _error = 'Bağlantı hatası: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Odadan ayrıl
  Future<void> leaveRoom() async {
    await _voiceService.disconnect();
  }

  /// Mikrofonu aç/kapat
  Future<void> toggleMic() async {
    await _voiceService.toggleMic();
  }
}
