/// Davet kodu modeli
class Invite {
  final String code;
  final bool isActive;
  final int maxUses;
  final int usedCount;
  final DateTime? expiresAt;
  final String createdBy;

  Invite({
    required this.code,
    required this.isActive,
    required this.maxUses,
    required this.usedCount,
    this.expiresAt,
    required this.createdBy,
  });

  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      code: json['code'] ?? '',
      isActive: json['isActive'] ?? true,
      maxUses: json['maxUses'] ?? 1,
      usedCount: json['usedCount'] ?? 0,
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : null,
      createdBy: json['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'isActive': isActive,
      'maxUses': maxUses,
      'usedCount': usedCount,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
  bool get isFull => usedCount >= maxUses;
  bool get isValid => isActive && !isExpired && !isFull;
}
