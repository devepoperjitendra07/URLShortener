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
        final token = prefs.getString('admin_auth_token');
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

  // Auth: Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_auth_token', token);
    return data;
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
    await prefs.setString('admin_auth_token', token);
    return data;
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('admin_auth_token');
  }

  // Check if token exists
  Future<bool> hasToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('admin_auth_token');
  }

  // App List
  Future<List<dynamic>> getApps() async {
    final response = await dio.get('/admin/apps');
    return response.data as List<dynamic>;
  }

  // Register App
  Future<Map<String, dynamic>> registerApp({
    required String name,
    String? androidPackageName,
    String? sha256Fingerprint,
    String? playStoreUrl,
    String? iosBundleId,
    String? appleTeamId,
    String? appStoreUrl,
  }) async {
    final data = {
      'name': name,
      if (androidPackageName != null && androidPackageName.isNotEmpty) 'androidPackageName': androidPackageName,
      if (sha256Fingerprint != null && sha256Fingerprint.isNotEmpty) 'sha256Fingerprint': sha256Fingerprint,
      if (playStoreUrl != null && playStoreUrl.isNotEmpty) 'playStoreUrl': playStoreUrl,
      if (iosBundleId != null && iosBundleId.isNotEmpty) 'iosBundleId': iosBundleId,
      if (appleTeamId != null && appleTeamId.isNotEmpty) 'appleTeamId': appleTeamId,
      if (appStoreUrl != null && appStoreUrl.isNotEmpty) 'appStoreUrl': appStoreUrl,
    };
    final response = await dio.post('/admin/apps', data: data);
    return response.data as Map<String, dynamic>;
  }
  // Update App
  Future<Map<String, dynamic>> updateApp({
    required String id,
    required String name,
    String? androidPackageName,
    String? sha256Fingerprint,
    String? playStoreUrl,
    String? iosBundleId,
    String? appleTeamId,
    String? appStoreUrl,
  }) async {
    final data = {
      'name': name,
      if (androidPackageName != null && androidPackageName.isNotEmpty) 'androidPackageName': androidPackageName,
      if (sha256Fingerprint != null && sha256Fingerprint.isNotEmpty) 'sha256Fingerprint': sha256Fingerprint,
      if (playStoreUrl != null && playStoreUrl.isNotEmpty) 'playStoreUrl': playStoreUrl,
      if (iosBundleId != null && iosBundleId.isNotEmpty) 'iosBundleId': iosBundleId,
      if (appleTeamId != null && appleTeamId.isNotEmpty) 'appleTeamId': appleTeamId,
      if (appStoreUrl != null && appStoreUrl.isNotEmpty) 'appStoreUrl': appStoreUrl,
    };
    final response = await dio.put('/admin/apps/$id', data: data);
    return response.data as Map<String, dynamic>;
  }
  // Delete App
  Future<void> deleteApp(String appId) async {
    await dio.delete('/admin/apps/$appId');
  }

  // Regenerate SDK Key
  Future<Map<String, dynamic>> regenerateSdkKey(String appId) async {
    final response = await dio.post('/admin/apps/$appId/keys/regenerate');
    return response.data as Map<String, dynamic>;
  }

  // Deep Link List
  Future<List<dynamic>> getDeepLinks() async {
    final response = await dio.get('/admin/links');
    return response.data as List<dynamic>;
  }

  // Deep Link Details
  Future<Map<String, dynamic>> getDeepLinkDetails(String linkId) async {
    final response = await dio.get('/admin/links/$linkId');
    return response.data as Map<String, dynamic>;
  }

  // Create Deep Link
  Future<Map<String, dynamic>> createDeepLink({
    required String appId,
    required String name,
    String? customSlug,
    required String destinationUri,
    DateTime? expiryDate,
  }) async {
    final data = {
      'appId': appId,
      'name': name,
      if (customSlug != null && customSlug.isNotEmpty) 'customSlug': customSlug,
      'destinationUri': destinationUri,
      if (expiryDate != null) 'expiryDate': expiryDate.toUtc().toIso8601String(),
    };
    final response = await dio.post('/admin/links', data: data);
    return response.data as Map<String, dynamic>;
  }

  // Update Deep Link
  Future<Map<String, dynamic>> updateDeepLink({
    required String linkId,
    required String appId,
    required String name,
    String? customSlug,
    required String destinationUri,
    DateTime? expiryDate,
  }) async {
    final data = {
      'appId': appId,
      'name': name,
      if (customSlug != null && customSlug.isNotEmpty) 'customSlug': customSlug,
      'destinationUri': destinationUri,
      if (expiryDate != null) 'expiryDate': expiryDate.toUtc().toIso8601String(),
    };
    final response = await dio.put('/admin/links/$linkId', data: data);
    return response.data as Map<String, dynamic>;
  }

  // Delete Deep Link
  Future<void> deleteDeepLink(String linkId) async {
    await dio.delete('/admin/links/$linkId');
  }

  // Get Analytics for a link
  Future<Map<String, dynamic>> getLinkAnalytics(String shortCode) async {
    final response = await dio.get('/analytics/$shortCode');
    return response.data as Map<String, dynamic>;
  }
}
