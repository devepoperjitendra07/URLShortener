import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';
import 'overview_view.dart';
import 'apps_view.dart';
import 'links_view.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final int currentTab;
  const DashboardScreen({super.key, required this.currentTab});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(appsProvider.notifier).fetchApps();
      ref.read(linksProvider.notifier).fetchLinks();
    });
  }

  void _onTabSelect(int index) {
    if (index == 0) {
      context.go('/dashboard');
    } else if (index == 1) {
      context.go('/apps');
    } else if (index == 2) {
      context.go('/links');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    final tabs = [
      const OverviewView(),
      const AppsView(),
      const LinksView(),
    ];

    final sidebarItems = [
      _SidebarItem(icon: Icons.dashboard_outlined, label: 'Dashboard'),
      _SidebarItem(icon: Icons.apps, label: 'Apps'),
      _SidebarItem(icon: Icons.link, label: 'Links'),
    ];

    Widget buildSidebar() {
      return Container(
        width: 250,
        color: const Color(0xFF0F172A),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.link, color: Color(0xFF6366F1), size: 28),
                const SizedBox(width: 8),
                const Text(
                  'GoIndiaTracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Expanded(
              child: ListView.builder(
                itemCount: sidebarItems.length,
                itemBuilder: (context, idx) {
                  final item = sidebarItems[idx];
                  final isSelected = widget.currentTab == idx;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: ListTile(
                      onTap: () => _onTabSelect(idx),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tileColor: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
                      leading: Icon(
                        item.icon,
                        color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Color(0xFF334155), height: 1),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                onTap: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      drawer: !isDesktop
          ? Drawer(
              child: buildSidebar(),
            )
          : null,
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: const Color(0xFF0F172A),
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              title: const Text(
                'GoIndiaTracker',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      body: Row(
        children: [
          if (isDesktop) buildSidebar(),
          Expanded(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: tabs[widget.currentTab],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem {
  final IconData icon;
  final String label;

  _SidebarItem({required this.icon, required this.label});
}
