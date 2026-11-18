import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import 'shorten_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import 'system_status_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  String? _selectedCodeForAnalytics;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final List<Widget> screens = [
      ShortenScreen(
        onNavigateToStats: (code) {
          setState(() {
            _selectedCodeForAnalytics = code;
            _currentIndex = 2; // Jump to Analytics tab
          });
        },
      ),
      const HistoryScreen(),
      AnalyticsScreen(initialCode: _selectedCodeForAnalytics),
      const SystemStatusScreen(),
    ];

    final List<String> titles = [
      'URLShortener',
      'My Links',
      'Link Analytics',
      'System Status',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.link, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Text(
              titles[_currentIndex],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          if (user != null) ...[
            Center(
              child: Text(
                user.name,
                style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
              },
            ),
          ]
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFF1E293B), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: const Color(0xFF0B0F19),
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: const Color(0xFF475569),
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
              if (index != 2) {
                // Clear selected code when leaving analytics manually
                _selectedCodeForAnalytics = null;
              }
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.link),
              label: 'Shorten',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dns_outlined),
              label: 'Status',
            ),
          ],
        ),
      ),
    );
  }
}
