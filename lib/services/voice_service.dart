import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

class VoiceService extends ChangeNotifier {
  Room? _room;
  EventsListener<RoomEvent>? _listener;
  
  // Durum değişkenleri
  bool _isConnected = false;
  bool _isMicEnabled = false;
  List<Participant> _participants = [];
  List<Participant> _activeSpeakers = [];

  // Getter'lar
  bool get isConnected => _isConnected;
  bool get isMicEnabled => _isMicEnabled;
  List<Participant> get participants => _participants;
  List<Participant> get activeSpeakers => _activeSpeakers;
  Room? get room => _room;

  /// Odaya bağlan
  Future<void> connect(String url, String token) async {
    try {
      // LiveKit bağlantı seçenekleri
      final roomOptions = RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioPublishOptions: const AudioPublishOptions(
          name: 'audio_track',
        ),
      );

      _room = Room(roomOptions: roomOptions);
      _listener = _room!.createListener();

      // Olayları dinle
      _setUpListeners();

      await _room!.connect(url, token);
      _isConnected = true;
      _updateParticipants();
      notifyListeners();
      
      // Başlangıçta mikrofon kapalı olsun, kullanıcı isterse açsın
      // Veya otomatik açılmasını istiyorsak: await toggleMic(true);
      
      debugPrint('LiveKit odasına bağlanıldı');
    } catch (e) {
      debugPrint('LiveKit bağlantı hatası: $e');
      _isConnected = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Odadan ayrıl
  Future<void> disconnect() async {
    if (_room != null) {
      await _room!.disconnect();
      _room = null;
    }
    _listener?.dispose();
    _listener = null;
    _isConnected = false;
    _participants = [];
    _isMicEnabled = false;
    notifyListeners();
  }

  /// Mikrofonu aç/kapat
  Future<void> toggleMic() async {
    if (_room == null || _room!.localParticipant == null) return;

    try {
      final localParticipant = _room!.localParticipant!;
      
      // Mikrofon durumunu değiştir
      final newState = !localParticipant.isMicrophoneEnabled();
      await localParticipant.setMicrophoneEnabled(newState);
      
      _isMicEnabled = newState;
      notifyListeners();
    } catch (e) {
      debugPrint('Mikrofon değiştirme hatası: $e');
    }
  }

  /// Olay dinleyicileri
  void _setUpListeners() {
    if (_listener == null) return;

    _listener!
      ..on<ParticipantConnectedEvent>((event) {
        debugPrint('Katılımcı bağlandı: ${event.participant.identity}');
        _updateParticipants();
        notifyListeners();
      })
      ..on<ParticipantDisconnectedEvent>((event) {
        debugPrint('Katılımcı ayrıldı: ${event.participant.identity}');
        _updateParticipants();
        notifyListeners();
      })
      ..on<TrackSubscribedEvent>((event) {
        // Ses akışı alındı
        notifyListeners();
      })
      ..on<TrackUnsubscribedEvent>((event) {
        // Ses akışı kesildi
        notifyListeners();
      })
      ..on<ActiveSpeakersChangedEvent>((event) {
        // Konuşanlar değişti
        _activeSpeakers = event.speakers;
        notifyListeners();
      })
      ..on<RoomDisconnectedEvent>((event) {
        debugPrint('Oda bağlantısı kesildi');
        disconnect();
      });
  }

  void _updateParticipants() {
    if (_room == null) return;
    
    // Remote katılımcılar
    final remoteParticipants = _room!.remoteParticipants.values.toList();
    
    // Local katılımcı (varsa)
    final localParticipant = _room!.localParticipant;
    
    _participants = [
      if (localParticipant != null) localParticipant,
      ...remoteParticipants
    ];
  }
}
