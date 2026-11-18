import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_model.dart';
import '../models/deep_link_model.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// Auth State
class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => checkInitAuth());
    return AuthState(isLoading: true);
  }

  Future<void> checkInitAuth() async {
    final apiService = ref.read(apiServiceProvider);
    final hasToken = await apiService.hasToken();
    state = AuthState(isAuthenticated: hasToken);
  }

  Future<void> login(String email, String password) async {
    state = AuthState(isLoading: true);
    final apiService = ref.read(apiServiceProvider);
    try {
      await apiService.login(email, password);
      state = AuthState(isAuthenticated: true);
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  Future<void> signup(String name, String email, String password) async {
    state = AuthState(isLoading: true);
    final apiService = ref.read(apiServiceProvider);
    try {
      await apiService.signup(name, email, password);
      state = AuthState(isAuthenticated: true);
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  Future<void> logout() async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.logout();
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// Apps Notifier
class AppsNotifier extends Notifier<List<AppModel>> {
  @override
  List<AppModel> build() {
    return [];
  }

  Future<void> fetchApps() async {
    final apiService = ref.read(apiServiceProvider);
    try {
      final raw = await apiService.getApps();
      state = raw.map((e) => AppModel.fromJson(e)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('[APPS ERROR] $e');
    }
  }

  Future<void> registerApp({
    required String name,
    String? androidPackageName,
    String? sha256Fingerprint,
    String? playStoreUrl,
    String? iosBundleId,
    String? appleTeamId,
    String? appStoreUrl,
  }) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.registerApp(
      name: name,
      androidPackageName: androidPackageName,
      sha256Fingerprint: sha256Fingerprint,
      playStoreUrl: playStoreUrl,
      iosBundleId: iosBundleId,
      appleTeamId: appleTeamId,
      appStoreUrl: appStoreUrl,
    );
    await fetchApps();
  }

  Future<void> updateApp({
    required String id,
    required String name,
    String? androidPackageName,
    String? sha256Fingerprint,
    String? playStoreUrl,
    String? iosBundleId,
    String? appleTeamId,
    String? appStoreUrl,
  }) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.updateApp(
      id: id,
      name: name,
      androidPackageName: androidPackageName,
      sha256Fingerprint: sha256Fingerprint,
      playStoreUrl: playStoreUrl,
      iosBundleId: iosBundleId,
      appleTeamId: appleTeamId,
      appStoreUrl: appStoreUrl,
    );
    await fetchApps();
  }

  Future<void> deleteApp(String appId) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.deleteApp(appId);
    await fetchApps();
  }

  Future<void> regenerateKey(String appId) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.regenerateSdkKey(appId);
    await fetchApps();
  }
}

final appsProvider = NotifierProvider<AppsNotifier, List<AppModel>>(() {
  return AppsNotifier();
});

// Links Notifier
class LinksNotifier extends Notifier<List<DeepLinkModel>> {
  @override
  List<DeepLinkModel> build() {
    return [];
  }

  Future<void> fetchLinks() async {
    final apiService = ref.read(apiServiceProvider);
    try {
      final raw = await apiService.getDeepLinks();
      state = raw.map((e) => DeepLinkModel.fromJson(e)).toList();
    } catch (e) {
      // ignore: avoid_print
      print('[LINKS ERROR] $e');
    }
  }

  Future<void> createLink({
    required String appId,
    required String name,
    String? customSlug,
    required String destinationUri,
    DateTime? expiryDate,
  }) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.createDeepLink(
      appId: appId,
      name: name,
      customSlug: customSlug,
      destinationUri: destinationUri,
      expiryDate: expiryDate,
    );
    await fetchLinks();
  }

  Future<void> updateLink({
    required String linkId,
    required String appId,
    required String name,
    String? customSlug,
    required String destinationUri,
    DateTime? expiryDate,
  }) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.updateDeepLink(
      linkId: linkId,
      appId: appId,
      name: name,
      customSlug: customSlug,
      destinationUri: destinationUri,
      expiryDate: expiryDate,
    );
    await fetchLinks();
  }

  Future<void> deleteLink(String linkId) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.deleteDeepLink(linkId);
    await fetchLinks();
  }
}

final linksProvider = NotifierProvider<LinksNotifier, List<DeepLinkModel>>(() {
  return LinksNotifier();
});
