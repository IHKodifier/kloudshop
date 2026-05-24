import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/providers/hygiene_providers.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

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
          const SnackBar(
            content: Text('GDPR Erasure completed successfully.'),
            backgroundColor: AppTheme.brandEmerald600,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _emailController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'), 
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Compliance & Hygiene', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: theme.dividerColor, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: System Info
            Row(
              children: [
                const Icon(LucideIcons.binary, size: 20, color: AppTheme.brandEmerald500),
                const SizedBox(width: 12),
                Text('System Environment', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: statusAsync.when(
                    data: (status) => _buildInfoCard(
                      title: 'System Version',
                      value: status.version,
                      subtitle: 'Build Hash: ${status.buildHash}',
                      icon: LucideIcons.binary,
                      color: AppTheme.brandEmerald500,
                      isDark: isDark,
                      theme: theme,
                    ),
                    loading: () => _buildLoadingCard(theme, isDark),
                    error: (e, s) => _buildErrorCard(e.toString(), theme, isDark),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: healthAsync.when(
                    data: (health) => _buildInfoCard(
                      title: 'Database Health',
                      value: health.status.toUpperCase(),
                      subtitle: 'Database Type: ${health.databaseType}',
                      icon: LucideIcons.database,
                      color: health.status == 'healthy' ? AppTheme.brandEmerald500 : const Color(0xFFF59E0B),
                      isDark: isDark,
                      theme: theme,
                    ),
                    loading: () => _buildLoadingCard(theme, isDark),
                    error: (e, s) => _buildErrorCard(e.toString(), theme, isDark),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 48),
            
            // Section 2: GDPR Erasure
            Row(
              children: [
                const Icon(LucideIcons.shieldAlert, size: 20, color: Colors.redAccent),
                const SizedBox(width: 12),
                Text('GDPR / Privacy Tools', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Right-to-Erasure: Provide a customer email address to redact and anonymize all associated personally identifiable information (PII) from orders and customer records.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 24),
            _buildGlassCard(
              title: 'Data Anonymization request (Redact PII)',
              icon: LucideIcons.trash2,
              color: Colors.redAccent,
              isDark: isDark,
              theme: theme,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Customer Email Address',
                    hintText: 'e.g. customer@example.com',
                    prefixIcon: const Icon(LucideIcons.mail, size: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: HoverScale(
                    child: ElevatedButton(
                      onPressed: _isErasing ? null : _handleErasure,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: _isErasing 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Anonymize All Customer PII', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.alertTriangle, size: 16, color: Color(0xFFF59E0B)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Warning: This action is permanent and completely irreversible. All orders and customer profiles matching this email will have their names, addresses, and email details redacted.',
                          style: TextStyle(fontSize: 12, color: Color(0xFFD97706), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isDark,
    required ThemeData theme,
    required List<Widget> children,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withOpacity(0.7) : Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
    required ThemeData theme,
  }) {
    return _buildGlassCard(
      title: title,
      icon: icon,
      color: color,
      isDark: isDark,
      theme: theme,
      children: [
        Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor)),
      ],
    );
  }

  Widget _buildLoadingCard(ThemeData theme, bool isDark) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: const Center(child: CircularProgressIndicator(color: AppTheme.brandEmerald500)),
    );
  }

  Widget _buildErrorCard(String error, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Text('Error loading status: $error', style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
    );
  }
}
