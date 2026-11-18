import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_india_tracker/go_india_tracker.dart';
import 'config/app_config.dart';
import 'providers/providers.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    _initDeepLinking();
  }

  void _initDeepLinking() async {
    print('[DDL] _initDeepLinking: Initializing SDK deep link handlers');
    
    // Initialize the GoIndiaTracker SDK. Key and backend host come from
    // AppConfig (override with --dart-define), never hardcoded here.
    GoIndiaTracker.init(
      sdkKey: AppConfig.sdkKey,
      customDomain: AppConfig.apiBaseUrl.replaceAll('/api', ''),
    );

    // Listen for all deep link matches (Deferred and Direct)
    GoIndiaTracker.onDeepLinkReceived.listen((DeepLinkData data) {
      if (data.matchFound && data.targetDestination != null) {
        print('[DDL] GoIndiaTracker \n-target destination: ${data.longUrl}\n-custom slug: ${data.shortCode}');
        if (mounted) {
          _showDdlDialog(data.targetDestination!, isDeferred: false); // We don't distinguish UI strictly here anymore
        }
      } else {
        print('[DDL] GoIndiaTracker found no match.');
      }
    });
  }



  void _showDdlDialog(String destination, {required bool isDeferred}) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
          ),
          title: Row(
            children: [
              Icon(
                isDeferred ? Icons.phonelink_ring : Icons.bolt,
                color: const Color(0xFF6366F1),
              ),
              const SizedBox(width: 8),
              Text(
                isDeferred ? 'Deferred Deep Link' : 'Direct Deep Link',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isDeferred
                    ? 'A deferred deep link was matched and resolved successfully on first launch!'
                    : 'A direct deep link was matched and resolved successfully!',
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text(
                'DESTINATION PATH',
                style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0F19),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  destination,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('DISMISS', style: TextStyle(color: Color(0xFF9CA3AF))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implement custom in-app deep link routing here if needed
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
              child: const Text('NAVIGATE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'URLShortener',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6366F1),
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF10B981),
          surface: Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      home: authState.isAuthenticated ? const HomeScreen() : const AuthScreen(),
    );
  }
}
