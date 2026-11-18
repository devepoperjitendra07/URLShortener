import 'deep_link_config.dart';

enum LinkStatus { active, broken, expired }

class ShortLink {
  final String id;
  final String shortCode;
  final String longUrl;
  final LinkStatus status;
  final int clickCount;
  final DateTime createdAt;
  final DateTime? expiryDate;
  final DeepLinkConfig? deepLinkCfg;

  ShortLink({
    required this.id,
    required this.shortCode,
    required this.longUrl,
    required this.status,
    required this.clickCount,
    required this.createdAt,
    this.expiryDate,
    this.deepLinkCfg,
  });

  factory ShortLink.fromJson(Map<String, dynamic> json) {
    LinkStatus statusVal = LinkStatus.active;
    String statusStr = json['status'] as String? ?? 'ACTIVE';
    if (statusStr == 'BROKEN') {
      statusVal = LinkStatus.broken;
    } else if (statusStr == 'EXPIRED') {
      statusVal = LinkStatus.expired;
    }

    return ShortLink(
      id: json['id'] as String? ?? '',
      shortCode: json['shortCode'] as String? ?? '',
      longUrl: json['longUrl'] as String? ?? '',
      status: statusVal,
      clickCount: (json['clickCount'] as num? ?? 0).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
      deepLinkCfg: json['deepLinkCfg'] != null 
          ? DeepLinkConfig.fromJson(json['deepLinkCfg'] as Map<String, dynamic>)
          : null,
    );
  }
}
