import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/deep_link_model.dart';
import '../providers/providers.dart';

class LinksView extends ConsumerStatefulWidget {
  const LinksView({super.key});

  @override
  ConsumerState<LinksView> createState() => _LinksViewState();
}

class _LinksViewState extends ConsumerState<LinksView> {
  void _openCreateLinkDialog({DeepLinkModel? link}) {
    showDialog(
      context: context,
      builder: (context) => _CreateLinkDialog(link: link),
    );
  }

  @override
  Widget build(BuildContext context) {
    final links = ref.watch(linksProvider);
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
                  'Deep Link Configurations',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Configure routing parameters for seamless app-to-app handoffs.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _openCreateLinkDialog(),
              icon: const Icon(Icons.bolt, size: 16),
              label: const Text('Configure Deep Link'),
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
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: links.isEmpty
                ? _emptyState()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Table Header
                      Container(
                        color: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          children: const [
                            Expanded(child: Text('LINK (SLUG)', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(child: Text('APP', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(child: Text('CLICKS', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(child: Text('DESTINATION URI', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 12))),
                            Expanded(child: Text('STATUS', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 12))),
                            Text('ACTIONS', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                      // Table Content
                      Expanded(
                        child: ListView.separated(
                          itemCount: links.length,
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
                                    child: Text(
                                      link.destinationUri,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                                    ),
                                  ),
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
                                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF9CA3AF), size: 18),
                                        onPressed: () => _openCreateLinkDialog(link: link),
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
                      ),
                    ],
                  ),
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
          Icon(Icons.link_off, size: 64, color: const Color(0xFF475569)),
          const SizedBox(height: 16),
          const Text(
            'No deep link mappings found',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first deep link to route users inside your mobile application.',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openCreateLinkDialog(),
            icon: const Icon(Icons.add),
            label: const Text('Create Deep Link'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
          ),
        ],
      ),
    );
  }
}

class _CreateLinkDialog extends ConsumerStatefulWidget {
  final DeepLinkModel? link;
  const _CreateLinkDialog({this.link});

  @override
  ConsumerState<_CreateLinkDialog> createState() => _CreateLinkDialogState();
}

class _CreateLinkDialogState extends ConsumerState<_CreateLinkDialog> {
  final _formKey = GlobalKey<FormState>();
  final _slugController = TextEditingController();
  final _destController = TextEditingController();
  final _nameController = TextEditingController();

  String? _selectedAppId;
  DateTime? _expiryDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.link != null) {
      _nameController.text = widget.link!.name;
      _slugController.text = widget.link!.shortCode;
      _destController.text = widget.link!.destinationUri;
      _selectedAppId = widget.link!.targetAppId;
      _expiryDate = widget.link!.expiryDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _destController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAppId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target application')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.link == null) {
        await ref.read(linksProvider.notifier).createLink(
              appId: _selectedAppId!,
              name: _nameController.text.trim(),
              customSlug: _slugController.text.trim().isEmpty ? null : _slugController.text.trim(),
              destinationUri: _destController.text.trim(),
              expiryDate: _expiryDate,
            );
      } else {
        await ref.read(linksProvider.notifier).updateLink(
              linkId: widget.link!.id,
              appId: _selectedAppId!,
              name: _nameController.text.trim(),
              customSlug: _slugController.text.trim().isEmpty ? null : _slugController.text.trim(),
              destinationUri: _destController.text.trim(),
              expiryDate: _expiryDate,
            );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.link == null ? 'Deep Link deployed successfully!' : 'Deep Link updated successfully!')),
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
    final apps = ref.watch(appsProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 550,
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
                      widget.link == null ? 'Configure Deep Link' : 'Edit Deep Link',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Phase 1: Define core routing parameters for seamless app-to-app handoffs.',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
                const SizedBox(height: 24),
                const Text('TARGET APP ENTITY', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedAppId,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Select target app'),
                  onChanged: (val) {
                    setState(() {
                      _selectedAppId = val;
                    });
                  },
                  items: apps.map((app) {
                    return DropdownMenuItem(
                      value: app.id,
                      child: Text('${app.name} (${app.androidPackageName ?? app.iosBundleId ?? ''})'),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('LINK NAME', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('e.g. Summer Promo 2024'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Link name is required' : null,
                ),
                const SizedBox(height: 16),
                const Text('CUSTOM SLUG (OPTIONAL)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _slugController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('e.g. summer-sale-24'),
                ),
                const SizedBox(height: 16),
                const Text('IN-APP DESTINATION (REQUIRED)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _destController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('e.g. app://store/product?id=442'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'In-app destination is required';
                    if (!v.contains('://')) return 'Destination must be a scheme path (e.g. app://)';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('EXPIRY DATE (OPTIONAL)', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          _expiryDate == null
                              ? 'Never Expires'
                              : '${_expiryDate!.month}/${_expiryDate!.day}/${_expiryDate!.year}',
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            _expiryDate = picked;
                          });
                        }
                      },
                      child: const Text('Select Date', style: TextStyle(color: Color(0xFF6366F1))),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF334155)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      child: const Text('Discard'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _submit,
                      icon: _isLoading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.rocket_launch, size: 16),
                      label: const Text('Deploy Link'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                    ),
                  ],
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
