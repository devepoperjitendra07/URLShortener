import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/short_link.dart';
import '../services/api_service.dart';


// Service providers
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());



// Auth state class
class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth notifier using modern Notifier API
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => _checkInitAuth());
    return AuthState(isLoading: true);
  }

  Future<void> _checkInitAuth() async {
    state = state.copyWith(isLoading: true);
    final apiService = ref.read(apiServiceProvider);
    final hasToken = await apiService.hasToken();
    if (hasToken) {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('user_id') ?? '';
      final name = prefs.getString('user_name') ?? '';
      final email = prefs.getString('user_email') ?? '';
      
      if (id.isNotEmpty) {
        state = AuthState(
          isAuthenticated: true,
          user: User(id: id, name: name, email: email),
        );
        return;
      }
    }
    state = AuthState(isAuthenticated: false);
  }

  Future<void> signup(String name, String email, String password) async {
    state = state.copyWith(isLoading: true);
    final apiService = ref.read(apiServiceProvider);
    try {
      final res = await apiService.signup(name, email, password);
      final user = User.fromJson(res['user']);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_email', user.email);

      state = AuthState(isAuthenticated: true, user: user);
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    final apiService = ref.read(apiServiceProvider);
    try {
      final res = await apiService.login(email, password);
      final user = User.fromJson(res['user']);
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_name', user.name);
      await prefs.setString('user_email', user.email);

      state = AuthState(isAuthenticated: true, user: user);
    } catch (e) {
      state = AuthState(error: e.toString());
    }
  }

  Future<void> logout() async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    state = AuthState(isAuthenticated: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// Link history state class
class HistoryState {
  final bool isLoading;
  final List<ShortLink> links;
  final int longTotalClicks;
  final int activeUrls;
  final double weeklyGrowth;
  final String? error;

  HistoryState({
    this.isLoading = false,
    this.links = const [],
    this.longTotalClicks = 0,
    this.activeUrls = 0,
    this.weeklyGrowth = 0.0,
    this.error,
  });

  HistoryState copyWith({
    bool? isLoading,
    List<ShortLink>? links,
    int? longTotalClicks,
    int? activeUrls,
    double? weeklyGrowth,
    String? error,
  }) {
    return HistoryState(
      isLoading: isLoading ?? this.isLoading,
      links: links ?? this.links,
      longTotalClicks: longTotalClicks ?? this.longTotalClicks,
      activeUrls: activeUrls ?? this.activeUrls,
      weeklyGrowth: weeklyGrowth ?? this.weeklyGrowth,
      error: error,
    );
  }
}

// Links history notifier using modern Notifier API
class HistoryNotifier extends Notifier<HistoryState> {
  @override
  HistoryState build() {
    return HistoryState();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    final apiService = ref.read(apiServiceProvider);
    try {
      final summary = await apiService.getAnalyticsSummary();
      final totalClicks = (summary['totalClicks'] as num? ?? 0).toInt();
      final activeUrls = (summary['activeUrls'] as num? ?? 0).toInt();
      final weeklyGrowth = (summary['weeklyGrowth'] as num? ?? 0.0).toDouble();

      final rawLinks = await apiService.getLinks(page: 0, size: 50);
      final List<ShortLink> linksList = rawLinks.map((e) => ShortLink.fromJson(e)).toList();

      state = HistoryState(
        links: linksList,
        longTotalClicks: totalClicks,
        activeUrls: activeUrls,
        weeklyGrowth: weeklyGrowth,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ShortLink?> shorten({
    required String longUrl,
    String? customSlug,
    DateTime? expiryDate,
    Map<String, dynamic>? deepLinkCfg,
  }) async {
    final apiService = ref.read(apiServiceProvider);
    try {
      final res = await apiService.shorten(
        longUrl: longUrl,
        customSlug: customSlug,
        expiryDate: expiryDate,
        deepLinkCfg: deepLinkCfg,
      );
      await refresh();
      return ShortLink.fromJson(res);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteLink(String id) async {
    final apiService = ref.read(apiServiceProvider);
    try {
      await apiService.deleteLink(id);
      await refresh();
    } catch (_) {
      rethrow;
    }
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, HistoryState>(() {
  return HistoryNotifier();
});
