class DeepLinkModel {
  final String id;
  final String shortUrl;
  final String longUrl;
  final String shortCode;
  final String name;
  final String targetAppName;
  final String targetAppId;
  final String targetAppPackageName;
  final String destinationUri;
  final Map<String, dynamic>? params;
  final int clickCount;
  final String status;
  final DateTime? expiryDate;
  final DateTime createdAt;

  DeepLinkModel({
    required this.id,
    required this.shortUrl,
    required this.longUrl,
    required this.shortCode,
    required this.name,
    required this.targetAppName,
    required this.targetAppId,
    required this.targetAppPackageName,
    required this.destinationUri,
    this.params,
    required this.clickCount,
    required this.status,
    this.expiryDate,
    required this.createdAt,
  });

  factory DeepLinkModel.fromJson(Map<String, dynamic> json) {
    return DeepLinkModel(
      id: json['id'] ?? '',
      shortUrl: json['shortUrl'] ?? '',
      longUrl: json['longUrl'] ?? '',
      shortCode: json['shortCode'] ?? '',
      name: json['name'] ?? '',
      targetAppName: json['targetAppName'] ?? '',
      targetAppId: json['targetAppId'] ?? '',
      targetAppPackageName: json['targetAppPackageName'] ?? '',
      destinationUri: json['destinationUri'] ?? '',
      params: json['params'] != null ? Map<String, dynamic>.from(json['params']) : null,
      clickCount: (json['clickCount'] as num? ?? 0).toInt(),
      status: json['status'] ?? 'ACTIVE',
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }
}
