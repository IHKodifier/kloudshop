import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/services/auth_service.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/providers/auth_providers.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';

class ProvisioningPage extends ConsumerStatefulWidget {
  final String? email;

  const ProvisioningPage({super.key, this.email});

  @override
  ConsumerState<ProvisioningPage> createState() => _ProvisioningPageState();
}

class _ProvisioningPageState extends ConsumerState<ProvisioningPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isCheckingAvailability = false;
  bool? _isAvailable;
  final TextEditingController _tenantIdController = TextEditingController();
  String _errorMessage = '';
  Timer? _debounceTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.email != null) {
      final suggestion = widget.email!
          .split('@')[0]
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
          .toLowerCase();
      _tenantIdController.text = suggestion;
      _checkAvailability(suggestion);
    }
  }

  @override
  void dispose() {
    _tenantIdController.dispose();
    _debounceTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _onIdChanged(String value) {
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
      final available =
          await ref.read(apiServiceProvider).checkTenantAvailability(tenantId);
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
    final tenantId = rawId
        .replaceAll(RegExp(r'[^a-z0-9]'), '-')
        .replaceAll(RegExp(r'-+'), '-');

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
          final claims =
              await ref.read(apiServiceProvider).getMe(forceRefresh: true);
          if (claims?.tenantId != null) {
            synced = true;
          }
        } catch (e) {
          debugPrint('Sync retry $retryCount failed: $e');
        }
        retryCount++;
      }

      ref.read(forceRefreshClaimsProvider.notifier).toggle(true);
      ref.invalidate(userClaimsProvider);

      if (mounted) {
        if (synced) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Store provisioned! Redirecting...'),
              backgroundColor: AppTheme.brandEmerald600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
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
    final isDark = theme.brightness == Brightness.dark;
    final displayId =
        _tenantIdController.text.trim().toLowerCase().replaceAll(' ', '-');

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF020617),
                    const Color(0xFF0F172A),
                    const Color(0xFF134E4A).withValues(alpha: 0.3),
                  ]
                : [
                    AppTheme.brandEmerald50,
                    AppTheme.brandTeal50,
                    Colors.white,
                  ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.brandEmerald500.withValues(alpha: 0.15)
                            : AppTheme.brandEmerald500.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandEmerald500.withValues(alpha: 0.08),
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated Icon
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  colors: [
                                    AppTheme.brandEmerald500
                                        .withValues(alpha: 0.3 * _pulseAnimation.value),
                                    AppTheme.brandEmerald500
                                        .withValues(alpha: 0.05),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.brandEmerald500
                                      .withValues(alpha: 0.4 * _pulseAnimation.value),
                                  width: 1.5,
                                ),
                              ),
                              child: const Icon(
                                LucideIcons.rocket,
                                size: 42,
                                color: AppTheme.brandEmerald500,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Launch Your Store',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  AppTheme.brandTeal900,
                                  AppTheme.brandEmerald500,
                                ],
                              ).createShader(
                                const Rect.fromLTWH(0, 0, 300, 60),
                              ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your Store ID will be your public identity on KloudShop. Choose wisely!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Input field
                        TextField(
                          controller: _tenantIdController,
                          enabled: !_isLoading,
                          style: theme.textTheme.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Store Handle / ID',
                            hintText: 'e.g. enigma-stores',
                            prefixIcon: Icon(
                              LucideIcons.link,
                              color: AppTheme.brandEmerald500,
                              size: 20,
                            ),
                            suffixIcon: _isCheckingAvailability
                                ? Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.brandEmerald500,
                                      ),
                                    ),
                                  )
                                : _isAvailable == true
                                    ? const Icon(LucideIcons.checkCircle2,
                                        color: AppTheme.brandEmerald500)
                                    : _isAvailable == false
                                        ? Icon(LucideIcons.xCircle,
                                            color: theme.colorScheme.error)
                                        : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: theme.colorScheme.outline),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                  color: theme.colorScheme.outline),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppTheme.brandEmerald500, width: 2),
                            ),
                            errorText: _errorMessage.isEmpty ? null : _errorMessage,
                            helperText:
                                _isAvailable == true ? '✓ ID is available!' : null,
                            helperStyle: const TextStyle(
                                color: AppTheme.brandEmerald500,
                                fontWeight: FontWeight.w500),
                            filled: true,
                            fillColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : AppTheme.brandEmerald50.withValues(alpha: 0.5),
                          ),
                          onChanged: _onIdChanged,
                        ),

                        const SizedBox(height: 16),

                        // URL Preview Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.brandEmerald500.withValues(alpha: 0.06),
                                AppTheme.brandTeal500.withValues(alpha: 0.04),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.brandEmerald500.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandEmerald500
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(LucideIcons.globe,
                                    size: 14, color: AppTheme.brandEmerald500),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant),
                                    children: [
                                      const TextSpan(text: 'kloudshop.com/'),
                                      TextSpan(
                                        text: displayId.isEmpty
                                            ? 'your-handle'
                                            : displayId,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.brandEmerald500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 48),

                        // CTA Button
                        HoverScale(
                          child: SizedBox(
                            width: double.infinity,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: _isAvailable == true && !_isLoading
                                    ? const LinearGradient(
                                        colors: [
                                          AppTheme.brandEmerald500,
                                          AppTheme.brandEmerald600,
                                        ],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: _isAvailable == true && !_isLoading
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.brandEmerald500
                                              .withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: (_isLoading || _isAvailable != true)
                                    ? null
                                    : _provision,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white))
                                    : const Icon(LucideIcons.rocket,
                                        color: Colors.white),
                                label: Text(
                                  _isLoading
                                      ? 'Launching Store...'
                                      : 'Provision My Store',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 20),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () =>
                                  ref.read(authServiceProvider).signOut(),
                          child: Text(
                            'Cancel and sign out',
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
