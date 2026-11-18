import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'package:share_plus/share_plus.dart';
import '../models/short_link.dart';
import '../providers/providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(historyProvider.notifier).refresh();
    });
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${(diff.inDays / 7).floor()}w ago';
  }

  void _deleteLink(String id) async {
    try {
      await ref.read(historyProvider.notifier).deleteLink(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Short URL deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header stats row
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: _headerStatCard(
                  'TOTAL CLICKS',
                  '${(historyState.longTotalClicks / 1000).toStringAsFixed(1)}k',
                  '+${historyState.weeklyGrowth.toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _headerStatCard(
                  'ACTIVE URLS',
                  '${historyState.activeUrls}',
                  null,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Link History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: historyState.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
              : historyState.links.isEmpty
                  ? const Center(
                      child: Text(
                        'No short URLs created yet.',
                        style: TextStyle(color: Color(0xFF9CA3AF)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: historyState.links.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, idx) {
                        final link = historyState.links[idx];
                        return _buildLinkTile(link);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _headerStatCard(String title, String val, String? growth) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                val,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (growth != null) ...[
                const SizedBox(width: 6),
                Text(
                  growth,
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(ShortLink link) {
    bool isBroken = link.status == LinkStatus.broken;
    bool isExpired = link.status == LinkStatus.expired;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBroken
              ? Colors.redAccent.withOpacity(0.3)
              : isExpired
                  ? Colors.orangeAccent.withOpacity(0.3)
                  : const Color(0xFF334155),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '/r/${link.shortCode}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'monospace',
                ),
              ),
              Row(
                children: [
                  Text(
                    _relativeTime(link.createdAt),
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                  _clickBadge(link),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            link.longUrl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          ),
          if (link.deepLinkCfg != null && link.deepLinkCfg!.enabled) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Color(0xFF6366F1), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Deferred Deep Link: ${link.deepLinkCfg!.destination}',
                    style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ],
          if (isBroken) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Link Broken (returns 4xx/5xx)',
                    style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ],
          if (isExpired) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_empty, color: Colors.orangeAccent, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Link Expired',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF334155), height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
               IconButton(
                icon: const Icon(Icons.copy, color: Color(0xFF9CA3AF), size: 18),
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: AppConfig.shortUrl(link.shortCode)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Short URL copied to clipboard!')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Color(0xFF9CA3AF), size: 18),
                onPressed: () {
                  Share.share('Check out this link: ${AppConfig.shortUrl(link.shortCode)}');
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                onPressed: () => _deleteLink(link.id),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _clickBadge(ShortLink link) {
    bool isTrending = link.clickCount > 1000;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTrending
            ? const Color(0xFF10B981).withOpacity(0.1)
            : const Color(0xFF334155),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${link.clickCount} clicks',
        style: TextStyle(
          color: isTrending ? const Color(0xFF10B981) : Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
