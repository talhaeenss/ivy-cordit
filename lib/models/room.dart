/// Oda modeli
class Room {
  final String id;
  final String name;
  final String type; // 'text' veya 'voice'
  final String? livekitRoomName;

  Room({
    required this.id,
    required this.name,
    required this.type,
    this.livekitRoomName,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'text',
      livekitRoomName: json['livekitRoomName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'livekitRoomName': livekitRoomName,
    };
  }

  bool get isVoice => type == 'voice';
}
