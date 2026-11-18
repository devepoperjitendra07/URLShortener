class DeepLinkConfig {
  final bool enabled;
  final String destination;
  final Map<String, String> params;

  DeepLinkConfig({
    required this.enabled,
    required this.destination,
    required this.params,
  });

  factory DeepLinkConfig.fromJson(Map<String, dynamic> json) {
    return DeepLinkConfig(
      enabled: json['enabled'] as bool? ?? false,
      destination: json['destination'] as String? ?? '',
      params: Map<String, String>.from(json['params'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'destination': destination,
      'params': params,
    };
  }
}
