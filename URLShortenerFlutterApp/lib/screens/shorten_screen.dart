import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import 'package:share_plus/share_plus.dart';
import '../models/short_link.dart';
import '../providers/providers.dart';

class ShortenScreen extends ConsumerStatefulWidget {
  final Function(String code) onNavigateToStats;

  const ShortenScreen({super.key, required this.onNavigateToStats});

  @override
  ConsumerState<ShortenScreen> createState() => _ShortenScreenState();
}

class _ShortenScreenState extends ConsumerState<ShortenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _slugController = TextEditingController();
  final _ddlDestController = TextEditingController();

  DateTime? _expiryDate;
  bool _enableDdl = false;
  bool _isLoading = false;
  ShortLink? _result;

  @override
  void dispose() {
    _urlController.dispose();
    _slugController.dispose();
    _ddlDestController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _result = null;
    });

    Map<String, dynamic>? ddlCfg;
    if (_enableDdl) {
      ddlCfg = {
        'enabled': true,
        'destination': _ddlDestController.text.trim(),
        'params': <String, String>{},
      };
    }

    try {
      final shortLink = await ref.read(historyProvider.notifier).shorten(
            longUrl: _urlController.text.trim(),
            customSlug: _slugController.text.trim().isEmpty ? null : _slugController.text.trim(),
            expiryDate: _expiryDate,
            deepLinkCfg: ddlCfg,
          );
      setState(() {
        _result = shortLink;
      });
      _urlController.clear();
      _slugController.clear();
      _ddlDestController.clear();
      _expiryDate = null;
      _enableDdl = false;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Color(0xFF1E293B),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Modern Link Infrastructure',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Shorten, track, and manage your deep links with production-grade reliability.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 28),
            // Form Card
            Container(
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
                    'TARGET DESTINATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('https://your-long-product-link.com', Icons.link),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Destination URL is required';
                      if (!v.startsWith('http://') && !v.startsWith('https://')) {
                        return 'URL must start with http:// or https://';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'CUSTOM SLUG (OPTIONAL)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _slugController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('e.g. dev-dash-2024', Icons.edit),
                  ),
                  const SizedBox(height: 20),
                  // Expiry date picker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'LINK EXPIRATION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _expiryDate == null
                                ? 'Never Expires'
                                : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _pickExpiryDate,
                        icon: const Icon(Icons.calendar_today, size: 16, color: Color(0xFF6366F1)),
                        label: const Text('Set Expiry', style: TextStyle(color: Color(0xFF6366F1))),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Color(0xFF334155)),
                  const SizedBox(height: 10),
                  // Deferred Deep Linking toggle
                  SwitchListTile(
                    title: const Text(
                      'Deferred Deep Linking',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Route users to specific app content even after post-install launches.',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                    value: _enableDdl,
                    activeColor: const Color(0xFF6366F1),
                    onChanged: (val) {
                      setState(() {
                        _enableDdl = val;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_enableDdl) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'APP SCHEME ROUTE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _ddlDestController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('e.g. app://internal/store?id=442', Icons.phone_android),
                      validator: (v) {
                        if (_enableDdl && (v == null || v.isEmpty)) {
                          return 'App deep link target cannot be empty';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.flash_on),
                    label: const Text('Shorten', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Result Card
            if (_result != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.05),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                                  SizedBox(width: 6),
                                  Text(
                                    'LIVE_DEPLOYED',
                                    style: TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_result!.deepLinkCfg != null && _result!.deepLinkCfg!.enabled) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.bolt, color: Color(0xFF6366F1), size: 10),
                                    SizedBox(width: 4),
                                    Text(
                                      'DEFERRED DEEPLINK',
                                      style: TextStyle(
                                        color: Color(0xFF6366F1),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const Text(
                          'CREATED 2m AGO',
                          style: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Short URL Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B0F19),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              AppConfig.shortUrl(_result!.shortCode),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, color: Color(0xFF9CA3AF), size: 20),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: AppConfig.shortUrl(_result!.shortCode)));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Short URL copied to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result!.longUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Share.share('Check out this link: ${AppConfig.shortUrl(_result!.shortCode)}');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF334155)),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.share, size: 18),
                            label: const Text('SHARE'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              widget.onNavigateToStats(_result!.shortCode);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF334155)),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.bar_chart, size: 18),
                            label: const Text('STATS'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Bottom stats cards
            Row(
              children: [
                Expanded(
                  child: _infoCard(
                    'TOTAL_REDIRECTS',
                    '12.4k',
                    '+14% this week',
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _infoCard(
                    'UPTIME_AVAILABILITY',
                    '99.99%',
                    'Cluster Stable',
                    Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String val, String subtitle, IconData icon) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, color: const Color(0xFF6366F1), size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            val,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF475569)),
      prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
      filled: true,
      fillColor: const Color(0xFF0B0F19),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF334155)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF6366F1)),
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
