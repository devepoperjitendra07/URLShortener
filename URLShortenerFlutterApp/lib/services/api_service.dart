import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';


class ApiService {
  static const String baseUrl = AppConfig.apiBaseUrl;
  late final Dio dio;

  ApiService() {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // ignore: avoid_print
        print('[API ERROR] ${e.response?.statusCode}: ${e.response?.data}');
        return handler.next(e);
      },
    ));
  }

  // Auth: Signup
  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    final response = await dio.post('/auth/signup', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    return data;
  }

  // Auth: Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    return data;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Check if logged in
  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('auth_token');
  }

  // Shorten URL
  Future<Map<String, dynamic>> shorten({
    required String longUrl,
    String? customSlug,
    DateTime? expiryDate,
    Map<String, dynamic>? deepLinkCfg,
  }) async {
    final data = {
      'longUrl': longUrl,
      'packageName': 'com.studyiq.android',
      if (customSlug != null && customSlug.isNotEmpty) 'customSlug': customSlug,
      if (expiryDate != null) 'expiryDate': expiryDate.toUtc().toIso8601String(),
      if (deepLinkCfg != null) 'deepLinkCfg': deepLinkCfg,
    };
    final response = await dio.post('/shorten', data: data);
    return response.data as Map<String, dynamic>;
  }

  // Get User Links (Paginated)
  Future<List<Map<String, dynamic>>> getLinks({int page = 0, int size = 20}) async {
    final response = await dio.get('/links', queryParameters: {
      'page': page,
      'size': size,
    });
    final content = response.data['content'] as List;
    return content.map((e) => e as Map<String, dynamic>).toList();
  }

  // Delete Link
  Future<void> deleteLink(String id) async {
    await dio.delete('/links/$id');
  }

  // Get Analytics Summary
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    final response = await dio.get('/analytics/summary');
    return response.data as Map<String, dynamic>;
  }

  // Get Specific Link Analytics
  Future<Map<String, dynamic>> getLinkAnalytics(String shortCode) async {
    final response = await dio.get('/analytics/$shortCode');
    return response.data as Map<String, dynamic>;
  }

  // Get System Status
  Future<Map<String, dynamic>> getSystemStatus() async {
    final response = await dio.get('/system/status');
    return response.data as Map<String, dynamic>;
  }

  // Get System DDL Logs
  Future<List<Map<String, dynamic>>> getDdlLogs({int page = 0, int size = 20}) async {
    final response = await dio.get('/system/ddl-logs', queryParameters: {
      'page': page,
      'size': size,
    });
    final content = response.data['content'] as List;
    return content.map((e) => e as Map<String, dynamic>).toList();
  }

  // Resolve Deferred Deep Link
  Future<Map<String, dynamic>> resolveDdl(String fingerprint) async {
    final response = await dio.post('/ddl/resolve', data: {
      'fingerprint': fingerprint,
    });
    return response.data as Map<String, dynamic>;
  }

  // Resolve Direct Deep Link
  Future<Map<String, dynamic>> resolveDirectDdl(String code) async {
    final response = await dio.get('/ddl/resolve-direct/$code');
    return response.data as Map<String, dynamic>;
  }

  // Resolve Deferred Deep Link using Install Referrer Session ID
  Future<Map<String, dynamic>> resolveDdlSession(String sessionId) async {
    final response = await dio.post('/ddl/resolve-referrer', data: {
      'sessionId': sessionId,
    });
    return response.data as Map<String, dynamic>;
  }
}
