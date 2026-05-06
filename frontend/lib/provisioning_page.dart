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

  void _provision() async {
    if (widget.email == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      // Generate a simple tenant ID from the email
      final tenantId = widget.email!.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
      
      await ref.read(apiServiceProvider).provisionTenant(tenantId);
      
      // Auto-Sync Identity Loop
      int retryCount = 0;
      bool synced = false;
      
      while (retryCount < 5 && !synced) {
        // Wait a bit for Firebase claims to propagate
        await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
        
        // Force refresh the auth token to get the new custom claims
        await ref.read(authServiceProvider).getIdToken(forceRefresh: true);
        
        // Verify with backend
        final claims = await ref.read(apiServiceProvider).getMe(forceRefresh: true);
        if (claims?.tenantId != null) {
          synced = true;
        }
        retryCount++;
      }
      
      // Trigger reactive refresh of user claims to route to dashboard
      ref.read(forceRefreshClaimsProvider.notifier).toggle(true);
      ref.invalidate(userClaimsProvider);
      
      if (mounted) {
        if (synced) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store provisioned and identity synced! Redirecting...')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Store provisioned, but identity sync is taking longer than expected. Please wait a moment.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error provisioning store: $e'), 
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 10),
          ),
        );
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

    return Scaffold(
      body: Center(
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
                child: const Icon(
                  LucideIcons.userPlus,
                  size: 64,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Identity Verified',
                style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Welcome, ${widget.email}. Your account is authenticated via Google, but you are not yet linked to a KloudShop merchant tenant.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _provision,
                icon: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(LucideIcons.rocket),
                label: Text(_isLoading ? 'Provisioning...' : 'Provision My Store'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: _isLoading ? null : () => ref.read(authServiceProvider).signOut(),
                child: const Text('Sign out and try another account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
