import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'package:android_play_install_referrer/android_play_install_referrer.dart';

import 'src/api_client.dart';
import 'src/fingerprinter.dart';

class DeepLinkData {
  final bool matchFound;
  final String? shortCode;
  final String? longUrl;
  final String? targetDestination;
  final Map<String, dynamic>? params;
  
  final String? utmSource;
  final String? utmMedium;
  final String? utmCampaign;
  final String? utmTerm;
  final String? utmContent;

  DeepLinkData({
    required this.matchFound,
    this.shortCode,
    this.longUrl,
    this.targetDestination,
    this.params,
    this.utmSource,
    this.utmMedium,
    this.utmCampaign,
    this.utmTerm,
    this.utmContent,
  });
}

class GoIndiaTracker {
  static late ApiClient _apiClient;
  static late AppLinks _appLinks;
  
  static final StreamController<DeepLinkData> _deepLinkController = StreamController<DeepLinkData>.broadcast();
  static Stream<DeepLinkData> get onDeepLinkReceived => _deepLinkController.stream;

  static Future<void> init({required String sdkKey, String? customDomain}) async {
    // Resolve the backend host: explicit customDomain wins, else a compile-time
    // --dart-define (TRACKER_DOMAIN), else localhost. No host is hardcoded.
    final domain = customDomain ??
        const String.fromEnvironment('TRACKER_DOMAIN',
            defaultValue: 'http://localhost:8082');
    _apiClient = ApiClient(domain: domain, sdkKey: sdkKey);
    _appLinks = AppLinks();

    // 1. Check for Deferred Deep Links (First Launch Only)
    await _checkDeferredDeepLink();

    // 2. Listen for Standard App Links (Direct Launch)
    _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDirectLink(uri);
    });
  }

  static Future<String> getDeviceFingerprint() {
    return Fingerprinter.getDeviceFingerprint();
  }

  static Future<Map<String, String>?> _checkInstallReferrer() async {
    if (!Platform.isAndroid) return null;
    try {
      final referrerDetails = await AndroidPlayInstallReferrer.installReferrer;
      final referrerString = referrerDetails.installReferrer;
      print('[GoIndiaTracker] Install Referrer string: $referrerString');
      
      if (referrerString != null) {
        final parsed = Uri.splitQueryString(referrerString);
        if (parsed.containsKey('click_token') || parsed.containsKey('utm_source')) {
          return parsed;
        }
      }
    } catch (e) {
      print('[GoIndiaTracker] Failed to get Install Referrer: $e');
    }
    return null;
  }

  static Future<void> _checkDeferredDeepLink() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('go_india_tracker_first_launch') ?? true;
    
    if (!isFirstLaunch) return;

    try {
      // 1. Try Deterministic Install Referrer (Android only)
      final referrerMap = await _checkInstallReferrer();
      Map<String, dynamic>? result;
      Map<String, String>? organicUtms;

      if (referrerMap != null && referrerMap.containsKey('click_token')) {
        final sessionId = referrerMap['click_token'];
        print('[GoIndiaTracker] Resolving deep link with Referrer Session ID: $sessionId');
        result = await _apiClient.resolveDdlSession(sessionId!);
      } else if (referrerMap != null) {
        organicUtms = referrerMap;
      }
      
      // 2. Fallback to Probabilistic Fingerprint
      if (result == null && organicUtms == null) {
        final fingerprint = await Fingerprinter.getDeviceFingerprint();
        print('[GoIndiaTracker] Checking DDL with fingerprint: $fingerprint');
        result = await _apiClient.resolveDdl(fingerprint, '127.0.0.1'); // In real env, backend grabs IP
      }

      if (result != null && result['enabled'] == true) {
        _deepLinkController.add(DeepLinkData(
          matchFound: true,
          shortCode: result['shortCode'],
          longUrl: result['longUrl'],
          targetDestination: result['destination'],
          params: result['params'],
          utmSource: result['utmSource'],
          utmMedium: result['utmMedium'],
          utmCampaign: result['utmCampaign'],
          utmTerm: result['utmTerm'],
          utmContent: result['utmContent'],
        ));
      } else if (organicUtms != null) {
        _deepLinkController.add(DeepLinkData(
          matchFound: false, // Not a short-link match, but we have organic UTMs
          utmSource: organicUtms['utm_source'],
          utmMedium: organicUtms['utm_medium'],
          utmCampaign: organicUtms['utm_campaign'],
          utmTerm: organicUtms['utm_term'],
          utmContent: organicUtms['utm_content'],
        ));
      } else {
        _deepLinkController.add(DeepLinkData(matchFound: false));
      }
      
      await prefs.setBool('go_india_tracker_first_launch', false);
    } catch (e) {
      print('[GoIndiaTracker] DDL Check failed: $e');
      await prefs.setBool('go_india_tracker_first_launch', false);
    }
  }

  static Future<void> _handleDirectLink(Uri uri) async {
    final pathSegments = uri.pathSegments;
    String? shortCode;

    for (int i = 0; i < pathSegments.length; i++) {
      if ((pathSegments[i] == 'r' || pathSegments[i] == 'api' && i + 1 < pathSegments.length && pathSegments[i+1] == 'r') && i + 1 < pathSegments.length) {
        shortCode = pathSegments[i + 1];
        if (pathSegments[i] == 'api') shortCode = pathSegments[i + 2];
        break;
      }
    }

    if (shortCode != null) {
      final result = await _apiClient.resolveDirectDdl(shortCode);
      if (result != null && result['enabled'] == true) {
        _deepLinkController.add(DeepLinkData(
          matchFound: true,
          shortCode: result['shortCode'],
          longUrl: result['longUrl'],
          targetDestination: result['destination'],
          params: result['params'],
          utmSource: result['utmSource'] ?? uri.queryParameters['utm_source'],
          utmMedium: result['utmMedium'] ?? uri.queryParameters['utm_medium'],
          utmCampaign: result['utmCampaign'] ?? uri.queryParameters['utm_campaign'],
          utmTerm: result['utmTerm'] ?? uri.queryParameters['utm_term'],
          utmContent: result['utmContent'] ?? uri.queryParameters['utm_content'],
        ));
      }
    }
  }
}
