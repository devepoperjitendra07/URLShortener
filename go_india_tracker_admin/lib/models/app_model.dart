class AppModel {
  final String id;
  final String name;
  final String? androidPackageName;
  final String? sha256Fingerprint;
  final String? playStoreUrl;
  final String? iosBundleId;
  final String? appleTeamId;
  final String? appStoreUrl;
  final String sdkKey;
  final DateTime createdAt;

  AppModel({
    required this.id,
    required this.name,
    this.androidPackageName,
    this.sha256Fingerprint,
    this.playStoreUrl,
    this.iosBundleId,
    this.appleTeamId,
    this.appStoreUrl,
    required this.sdkKey,
    required this.createdAt,
  });

  factory AppModel.fromJson(Map<String, dynamic> json) {
    return AppModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      androidPackageName: json['androidPackageName'],
      sha256Fingerprint: json['sha256Fingerprint'],
      playStoreUrl: json['playStoreUrl'],
      iosBundleId: json['iosBundleId'],
      appleTeamId: json['appleTeamId'],
      appStoreUrl: json['appStoreUrl'],
      sdkKey: json['sdkKey'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'androidPackageName': androidPackageName,
      'sha256Fingerprint': sha256Fingerprint,
      'playStoreUrl': playStoreUrl,
      'iosBundleId': iosBundleId,
      'appleTeamId': appleTeamId,
      'appStoreUrl': appStoreUrl,
      'sdkKey': sdkKey,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
