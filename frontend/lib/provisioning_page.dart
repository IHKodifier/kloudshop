import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/services/auth_service.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/providers/auth_providers.dart';

class ProvisioningPage extends ConsumerStatefulWidget {
  final String? email;

  const ProvisioningPage({super.key, this.email});

  @override
  ConsumerState<ProvisioningPage> createState() => _ProvisioningPageState();
}

class _ProvisioningPageState extends ConsumerState<ProvisioningPage> {
  bool _isLoading = false;
  bool _isCheckingAvailability = false;
  bool? _isAvailable;
  final TextEditingController _tenantIdController = TextEditingController();
  String _errorMessage = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      final suggestion = widget.email!.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      _tenantIdController.text = suggestion;
      _checkAvailability(suggestion);
    }
  }

  @override
  void dispose() {
    _tenantIdController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onIdChanged(String value) {
    // Live slugification: replace spaces with dashes instantly
    final slugified = value.toLowerCase().replaceAll(' ', '-');
    if (slugified != value) {
      _tenantIdController.value = TextEditingValue(
        text: slugified,
        selection: TextSelection.collapsed(offset: slugified.length),
      );
    }

    setState(() {
      _isAvailable = null;
      _errorMessage = '';
    });
    
    _debounceTimer?.cancel();
    if (slugified.trim().length >= 3) {
      _debounceTimer = Timer(const Duration(milliseconds: 500), () {
        _checkAvailability(slugified.trim());
      });
    }
  }

  Future<void> _checkAvailability(String tenantId) async {
    if (tenantId.isEmpty) return;
    
    setState(() => _isCheckingAvailability = true);
    try {
      final available = await ref.read(apiServiceProvider).checkTenantAvailability(tenantId);
      if (mounted) {
        setState(() {
          _isAvailable = available;
          if (!available) {
            _errorMessage = 'This ID is already taken. Try another one!';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingAvailability = false);
      }
    }
  }

  void _provision() async {
    final rawId = _tenantIdController.text.trim().toLowerCase();
    final tenantId = rawId.replaceAll(RegExp(r'[^a-z0-9]'), '-').replaceAll(RegExp(r'-+'), '-');
    
    if (tenantId.isEmpty) {
      setState(() => _errorMessage = 'Please enter a Store ID');
      return;
    }

    if (_isAvailable == false) {
      setState(() => _errorMessage = 'Please choose an available ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      await ref.read(apiServiceProvider).provisionTenant(tenantId);
      
      int retryCount = 0;
      bool synced = false;
      
      while (retryCount < 10 && !synced) {
        await Future.delayed(const Duration(milliseconds: 800));
        try {
          await ref.read(authServiceProvider).getIdToken(forceRefresh: true);
          final claims = await ref.read(apiServiceProvider).getMe(forceRefresh: true);
          if (claims?.tenantId != null) {
            synced = true;
          }
        } catch (e) {
          // If we hit a transient 401 (like "token used too early"), we just wait and retry
          debugPrint('Sync retry $retryCount failed: $e');
        }
        retryCount++;
      }
      
      ref.read(forceRefreshClaimsProvider.notifier).toggle(true);
      ref.invalidate(userClaimsProvider);
      
      if (mounted) {
        if (synced) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store provisioned! Redirecting...')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Provisioning failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayId = _tenantIdController.text.trim().toLowerCase().replaceAll(' ', '-');

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.rocket, size: 64, color: Colors.orange),
                ),
                const SizedBox(height: 32),
                Text(
                  'Launch Your Store',
                  style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Store ID will be your public identity on KloudShop. Choose wisely!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 40),
                
                TextField(
                  controller: _tenantIdController,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    labelText: 'Store Handle / ID',
                    hintText: 'e.g. enigma-stores',
                    prefixIcon: const Icon(LucideIcons.link),
                    suffixIcon: _isCheckingAvailability
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _isAvailable == true
                        ? const Icon(LucideIcons.checkCircle2, color: Colors.green)
                        : _isAvailable == false
                          ? const Icon(LucideIcons.xCircle, color: Colors.red)
                          : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    errorText: _errorMessage.isEmpty ? null : _errorMessage,
                    helperText: _isAvailable == true ? 'ID is available!' : null,
                    helperStyle: const TextStyle(color: Colors.green),
                  ),
                  onChanged: _onIdChanged,
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.globe, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                            children: [
                              const TextSpan(text: 'Public URL: '),
                              const TextSpan(text: 'kloudshop.com/'),
                              TextSpan(
                                text: displayId.isEmpty ? 'your-handle' : displayId,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_isLoading || _isAvailable != true) ? null : _provision,
                    icon: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(LucideIcons.rocket),
                    label: Text(_isLoading ? 'Launching Store...' : 'Provision My Store'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      backgroundColor: _isAvailable == true ? Colors.blue : null,
                      foregroundColor: _isAvailable == true ? Colors.white : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _isLoading ? null : () => ref.read(authServiceProvider).signOut(),
                  child: const Text('Cancel and sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
