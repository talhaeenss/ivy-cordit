/// Kullanıcı modeli
class User {
  final String id;
  final String username;
  final String role;
  final String token;

  User({
    required this.id,
    required this.username,
    required this.role,
    required this.token,
  });

  /// JSON'dan User oluştur
  factory User.fromJson(Map<String, dynamic> json, {String? token}) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'user',
      token: token ?? json['token'] ?? '',
    );
  }

  /// User'ı JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'token': token,
    };
  }

  /// Kullanıcı admin mi?
  bool get isAdmin => role == 'admin';

  @override
  String toString() => 'User(id: $id, username: $username, role: $role)';
}
