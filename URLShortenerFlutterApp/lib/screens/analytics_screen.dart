import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/providers.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  final String? initialCode;

  const AnalyticsScreen({super.key, this.initialCode});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String? _selectedCode;
  bool _isLoading = false;
  Map<String, dynamic>? _analyticsData;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.initialCode;
    Future.microtask(() {
      _loadData();
    });
  }

  @override
  void didUpdateWidget(covariant AnalyticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCode != oldWidget.initialCode && widget.initialCode != null) {
      setState(() {
        _selectedCode = widget.initialCode;
      });
      _loadData();
    }
  }

  void _loadData() async {
    final history = ref.read(historyProvider);
    if (_selectedCode == null && history.links.isNotEmpty) {
      _selectedCode = history.links.first.shortCode;
    }

    if (_selectedCode == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await ref.read(apiServiceProvider).getLinkAnalytics(_selectedCode!);
      setState(() {
        _analyticsData = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load analytics: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyProvider);

    if (historyState.links.isEmpty) {
      return const Center(
        child: Text(
          'No links available for analytics.',
          style: TextStyle(color: Color(0xFF9CA3AF)),
        ),
      );
    }

    // List of short codes for the dropdown
    final shortCodes = historyState.links.map((e) => e.shortCode).toList();
    if (_selectedCode == null && shortCodes.isNotEmpty) {
      _selectedCode = shortCodes.first;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Code Selector Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCode,
                dropdownColor: const Color(0xFF1E293B),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                items: shortCodes.map((code) {
                  return DropdownMenuItem<String>(
                    value: code,
                    child: Text('/r/$code'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCode = val;
                    });
                    _loadData();
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (_isLoading)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
            )
          else if (_analyticsData == null)
            const Center(child: Text('Select a link to load analytics.', style: TextStyle(color: Color(0xFF9CA3AF))))
          else ...[
            // Total Clicks Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL CLICKS',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${_analyticsData!['totalClicks']}',
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '+${_analyticsData!['weeklyChange']}% this week',
                        style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Traffic trends chart card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TRAFFIC TRENDS (7D)',
                        style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                          SizedBox(width: 4),
                          Text('LIVE', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 180,
                    child: _buildTrafficChart(_analyticsData!['clicksByDay'] as List),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Device distribution card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DEVICE DISTRIBUTION',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _deviceProgressRow('Desktop', _getDevicePercent('DESKTOP'), Icons.desktop_mac),
                  const SizedBox(height: 16),
                  _deviceProgressRow('iOS', _getDevicePercent('IOS'), Icons.phone_iphone),
                  const SizedBox(height: 16),
                  _deviceProgressRow('Android', _getDevicePercent('ANDROID'), Icons.phone_android),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Protocol configuration card
            _buildProtocolConfigCard(_analyticsData!['deepLinkCfg']),
          ]
        ],
      ),
    );
  }

  double _getDevicePercent(String type) {
    final list = _analyticsData!['deviceDistribution'] as List;
    int total = 0;
    int count = 0;
    for (var item in list) {
      final c = (item['count'] as num? ?? 0).toInt();
      total += c;
      if (item['deviceType'] == type) {
        count = c;
      }
    }
    if (total == 0) return 0.0;
    return count / total;
  }

  Widget _deviceProgressRow(String name, double percent, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF9CA3AF), size: 16),
                const SizedBox(width: 8),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ],
            ),
            Text('${(percent * 100).toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            backgroundColor: const Color(0xFF0B0F19),
            color: const Color(0xFF6366F1),
            minHeight: 8,
          ),
        )
      ],
    );
  }

  Widget _buildProtocolConfigCard(Map<String, dynamic>? deepLinkCfg) {
    bool isEnabled = deepLinkCfg != null && (deepLinkCfg['enabled'] as bool? ?? false);
    String destination = deepLinkCfg != null ? (deepLinkCfg['destination'] as String? ?? 'Not configured') : 'Not configured';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PROTOCOL CONFIGURATION',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isEnabled ? const Color(0xFF6366F1).withOpacity(0.1) : const Color(0xFF334155),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.phonelink_setup,
                  color: isEnabled ? const Color(0xFF6366F1) : const Color(0xFF9CA3AF),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Deferred Deep Linking',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEnabled ? 'Route: $destination' : 'Route users to specific app content even after post-install launches.',
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isEnabled ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFF334155).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: isEnabled ? const Color(0xFF10B981) : const Color(0xFF9CA3AF), size: 8),
                    const SizedBox(width: 6),
                    Text(
                      isEnabled ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        color: isEnabled ? const Color(0xFF10B981) : const Color(0xFF9CA3AF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'CONFIGURE',
                style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTrafficChart(List clicksByDay) {
    if (clicksByDay.isEmpty) {
      return const Center(child: Text('No traffic data for chart.', style: TextStyle(color: Color(0xFF9CA3AF))));
    }

    final barGroups = clicksByDay.asMap().entries.map((entry) {
      final idx = entry.key;
      final val = entry.value;
      final count = (val['count'] as num? ?? 0).toDouble();

      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: count,
            color: const Color(0xFF6366F1),
            width: 14,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (val, meta) {
                final idx = val.toInt();
                if (idx < 0 || idx >= clicksByDay.length) return const SizedBox();
                final dayStr = clicksByDay[idx]['day'] as String; // e.g. "2026-07-03"
                final date = DateTime.parse(dayStr);
                final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Text(
                  weekdays[date.weekday - 1],
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
