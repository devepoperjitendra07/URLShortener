import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String domain;
  final String sdkKey;

  ApiClient({required this.domain, required this.sdkKey});

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-SDK-Key': sdkKey,
      };

  Future<Map<String, dynamic>?> resolveDdl(String fingerprint, String ip) async {
    try {
      final response = await http.post(
        Uri.parse('$domain/api/ddl/resolve'),
        headers: _headers,
        body: jsonEncode({
          'fingerprint': fingerprint,
          'ip': ip,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('[GoIndiaTracker] Failed to resolve DDL: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> resolveDirectDdl(String shortCode) async {
    try {
      final response = await http.get(
        Uri.parse('$domain/api/ddl/resolve-direct/$shortCode'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('[GoIndiaTracker] Failed to resolve Direct DDL: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> resolveDdlSession(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$domain/api/ddl/resolve-referrer'),
        headers: _headers,
        body: jsonEncode({
          'sessionId': sessionId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('[GoIndiaTracker] Failed to resolve Referrer Session: $e');
    }
    return null;
  }
}
