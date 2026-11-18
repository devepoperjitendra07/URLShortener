class SystemStatus {
  final String version;
  final int latencyMs;
  final double hitRate;
  final String memoryUsage;
  final int activeConnections;
  final Map<String, bool> verifications;

  SystemStatus({
    required this.version,
    required this.latencyMs,
    required this.hitRate,
    required this.memoryUsage,
    required this.activeConnections,
    required this.verifications,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      version: json['version'] as String? ?? 'v1.0.0',
      latencyMs: (json['latencyMs'] as num? ?? 0).toInt(),
      hitRate: (json['hitRate'] as num? ?? 0.0).toDouble(),
      memoryUsage: json['memoryUsage'] as String? ?? '0B/0B',
      activeConnections: (json['activeConnections'] as num? ?? 0).toInt(),
      verifications: Map<String, bool>.from(json['verifications'] as Map? ?? {}),
    );
  }
}
