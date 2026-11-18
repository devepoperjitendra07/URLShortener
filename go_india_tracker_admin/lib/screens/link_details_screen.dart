import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/deep_link_model.dart';
import '../providers/providers.dart';

class LinkDetailsScreen extends ConsumerStatefulWidget {
  final String linkId;
  const LinkDetailsScreen({super.key, required this.linkId});

  @override
  ConsumerState<LinkDetailsScreen> createState() => _LinkDetailsScreenState();
}

class _LinkDetailsScreenState extends ConsumerState<LinkDetailsScreen> {
  DeepLinkModel? _linkDetails;
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLinkDetails();
  }

  Future<void> _loadLinkDetails() async {
    final apiService = ref.read(apiServiceProvider);
    try {
      final res = await apiService.getDeepLinkDetails(widget.linkId);
      final model = DeepLinkModel.fromJson(res);
      Map<String, dynamic>? analytics;
      try {
        analytics = await apiService.getLinkAnalytics(model.shortCode);
      } catch (e) {
        print('Failed to load analytics: $e');
      }

      if (mounted) {
        setState(() {
          _linkDetails = model;
          _analytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load link details: $e'), backgroundColor: Colors.redAccent),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _deleteLink() async {
    final apiService = ref.read(apiServiceProvider);
    try {
      await apiService.deleteDeepLink(widget.linkId);
      ref.read(linksProvider.notifier).fetchLinks();
      if (mounted) {
        context.go('/links');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deep link deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0F19),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    if (_linkDetails == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B0F19),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Deep link details not found', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final link = _linkDetails!;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/links'),
        ),
        title: Row(
          children: [
            Text(
              'Link Details',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
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
                  color: link.status == 'ACTIVE' ? const Color(0xFF10B981) : Colors.redAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _deleteLink,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Copy URL display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link.shortUrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Color(0xFF9CA3AF)),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link.shortUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Short URL copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Metrics
            Row(
              children: [
                Expanded(child: _metricCard('CLICKS', '${link.clickCount}', Icons.ads_click)),
                const SizedBox(width: 16),
                Expanded(child: _metricCard('INSTALLS', '${(link.clickCount * 0.25).toInt()}', Icons.download)),
                const SizedBox(width: 16),
                Expanded(child: _metricCard('MATCH RATE', '25.8%', Icons.check_circle_outline)),
              ],
            ),
            const SizedBox(height: 24),

            // Content Split
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configuration Details',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        _detailRow('LINK NAME', link.name),
                        _detailRow('TARGET APP', link.targetAppName),
                        _detailRow('PACKAGE NAME', link.targetAppPackageName),
                        _detailRow('DESTINATION URI', link.destinationUri),
                        _detailRow('CREATED DATE', '${link.createdAt.month}/${link.createdAt.day}/${link.createdAt.year}'),
                        _detailRow(
                          'EXPIRATION',
                          link.expiryDate == null
                              ? 'Never'
                              : '${link.expiryDate!.month}/${link.expiryDate!.day}/${link.expiryDate!.year}',
                        ),
                      ],
                    ),
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Campaign Sources (UTM)',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 16),
                              if (_analytics != null && _analytics!['utmDistribution'] != null && (_analytics!['utmDistribution'] as List).isNotEmpty)
                                ...(_analytics!['utmDistribution'] as List).map((u) {
                                  final source = u['utmSource'] ?? 'Unknown';
                                  final campaign = u['utmCampaign'] ?? 'Direct';
                                  final count = u['count'] ?? 0;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '$source / $campaign',
                                            style: const TextStyle(color: Colors.white, fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          '$count clicks',
                                          style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList()
                              else
                                const Text(
                                  'No UTM data available yet.',
                                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                ]
              ],
            )
          ],
        ),
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
              Icon(icon, color: const Color(0xFF6366F1), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
