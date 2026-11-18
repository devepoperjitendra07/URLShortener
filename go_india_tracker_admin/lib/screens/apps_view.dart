import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_model.dart';
import '../providers/providers.dart';

class AppsView extends ConsumerStatefulWidget {
  const AppsView({super.key});

  @override
  ConsumerState<AppsView> createState() => _AppsViewState();
}

class _AppsViewState extends ConsumerState<AppsView> {
  void _openRegisterDialog({AppModel? app}) {
    showDialog(
      context: context,
      builder: (context) => _RegisterAppDialog(app: app),
    );
  }

  void _confirmDelete(AppModel app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Application', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete ${app.name}? This will revoke all SDK keys and break associated deep links.',
          style: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(appsProvider.notifier).deleteApp(app.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  void _confirmRegenerate(AppModel app) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Rotate SDK Key', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Rotating the SDK key will immediately invalidate the active key. Old app builds using it will no longer be able to resolve deep links.',
          style: TextStyle(color: Color(0xFF9CA3AF)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: Color(0xFF9CA3AF))),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(appsProvider.notifier).regenerateKey(app.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('ROTATE KEY'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(appsProvider);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'App Directory',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage deep linking configurations and registered mobile applications.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _openRegisterDialog,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Register New App'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        Expanded(
          child: apps.isEmpty
              ? _emptyState()
              : GridView.builder(
                  itemCount: apps.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isDesktop ? 3 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isDesktop ? 1.3 : 1.2,
                  ),
                  itemBuilder: (context, idx) {
                    final app = apps[idx];
                    return _buildAppCard(app);
                  },
                ),
        )
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apps_outage_outlined, size: 64, color: const Color(0xFF475569)),
          const SizedBox(height: 16),
          const Text(
            'No applications registered yet',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Register your first Android or iOS app to configure SDK links.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openRegisterDialog,
            icon: const Icon(Icons.add),
            label: const Text('Register App'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppCard(AppModel app) {
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
                  Icon(
                    app.androidPackageName != null && app.iosBundleId != null ? Icons.devices 
                        : (app.iosBundleId != null ? Icons.phone_iphone : Icons.android),
                    color: const Color(0xFF6366F1),
                    size: 24,
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
              PopupMenuButton<String>(
                color: const Color(0xFF1E293B),
                icon: const Icon(Icons.more_vert, color: Color(0xFF9CA3AF)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _openRegisterDialog(app: app);
                  } else if (val == 'regenerate') {
                    _confirmRegenerate(app);
                  } else if (val == 'delete') {
                    _confirmDelete(app);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Config', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'regenerate',
                    child: Text('Regenerate Key', style: TextStyle(color: Colors.white)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete App', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (app.androidPackageName != null) ...[
            Text(app.androidPackageName!, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          ],
          if (app.iosBundleId != null) ...[
            Text(app.iosBundleId!, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
          ],
          const SizedBox(height: 12),
          const Text(
            'SDK KEY',
            style: TextStyle(color: Color(0xFF475569), fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (app.androidPackageName != null) 
                const Text('Android', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
              if (app.iosBundleId != null) 
                const Text('iOS', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
              const Text(
                'Status: Active',
                style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegisterAppDialog extends ConsumerStatefulWidget {
  final AppModel? app;
  const _RegisterAppDialog({this.app});

  @override
  ConsumerState<_RegisterAppDialog> createState() => _RegisterAppDialogState();
}

class _RegisterAppDialogState extends ConsumerState<_RegisterAppDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _androidPackageController;
  late final TextEditingController _fingerprintController;
  late final TextEditingController _playStoreUrlController;
  late final TextEditingController _iosBundleIdController;
  late final TextEditingController _teamIdController;
  late final TextEditingController _appStoreUrlController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.app?.name ?? '');
    _androidPackageController = TextEditingController(text: widget.app?.androidPackageName ?? '');
    _fingerprintController = TextEditingController(text: widget.app?.sha256Fingerprint ?? '');
    _playStoreUrlController = TextEditingController(text: widget.app?.playStoreUrl ?? '');
    _iosBundleIdController = TextEditingController(text: widget.app?.iosBundleId ?? '');
    _teamIdController = TextEditingController(text: widget.app?.appleTeamId ?? '');
    _appStoreUrlController = TextEditingController(text: widget.app?.appStoreUrl ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _androidPackageController.dispose();
    _fingerprintController.dispose();
    _playStoreUrlController.dispose();
    _iosBundleIdController.dispose();
    _teamIdController.dispose();
    _appStoreUrlController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.app == null) {
        await ref.read(appsProvider.notifier).registerApp(
              name: _nameController.text.trim(),
              androidPackageName: _androidPackageController.text.trim(),
              sha256Fingerprint: _fingerprintController.text.trim(),
              playStoreUrl: _playStoreUrlController.text.trim(),
              iosBundleId: _iosBundleIdController.text.trim(),
              appleTeamId: _teamIdController.text.trim(),
              appStoreUrl: _appStoreUrlController.text.trim(),
            );
      } else {
        await ref.read(appsProvider.notifier).updateApp(
              id: widget.app!.id,
              name: _nameController.text.trim(),
              androidPackageName: _androidPackageController.text.trim(),
              sha256Fingerprint: _fingerprintController.text.trim(),
              playStoreUrl: _playStoreUrlController.text.trim(),
              iosBundleId: _iosBundleIdController.text.trim(),
              appleTeamId: _teamIdController.text.trim(),
              appStoreUrl: _appStoreUrlController.text.trim(),
            );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.app == null ? 'Application registered successfully!' : 'Application updated successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(28.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.app == null ? 'Register Application' : 'Edit Application',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('APP NAME', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('e.g. StudyIQ App'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'App name is required' : null,
                ),
                const SizedBox(height: 24),
                
                // Android Section
                const Text('ANDROID CONFIGURATION', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
                const Divider(color: Color(0xFF334155), height: 16),
                
                const Text('ANDROID PACKAGE NAME', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _androidPackageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('e.g. com.studyiq.android'),
                ),
                const SizedBox(height: 16),
                
                const Text('SHA-256 FINGERPRINTS (COMMA SEPARATED FOR MULTIPLE)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _fingerprintController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('e.g. 14:6D:E9:..., AA:BB:CC:...'),
                ),
                const SizedBox(height: 16),
                
                const Text('PLAY STORE URL (FALLBACK)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _playStoreUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('https://play.google.com/store/apps/details?id=...'),
                ),
                
                const SizedBox(height: 32),
                
                // iOS Section
                const Text('IOS CONFIGURATION', style: TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold)),
                const Divider(color: Color(0xFF334155), height: 16),
                
                const Text('IOS BUNDLE ID', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _iosBundleIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('e.g. com.studyiq.ios'),
                ),
                const SizedBox(height: 16),
                
                const Text('APPLE TEAM ID (REQUIRED FOR UNIVERSAL LINKS)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _teamIdController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('e.g. ABCDE12345'),
                ),
                const SizedBox(height: 16),
                
                const Text('APP STORE URL (FALLBACK)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _appStoreUrlController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('https://apps.apple.com/app/id...'),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(widget.app == null ? 'SUBMIT' : 'SAVE CHANGES', style: const TextStyle(fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF475569)),
      filled: true,
      fillColor: const Color(0xFF0B0F19),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF334155)),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF6366F1)),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
