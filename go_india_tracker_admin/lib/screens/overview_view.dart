import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/providers.dart';

class OverviewView extends ConsumerWidget {
  const OverviewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(appsProvider);
    final links = ref.watch(linksProvider);

    final totalClicks = links.fold<int>(0, (sum, item) => sum + item.clickCount);
    // Simple mock install calculation for dashboard illustration
    final totalInstalls = links.fold<int>(0, (sum, item) => sum + (item.clickCount * 0.25).toInt());

    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Platform Overview',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'System performance metrics and recent activity.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/apps'),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Register App'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF334155)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/links'),
                    icon: const Icon(Icons.bolt, size: 16),
                    label: const Text('Create Link'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),

          // Metrics Grid
          GridView.count(
            crossAxisCount: isDesktop ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 1.6 : 1.3,
            children: [
              _metricCard('TOTAL APPS', '${apps.length}', Icons.apps),
              _metricCard('ACTIVE LINKS', '${links.length}', Icons.link),
              _metricCard('TOTAL CLICKS', '$totalClicks', Icons.trending_up),
              _metricCard('ATTRIBUTED INSTALLS', '$totalInstalls', Icons.download),
            ],
          ),
          const SizedBox(height: 32),

          // Registered Apps Section Title
          const Text(
            'Registered Apps',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Apps Row (Responsive layout)
          apps.isEmpty
              ? const Card(
                  color: Color(0xFF1E293B),
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text('No apps registered. Add an app in the Apps tab.',
                          style: TextStyle(color: Color(0xFF9CA3AF))),
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: apps.length > 2 ? 2 : apps.length, // Limit to 2 for dashboard overview
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 2.5 : 2.0,
                  ),
                  itemBuilder: (context, idx) {
                    final app = apps[idx];
                    return _appCard(context, app, ref);
                  },
                ),
          const SizedBox(height: 32),

          // Recent Link Activity Section
          const Text(
            'Recent Link Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Link Activity Table
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: links.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text('No deep links created yet.', style: TextStyle(color: Color(0xFF9CA3AF))),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Container(
                        color: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: const [
                            Expanded(child: Text('LINK (SLUG)', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(child: Text('APP', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(child: Text('CLICKS', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(child: Text('STATUS', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 12))),
                            Text('ACTIONS', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Rows
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: links.length > 5 ? 5 : links.length,
                        separatorBuilder: (context, idx) => const Divider(color: Color(0xFF334155), height: 1),
                        itemBuilder: (context, idx) {
                          final link = links[idx];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () => context.go('/link-details/${link.id}'),
                                    child: Text(
                                      '/${link.shortCode}',
                                      style: const TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(child: Text(link.targetAppName, style: const TextStyle(color: Colors.white))),
                                Expanded(child: Text('${link.clickCount}', style: const TextStyle(color: Colors.white))),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: link.status == 'ACTIVE'
                                              ? const Color(0xFF10B981).withOpacity(0.2)
                                              : Colors.redAccent.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          link.status,
                                          style: TextStyle(
                                            color: link.status == 'ACTIVE'
                                                ? const Color(0xFF10B981)
                                                : Colors.redAccent,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.bar_chart, color: Color(0xFF9CA3AF), size: 18),
                                      onPressed: () => context.go('/link-details/${link.id}'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                      onPressed: () {
                                        ref.read(linksProvider.notifier).deleteLink(link.id);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: const Color(0xFF6366F1), size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _appCard(BuildContext context, dynamic app, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Row(
                    children: [
                      if (app.androidPackageName != null)
                        const Icon(Icons.android, color: Color(0xFF6366F1), size: 24),
                      if (app.androidPackageName != null && app.iosBundleId != null)
                        const SizedBox(width: 4),
                      if (app.iosBundleId != null)
                        const Icon(Icons.phone_iphone, color: Color(0xFF6366F1), size: 24),
                      if (app.androidPackageName == null && app.iosBundleId == null)
                        const Icon(Icons.apps, color: Color(0xFF6366F1), size: 24),
                    ],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    app.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            [if (app.androidPackageName != null) app.androidPackageName, if (app.iosBundleId != null) app.iosBundleId].join(' / '),
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F19),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    app.sdkKey,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.copy, color: Color(0xFF9CA3AF), size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: app.sdkKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SDK Key copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
