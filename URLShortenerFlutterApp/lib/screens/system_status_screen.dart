import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../models/ddl_log.dart';
import '../models/system_status.dart';
import '../providers/providers.dart';
import 'package:go_india_tracker/go_india_tracker.dart';

class SystemStatusScreen extends ConsumerStatefulWidget {
  const SystemStatusScreen({super.key});

  @override
  ConsumerState<SystemStatusScreen> createState() => _SystemStatusScreenState();
}

class _SystemStatusScreenState extends ConsumerState<SystemStatusScreen> {
  SystemStatus? _status;
  List<DdlLog> _logs = [];
  String _fingerprint = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadFingerprint();
    _loadData();
    // Auto-refresh stats every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadFingerprint() async {
    final fp = await GoIndiaTracker.getDeviceFingerprint();
    setState(() {
      _fingerprint = fp;
    });
  }

  void _loadData() async {
    if (!mounted) return;
    try {
      final api = ref.read(apiServiceProvider);
      final statusMap = await api.getSystemStatus();
      final logsList = await api.getDdlLogs(page: 0, size: 20);

      if (mounted) {
        setState(() {
          _status = SystemStatus.fromJson(statusMap);
          _logs = logsList.map((e) => DdlLog.fromJson(e)).toList();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null) {
      return const SizedBox(
        height: 400,
        child: Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ACTIVE MONITORING',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cluster: US-EAST-1',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // 1. Spring Boot Backend card
          _statusCard(
            'Spring Boot Backend',
            _status!.version,
            'Latency: ${_status!.latencyMs}ms',
            'CONNECTED',
            const Color(0xFF10B981),
            Icons.swap_horiz,
          ),
          const SizedBox(height: 12),

          // 2. Redis Cache card
          _statusCard(
            'Redis Cache',
            '${_status!.hitRate.toStringAsFixed(1)}% Hit Rate',
            'Memory: ${_status!.memoryUsage}',
            'WARM',
            const Color(0xFF3B82F6),
            Icons.layers,
          ),
          const SizedBox(height: 12),

          // 3. Postgres DB card
          _statusCard(
            'Postgres DB',
            'Primary Instance',
            'Active Connections: ${_status!.activeConnections}',
            'ACTIVE',
            const Color(0xFF10B981),
            Icons.storage,
          ),
          const SizedBox(height: 20),

          // 4. Device Fingerprint card
          _buildFingerprintCard(),
          const SizedBox(height: 20),

          // 5. Link Verification checklist
          _buildLinkVerificationCard(),
          const SizedBox(height: 20),

          // 6. Debug Logs (DDL) panel
          _buildDebugLogsCard(),
        ],
      ),
    );
  }

  Widget _statusCard(
    String title,
    String val,
    String subtitle,
    String badgeText,
    Color badgeColor,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6366F1), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(color: badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFingerprintCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DEVICE FINGERPRINT',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                'Generated @ Live',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10),
              )
            ],
          ),
          const SizedBox(height: 20),
          // QR code
          if (_fingerprint.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: QrImageView(
                data: _fingerprint,
                version: QrVersions.auto,
                size: 110.0,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SHA256 DEVICE HASH',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 9, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0B0F19),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _fingerprint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildLinkVerificationCard() {
    final checks = _status!.verifications;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Link Verification',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _verificationRow(
            'iOS Universal Links',
            'apple-app-site-association',
            checks['ios'] ?? false,
          ),
          const SizedBox(height: 12),
          _verificationRow(
            'Android App Links',
            'assetlinks.json',
            checks['android'] ?? false,
          ),
          const SizedBox(height: 12),
          _verificationRow(
            'Custom URI Scheme',
            'urlshortener://',
            checks['customScheme'] ?? false,
          ),
        ],
      ),
    );
  }

  Widget _verificationRow(String title, String details, bool verified) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(details, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: verified ? const Color(0xFF10B981).withOpacity(0.2) : Colors.redAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            verified ? 'VERIFIED' : 'FAILED',
            style: TextStyle(
              color: verified ? const Color(0xFF10B981) : Colors.redAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDebugLogsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Debug Logs (DDL)',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _logs.clear();
                  });
                },
                child: const Text('CLEAR', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 220,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0F19),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _logs.isEmpty
                ? const Center(child: Text('No debug logs recorded.', style: TextStyle(color: Color(0xFF475569), fontSize: 12)))
                : ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, idx) {
                      final logItem = _logs[idx];
                      return _buildLogEntry(logItem);
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildLogEntry(DdlLog logItem) {
    Color tagColor = Colors.grey;
    if (logItem.tag == 'DDL_RESOLVER') {
      tagColor = const Color(0xFF3B82F6);
    } else if (logItem.tag == 'FINGERPRINT') {
      tagColor = const Color(0xFF10B981);
    } else if (logItem.tag == 'SYSTEM') {
      tagColor = const Color(0xFFF59E0B);
    }

    final timeStr = DateFormat('HH:mm:ss').format(logItem.createdAt.toLocal());
    bool isWarning = logItem.level == 'WARN';
    bool isError = logItem.level == 'ERROR';
    Color msgColor = isWarning
        ? Colors.orangeAccent
        : isError
            ? Colors.redAccent
            : const Color(0xFF9CA3AF);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '[$timeStr] ',
              style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontFamily: 'monospace'),
            ),
            TextSpan(
              text: '${logItem.tag}: ',
              style: TextStyle(color: tagColor, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
            ),
            TextSpan(
              text: logItem.message,
              style: TextStyle(color: msgColor, fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
