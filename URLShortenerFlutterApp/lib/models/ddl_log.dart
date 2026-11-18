class DdlLog {
  final int id;
  final String level;
  final String tag;
  final String message;
  final String? deviceId;
  final String? sessionId;
  final DateTime createdAt;

  DdlLog({
    required this.id,
    required this.level,
    required this.tag,
    required this.message,
    this.deviceId,
    this.sessionId,
    required this.createdAt,
  });

  factory DdlLog.fromJson(Map<String, dynamic> json) {
    return DdlLog(
      id: (json['id'] as num? ?? 0).toInt(),
      level: json['level'] as String? ?? 'INFO',
      tag: json['tag'] as String? ?? 'SYSTEM',
      message: json['message'] as String? ?? '',
      deviceId: json['deviceId'] as String?,
      sessionId: json['sessionId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
