import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/providers/hygiene_providers.dart';
import 'package:kloudshop/services/api_service.dart';

class ComplianceView extends ConsumerStatefulWidget {
  const ComplianceView({super.key});

  @override
  ConsumerState<ComplianceView> createState() => _ComplianceViewState();
}

class _ComplianceViewState extends ConsumerState<ComplianceView> {
  final _emailController = TextEditingController();
  bool _isErasing = false;

  Future<void> _handleErasure() async {
    if (_emailController.text.isEmpty) return;

    setState(() => _isErasing = true);
    try {
      await ref.read(apiServiceProvider).triggerGdprErasure(_emailController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GDPR Erasure completed successfully.')),
        );
        _emailController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isErasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(systemStatusProvider);
    final healthAsync = ref.watch(schemaHealthProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Compliance & Hygiene')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: System Info
            Text('System Environment', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: statusAsync.when(
                    data: (status) => _InfoCard(
                      title: 'Version',
                      value: status.version,
                      subtitle: 'Build: ${status.buildHash}',
                      icon: LucideIcons.binary,
                    ),
                    loading: () => const _LoadingCard(),
                    error: (e, s) => _ErrorCard(error: e.toString()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: healthAsync.when(
                    data: (health) => _InfoCard(
                      title: 'Database Health',
                      value: health.status.toUpperCase(),
                      subtitle: 'Type: ${health.databaseType}',
                      icon: LucideIcons.database,
                      color: health.status == 'healthy' ? Colors.green : Colors.orange,
                    ),
                    loading: () => const _LoadingCard(),
                    error: (e, s) => _ErrorCard(error: e.toString()),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Section 2: GDPR Erasure
            Text('GDPR / Privacy Tools', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Right-to-Erasure: Provide an email address to anonymize all associated PII in orders and accounts.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Customer Email Address',
                      hintText: 'e.g. user@example.com',
                      prefixIcon: Icon(LucideIcons.mail, size: 18),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isErasing ? null : _handleErasure,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isErasing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Anonymize All PII'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(LucideIcons.alertTriangle, size: 14, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Warning: This action is irreversible. It will redact names, addresses, and emails.',
                          style: TextStyle(fontSize: 11, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color? color;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayColor = color ?? theme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: displayColor),
              const SizedBox(width: 12),
              Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor)),
            ],
          ),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: displayColor)),
          const SizedBox(height: 4),
          Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Text('Error: $error', style: const TextStyle(color: Colors.red, fontSize: 10)),
    );
  }
}
