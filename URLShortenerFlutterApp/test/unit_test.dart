import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_shortener/models/user.dart';
import 'package:url_shortener/models/short_link.dart';
import 'package:url_shortener/services/api_service.dart';
import 'package:url_shortener/providers/providers.dart';

// 1. Mock Repository / ApiService class that overrides all live HTTP requests
class MockApiService extends ApiService {
  bool didCallSignup = false;
  bool didCallLogin = false;
  bool didCallShorten = false;
  bool didCallGetLinks = false;
  bool didCallGetSummary = false;

  @override
  Future<Map<String, dynamic>> signup(String name, String email, String password) async {
    didCallSignup = true;
    // Mock Registration Response payload
    return {
      'token': 'mock-jwt-token-signup',
      'user': {
        'id': 'mock-user-123',
        'name': name,
        'email': email,
      }
    };
  }

  @override
  Future<Map<String, dynamic>> login(String email, String password) async {
    didCallLogin = true;
    // Mock Login Response payload
    return {
      'token': 'mock-jwt-token-login',
      'user': {
        'id': 'mock-user-123',
        'name': 'Jane Doe',
        'email': email,
      }
    };
  }

  @override
  Future<Map<String, dynamic>> shorten({
    required String longUrl,
    String? customSlug,
    DateTime? expiryDate,
    Map<String, dynamic>? deepLinkCfg,
  }) async {
    didCallShorten = true;
    // Mock Shorten URL Response payload
    return {
      'id': 'mock-link-uuid',
      'shortCode': customSlug ?? 'mockCode',
      'longUrl': longUrl,
      'status': 'ACTIVE',
      'clickCount': 0,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'deepLinkCfg': deepLinkCfg,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getLinks({int page = 0, int size = 20}) async {
    didCallGetLinks = true;
    // Mock paginated links response content
    return [
      {
        'id': 'mock-link-uuid',
        'shortCode': 'mockCode',
        'longUrl': 'https://flutter.dev',
        'status': 'ACTIVE',
        'clickCount': 10,
        'createdAt': '2026-07-03T12:00:00Z',
      }
    ];
  }

  @override
  Future<Map<String, dynamic>> getAnalyticsSummary() async {
    didCallGetSummary = true;
    // Mock analytics dashboard metrics
    return {
      'totalClicks': 250,
      'activeUrls': 12,
      'weeklyGrowth': 14.8,
    };
  }

  @override
  Future<bool> hasToken() async {
    return false;
  }
}

void main() {
  // Setup SharedPreferences in initial mock state
  SharedPreferences.setMockInitialValues({});

  group('Riverpod Notifiers & API Mock Flow Tests', () {
    late ProviderContainer container;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('AuthNotifier - signup flow updates state and triggers storage', () async {
      // 1. Initially should start as loading/unauthenticated
      expect(container.read(authProvider).isAuthenticated, false);

      // 2. Perform signup action
      final notifier = container.read(authProvider.notifier);
      await notifier.signup('Jane Doe', 'jane@test.com', 'password123');

      // 3. Verify mock service called and state updated
      expect(mockApiService.didCallSignup, true);
      final authState = container.read(authProvider);
      expect(authState.isAuthenticated, true);
      expect(authState.user!.name, 'Jane Doe');
      expect(authState.user!.email, 'jane@test.com');
    });

    test('AuthNotifier - login flow updates state and extracts user', () async {
      // 1. Perform login action
      final notifier = container.read(authProvider.notifier);
      await notifier.login('jane@test.com', 'password123');

      // 2. Verify mock login response mapping
      expect(mockApiService.didCallLogin, true);
      final authState = container.read(authProvider);
      expect(authState.isAuthenticated, true);
      expect(authState.user!.id, 'mock-user-123');
    });

    test('HistoryNotifier - refresh flow fetches and maps data', () async {
      final notifier = container.read(historyProvider.notifier);
      
      // 1. Initial State should be empty
      expect(container.read(historyProvider).links, isEmpty);

      // 2. Trigger Refresh logic
      await notifier.refresh();

      // 3. Verify multiple mock APIs called and dashboard metrics populated
      expect(mockApiService.didCallGetSummary, true);
      expect(mockApiService.didCallGetLinks, true);

      final state = container.read(historyProvider);
      expect(state.links.length, 1);
      expect(state.links.first.shortCode, 'mockCode');
      expect(state.longTotalClicks, 250);
      expect(state.activeUrls, 12);
      expect(state.weeklyGrowth, 14.8);
    });

    test('HistoryNotifier - shorten URL triggers list reload', () async {
      final notifier = container.read(historyProvider.notifier);

      // 1. Call Shorten Link action
      final newLink = await notifier.shorten(
        longUrl: 'https://flutter.dev',
        customSlug: 'custom',
        deepLinkCfg: {'enabled': true, 'destination': 'app://flutter'},
      );

      // 2. Verify link shortening succeeded
      expect(mockApiService.didCallShorten, true);
      expect(newLink, isNotNull);
      expect(newLink!.shortCode, 'custom');

      // 3. Verify that refresh was triggered automatically to update list count
      expect(mockApiService.didCallGetLinks, true);
      final state = container.read(historyProvider);
      expect(state.links.length, 1);
    });
  });
}
