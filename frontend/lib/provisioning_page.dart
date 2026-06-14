import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/services/auth_service.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:kloudshop/widgets/lottie_toggle.dart';
import 'package:kloudshop/models/gcp_region.dart';
import 'package:kloudshop/providers/provisioning_provider.dart';
import 'package:kloudshop/widgets/semantic_text_form_field.dart';


class ProvisioningPage extends ConsumerStatefulWidget {
  final String? email;

  const ProvisioningPage({super.key, this.email});

  @override
  ConsumerState<ProvisioningPage> createState() => _ProvisioningPageState();
}

class _ProvisioningPageState extends ConsumerState<ProvisioningPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _tenantIdController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isFocused = false;
  bool _isRedundancyExpanded = true; // Multi-Region redundancy panel state

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tenantProvisioningProvider.notifier).reset();
      
      if (widget.email != null) {
        final suggestion = widget.email!
            .split('@')[0]
            .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
            .toLowerCase();
        _tenantIdController.text = suggestion;
        ref.read(tenantProvisioningProvider.notifier).updateTenantId(suggestion);
      }
    });
  }

  @override
  void dispose() {
    _tenantIdController.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onIdChanged(String value) {
    ref.read(tenantProvisioningProvider.notifier).updateTenantId(value);
  }

  void _provision() {
    ref.read(tenantProvisioningProvider.notifier).provisionStore();
  }

  void _signOut() {
    ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provState = ref.watch(tenantProvisioningProvider);
    final width = MediaQuery.of(context).size.width;

    // Determine layout columns based on width
    final isDesktop = width > 850;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAF6),
      body: isDesktop
          ? Row(
              children: [
                // Left Panel - Wizard Progress Sidebar (Fixed width)
                _buildSidebar(context, provState, isDark, true),
                const VerticalDivider(width: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                // Right Panel - Wizard Core View Area
                Expanded(
                  child: Container(
                    height: double.infinity,
                    color: isDark ? const Color(0xFF030712) : Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: _buildStepContent(context, provState, isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                // Top Panel - Compact Mobile Header
                _buildSidebar(context, provState, isDark, false),
                const Divider(height: 1, thickness: 1),
                // Bottom Scroll Container
                Expanded(
                  child: Container(
                    color: isDark ? const Color(0xFF030712) : Colors.white,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: _buildStepContent(context, provState, isDark),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // Left Sidebar / Top Horizontal Stepper
  Widget _buildSidebar(BuildContext context, ProvisioningState state, bool isDark, bool isSidebar) {
    // Compute progress % based on step
    double progressPercent = 0.20;
    String progressText = "20% Complete";
    String statusLabel = "Awaiting Configuration";

    switch (state.currentStep) {
      case ProvisioningStep.storeSetup:
        progressPercent = 0.20;
        progressText = "20% Complete";
        statusLabel = state.availabilityStatus == AvailabilityStatus.checking 
            ? "Checking Availability" 
            : "Awaiting Configuration";
        break;
      case ProvisioningStep.infrastructure:
        progressPercent = 0.65;
        progressText = "65% Complete";
        statusLabel = "Awaiting Infrastructure Select";
        break;
      case ProvisioningStep.loading:
        progressPercent = 0.85;
        progressText = "85% Complete";
        statusLabel = "Provisioning Environment...";
        break;
      case ProvisioningStep.success:
        progressPercent = 1.0;
        progressText = "100% Complete";
        statusLabel = "Ready";
        break;
      case ProvisioningStep.error:
        progressPercent = 0.65;
        progressText = "65% Complete";
        statusLabel = "Setup Failed";
        break;
    }

    // Sidebar View
    if (isSidebar) {
      return Container(
        width: 250,
        height: double.infinity,
        color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF3F4F1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo header
            Row(
              children: [
                const Icon(LucideIcons.rocket, color: AppTheme.brandEmerald500, size: 24),
                const SizedBox(width: 10),
                Text(
                  'KloudShop',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.neutral900,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Progress Header
            Text(
              'SETUP PROGRESS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFF64748B) : AppTheme.neutral500,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              progressText,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.neutral900,
              ),
            ),
            const SizedBox(height: 10),
            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercent,
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                color: AppTheme.brandEmerald500,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 48),

            // Steps Checklist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepTile(
                    'Store Setup',
                    LucideIcons.store,
                    isActive: state.currentStep == ProvisioningStep.storeSetup,
                    isCompleted: state.currentStep != ProvisioningStep.storeSetup && state.tenantId.isNotEmpty,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildStepTile(
                    'Inventory',
                    LucideIcons.boxes,
                    isActive: false,
                    isCompleted: true, // Mocked done
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildStepTile(
                    'Payments',
                    LucideIcons.creditCard,
                    isActive: false,
                    isCompleted: true, // Mocked done
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildStepTile(
                    'Infrastructure',
                    LucideIcons.database,
                    isActive: state.currentStep == ProvisioningStep.infrastructure ||
                              state.currentStep == ProvisioningStep.loading ||
                              state.currentStep == ProvisioningStep.error,
                    isCompleted: state.currentStep == ProvisioningStep.success,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildStepTile(
                    'Review',
                    LucideIcons.clipboardCheck,
                    isActive: false,
                    isCompleted: state.currentStep == ProvisioningStep.success,
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // Bottom status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE7E9E5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFD8DBD7),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PROVISIONING_STATUS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF94A3B8) : AppTheme.neutral500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.currentStep == ProvisioningStep.error 
                              ? Colors.redAccent 
                              : (state.currentStep == ProvisioningStep.success 
                                  ? AppTheme.brandEmerald500 
                                  : (state.currentStep == ProvisioningStep.loading 
                                      ? Colors.amber 
                                      : AppTheme.brandEmerald500)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppTheme.neutral900,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile/Top Stepper View
    return Container(
      color: isDark ? const Color(0xFF0B0F19) : const Color(0xFFF3F4F1),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(LucideIcons.rocket, color: AppTheme.brandEmerald500, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'KloudShop',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.neutral900,
                      ),
                    ),
                  ],
                ),
                Text(
                  progressText,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressPercent,
                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                color: AppTheme.brandEmerald500,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepTile(String label, IconData icon,
      {required bool isActive, required bool isCompleted, required bool isDark}) {
    Color itemColor = isDark ? const Color(0xFF64748B) : AppTheme.neutral500;
    FontWeight weight = FontWeight.normal;
    Widget leading = Icon(icon, size: 16, color: itemColor);

    if (isCompleted) {
      itemColor = AppTheme.brandEmerald500;
      leading = const Icon(LucideIcons.checkSquare, size: 16, color: AppTheme.brandEmerald500);
      weight = FontWeight.w600;
    } else if (isActive) {
      itemColor = isDark ? Colors.white : AppTheme.neutral900;
      leading = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.brandTeal900,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 12, color: Colors.white),
      );
      weight = FontWeight.bold;
    }

    return Row(
      children: [
        leading,
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: weight,
            color: itemColor,
          ),
        ),
      ],
    );
  }

  // Right Side Content Director
  Widget _buildStepContent(BuildContext context, ProvisioningState state, bool isDark) {
    switch (state.currentStep) {
      case ProvisioningStep.storeSetup:
        return _buildStoreSetupView(context, state, isDark);
      case ProvisioningStep.infrastructure:
        return _buildInfrastructureView(context, state, isDark);
      case ProvisioningStep.loading:
        return _buildConsoleLoadingState(context, state, isDark);
      case ProvisioningStep.error:
        return _buildErrorState(context, state, isDark);
      case ProvisioningStep.success:
        return _buildSuccessState(context, state, isDark);
    }
  }

  // --- Step 1: Store Setup View ---
  Widget _buildStoreSetupView(BuildContext context, ProvisioningState state, bool isDark) {
    final hasValidationError = state.availabilityStatus == AvailabilityStatus.invalid;
    final isTaken = state.availabilityStatus == AvailabilityStatus.taken;
    final isAvailable = state.availabilityStatus == AvailabilityStatus.available;
    final isChecking = state.availabilityStatus == AvailabilityStatus.checking;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '1. Define Store Identity',
          style: GoogleFonts.outfit(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.6,
            color: isDark ? Colors.white : AppTheme.neutral900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Assign a unique URL handle to setup your isolated database schema.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : AppTheme.neutral500,
          ),
        ),
        const SizedBox(height: 32),

        // Handle text input card
        Text(
          'Store Subdomain Handle',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral700,
          ),
        ),
        const SizedBox(height: 8),
        SemanticTextFormField(
          controller: _tenantIdController,
          focusNode: _focusNode,
          onChanged: _onIdChanged,
          prefixIcon: LucideIcons.globe,
          hintText: 'e.g. quantum-boutique',
          suffixIcon: isChecking
              ? Container(
                  width: 20,
                  height: 20,
                  padding: const EdgeInsets.all(14),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.brandEmerald500,
                  ),
                )
              : isAvailable
                  ? const Icon(LucideIcons.checkCircle2, color: AppTheme.brandEmerald500, size: 20)
                  : isTaken
                      ? const Icon(LucideIcons.xCircle, color: Colors.redAccent, size: 20)
                      : null,
          errorText: (hasValidationError || isTaken) ? state.errorMessage : null,
        ),
        const SizedBox(height: 16),

        // URL Preview
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                : AppTheme.brandTeal50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF334155)
                  : AppTheme.brandTeal500.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.link,
                size: 16,
                color: isAvailable ? AppTheme.brandEmerald500 : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF94A3B8) : AppTheme.neutral500,
                    ),
                    children: [
                      const TextSpan(text: 'Domain: '),
                      TextSpan(
                        text: state.tenantId.isEmpty ? 'your-handle' : state.tenantId,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          color: isAvailable
                              ? AppTheme.brandEmerald500
                              : isDark
                                  ? Colors.white
                                  : AppTheme.neutral900,
                        ),
                      ),
                      const TextSpan(text: '.kloudshop.com'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),

        // Action Trigger
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: _signOut,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Cancel & Sign Out',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral700,
                ),
              ),
            ),
            HoverScale(
              child: ElevatedButton(
                onPressed: isAvailable
                    ? () => ref.read(tenantProvisioningProvider.notifier).proceedToInfrastructure()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandTeal900,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Row(
                  children: [
                    Text(
                      'Continue to Infrastructure',
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(LucideIcons.arrowRight, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPrimaryCard(GcpRegion region, double? distance, bool isDark) {
    final distStr = distance != null ? ' (~${distance.toStringAsFixed(0)} km away)' : '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1E293B).withValues(alpha: 0.4)
            : AppTheme.brandTeal50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.brandEmerald500, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brandEmerald500.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(_getContinentIcon(region.continent), color: AppTheme.brandEmerald500, size: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.brandEmerald500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRIMARY CLUSTER',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandEmerald500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            region.name,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${region.id}$distStr',
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Location: ${region.location}\nWorks best if your primary customers are from ${region.customerTarget}.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? const Color(0xFF94A3B8) : AppTheme.neutral700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFailoverCard(List<String>? failovers, bool isDark) {
    final hasFailovers = failovers != null && failovers.isNotEmpty;
    final cardBorderColor = hasFailovers 
        ? AppTheme.brandEmerald500 
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));
    final cardBgColor = isDark 
        ? (hasFailovers ? const Color(0xFF1E293B).withValues(alpha: 0.2) : const Color(0xFF0F172A))
        : (hasFailovers ? AppTheme.brandTeal50.withValues(alpha: 0.5) : Colors.white);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardBorderColor, width: hasFailovers ? 2.0 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                hasFailovers ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
                color: hasFailovers ? AppTheme.brandEmerald500 : Colors.grey,
                size: 20,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hasFailovers 
                      ? AppTheme.brandEmerald500.withValues(alpha: 0.1) 
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  hasFailovers ? 'FAILOVER ACTIVE' : 'NO FAILOVER',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: hasFailovers ? AppTheme.brandEmerald500 : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            hasFailovers ? 'Redundant Standby' : 'Cost Optimized',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.neutral900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            hasFailovers ? '${failovers.length} Backup Nodes' : 'Zero Redundancy',
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            hasFailovers 
                ? 'Automated failover nodes:\n${failovers.map((id) => gcpRegions[id]?.location ?? id).join(', ')}'
                : 'Maximum cost efficiency. Toggles are available in the accordion below to configure redundancy.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? const Color(0xFF94A3B8) : AppTheme.neutral700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getContinentIcon(String continent) {
    if (continent.contains('Americas')) return LucideIcons.globe;
    if (continent.contains('Europe')) return LucideIcons.mapPin;
    if (continent.contains('Asia')) return LucideIcons.network;
    return LucideIcons.server;
  }

  // --- Step 4: Infrastructure Setup View (Mockup Clone) ---
  Widget _buildInfrastructureView(BuildContext context, ProvisioningState state, bool isDark) {
    final notifier = ref.read(tenantProvisioningProvider.notifier);
    final sortedRegions = notifier.getSortedRegions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title Section
        Text(
          'Configure Your Infrastructure',
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : AppTheme.neutral900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the primary region for your store\'s high-performance cloud engine.',
          style: GoogleFonts.inter(
            fontSize: 15,
            color: isDark ? const Color(0xFF94A3B8) : AppTheme.neutral500,
          ),
        ),
        const SizedBox(height: 32),

        // Dropdown Selection Header
        Text(
          'Primary GCP Region',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: state.selectedRegion,
              hint: Text(
                'Select primary GCP region...',
                style: GoogleFonts.inter(
                  color: isDark ? const Color(0xFF64748B) : AppTheme.neutral400,
                ),
              ),
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              menuMaxHeight: 400,
              itemHeight: 76,
              icon: Icon(
                LucideIcons.chevronDown,
                color: isDark ? const Color(0xFF64748B) : AppTheme.neutral500,
              ),
              selectedItemBuilder: (BuildContext context) {
                return sortedRegions.map<Widget>((region) {
                  final dist = notifier.getDistanceToRegion(region.id);
                  final distStr = dist != null ? ' (~${dist.toStringAsFixed(0)} km)' : '';
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${region.name} (${region.id})$distStr',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppTheme.neutral700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
              items: sortedRegions.map((region) {
                final dist = notifier.getDistanceToRegion(region.id);
                final distStr = dist != null ? ' (~${dist.toStringAsFixed(0)} km)' : '';
                return DropdownMenuItem<String>(
                  value: region.id,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Line 1: Region Name + Location + Proximity
                              Row(
                                children: [
                                  Text(
                                    region.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : AppTheme.neutral700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '•  ${region.location}',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: isDark ? const Color(0xFF94A3B8) : AppTheme.neutral500,
                                    ),
                                  ),
                                  if (distStr.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: AppTheme.brandEmerald500.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        distStr.trim(),
                                        style: GoogleFonts.inter(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.brandEmerald500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Line 2: Technical ID + Customer Target Helper Text
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      region.id,
                                      style: GoogleFonts.robotoMono(
                                        fontSize: 11,
                                        color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: 'works best if primary customers are in ',
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5,
                                              color: isDark ? const Color(0xFF64748B) : AppTheme.neutral400,
                                            ),
                                          ),
                                          TextSpan(
                                            text: region.customerTarget,
                                            style: GoogleFonts.inter(
                                              fontSize: 12.5,
                                              fontWeight: region.customerTarget.contains('Eastern Canada') 
                                                  ? FontWeight.bold 
                                                  : FontWeight.w600,
                                              color: region.customerTarget.contains('Eastern Canada')
                                                  ? AppTheme.brandEmerald500 
                                                  : (isDark ? const Color(0xFF94A3B8) : AppTheme.neutral500),
                                            ),
                                          ),
                                        ],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Trailing world map graphic
                        Container(
                          width: 90,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: CustomPaint(
                              painter: WorldMapPainter(
                                latitude: region.latitude,
                                longitude: region.longitude,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  ref.read(tenantProvisioningProvider.notifier).selectRegion(val);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 32),

        if (state.selectedRegion == null) ...[
          // Empty state when no region is selected
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.globe,
                  size: 48,
                  color: isDark ? const Color(0xFF475569) : AppTheme.neutral400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Region Selected',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.neutral700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please select a primary GCP hosting region from the dropdown above to configure your database clusters and redundancy options.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? const Color(0xFF64748B) : AppTheme.neutral500,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // Adaptive Region Configuration Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final cardsWidth = constraints.maxWidth;
              final isWide = cardsWidth > 600;
              final primaryReg = state.selectedRegion!;
              final primaryRegionData = gcpRegions[primaryReg]!;
              final dist = notifier.getDistanceToRegion(primaryReg);

              final primaryCard = _buildPrimaryCard(primaryRegionData, dist, isDark);
              final failoverCard = _buildFailoverCard(state.selectedFailoverRegions, isDark);

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: primaryCard),
                    const SizedBox(width: 16),
                    Expanded(child: failoverCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    primaryCard,
                    const SizedBox(height: 12),
                    failoverCard,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 28),

          // Collapsible Panel: Multi-Region Redundancy
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAF6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Accordion Header
                InkWell(
                  onTap: () {
                    setState(() {
                      _isRedundancyExpanded = !_isRedundancyExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.shieldCheck, color: AppTheme.brandTeal900, size: 18),
                            const SizedBox(width: 12),
                            Text(
                              'Multi-Region Redundancy',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : AppTheme.neutral900,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          _isRedundancyExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Animated Expanded Content
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 1, thickness: 1),
                        const SizedBox(height: 16),

                        // Dynamic Surcharge Info Box
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? const Color(0xFF451A03) 
                                : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark 
                                  ? const Color(0xFF78350F).withValues(alpha: 0.4) 
                                  : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(LucideIcons.info, color: Colors.orange, size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.selectedFailoverRegions == null || state.selectedFailoverRegions!.isEmpty
                                          ? 'Cost Impact: Zero Redundancy Surcharge Waived'
                                          : 'Cost Impact: +${state.selectedFailoverRegions!.length * 15}% Monthly Surcharge',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      state.selectedFailoverRegions == null || state.selectedFailoverRegions!.isEmpty
                                          ? 'No redundant node has been selected. Running standard single-cluster configurations keeps infrastructure costs optimized with zero monthly surcharge.'
                                          : 'Activation of ${state.selectedFailoverRegions!.length} backup failover protection node(s) adds a ${state.selectedFailoverRegions!.length * 15}% surcharge to your monthly infrastructure bill to handle automated live data replication.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Dynamic Switches List + Global Add Dropdown
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final innerWidth = constraints.maxWidth;
                            final isRow = innerWidth > 500;
                            final primaryRegion = state.selectedRegion!;
                            final primaryDetails = gcpRegions[primaryRegion]!;

                            // 1. Same-continent candidates (recommended failovers)
                            final List<GcpRegion> recommendedList = [];
                            recommendedList.addAll(
                              gcpRegions.values.where(
                                (r) => r.continent == primaryDetails.continent && r.id != primaryRegion
                              )
                            );

                            // 2. Active failovers that are not in the same continent (to show switches for them)
                            final List<GcpRegion> activeFailoverRegions = [];
                            activeFailoverRegions.addAll(recommendedList);
                            
                            final selectedFailovers = state.selectedFailoverRegions ?? [];
                            for (var selectedId in selectedFailovers) {
                              if (!activeFailoverRegions.any((r) => r.id == selectedId)) {
                                final reg = gcpRegions[selectedId];
                                if (reg != null) {
                                  activeFailoverRegions.add(reg);
                                }
                              }
                            }

                            final switchWidgets = activeFailoverRegions.map((region) {
                              final isSelected = selectedFailovers.contains(region.id);
                              final dist = notifier.getDistanceToRegion(region.id);
                              final distStr = dist != null ? ' (~${dist.toStringAsFixed(0)} km)' : '';
                              return _buildSwitchTile(
                                '${region.name} (${region.id})$distStr',
                                isSelected,
                                (val) => ref.read(tenantProvisioningProvider.notifier).toggleFailoverRegion(region.id, val),
                                isDark,
                              );
                            }).toList();

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (switchWidgets.isNotEmpty) ...[
                                  Text(
                                    'RECOMMENDED CONTINENT CORES',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  if (isRow)
                                    Wrap(
                                      spacing: 16,
                                      runSpacing: 12,
                                      children: switchWidgets.map((w) => SizedBox(
                                        width: (innerWidth - 16) / 2,
                                        child: w,
                                      )).toList(),
                                    )
                                  else
                                    Column(
                                      children: [
                                        for (int i = 0; i < switchWidgets.length; i++) ...[
                                          if (i > 0) const SizedBox(height: 12),
                                          switchWidgets[i],
                                        ]
                                      ],
                                    ),
                                ],
                                const SizedBox(height: 20),
                                
                                // Global region dropdown selector
                                Row(
                                  children: [
                                    Text(
                                      'Add global backup node: ',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral700,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            hint: Text(
                                              'Select global region...',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: isDark ? const Color(0xFF64748B) : AppTheme.neutral500,
                                              ),
                                            ),
                                            isExpanded: true,
                                            dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: isDark ? Colors.white : AppTheme.neutral900,
                                            ),
                                            icon: const Icon(LucideIcons.plus, size: 14),
                                            items: gcpRegions.values
                                                .where((r) => r.id != primaryRegion && !activeFailoverRegions.any((active) => active.id == r.id))
                                                .map((r) => DropdownMenuItem<String>(
                                                      value: r.id,
                                                      child: Text('${r.name} (${r.id})'),
                                                    ))
                                                .toList(),
                                            onChanged: (val) {
                                              if (val != null) {
                                                ref.read(tenantProvisioningProvider.notifier).toggleFailoverRegion(val, true);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _isRedundancyExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Visual Terminal Blade Container
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: const Color(0xFF030712), // Visual terminal dark
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Background Grid Effect simulating server hardware
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: GridPaper(
                      color: AppTheme.brandEmerald500,
                      interval: 16,
                      subdivisions: 1,
                    ),
                  ),
                ),
                
                // Blinking LED dots inside servers
                Positioned(
                  right: 20,
                  top: 20,
                  bottom: 20,
                  child: _buildMockServerBlades(isDark),
                ),

                // Title and visual capacity indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.brandEmerald500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'PROVISIONING ENGINE READY',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.brandEmerald500,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'INIT_CLUSTER',
                            style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                      
                      // Custom visual Capacity Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'STANDBY_CAPACITY',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 10,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              Text(
                                '75% CAPACITY',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 10,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Container(
                              height: 4,
                              width: double.infinity,
                              color: const Color(0xFF1E293B),
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: 0.75,
                                child: Container(color: AppTheme.brandEmerald500.withValues(alpha: 0.7)),
                              ),
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
        ],
        const SizedBox(height: 48),

        // Actions: Back and Provision Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton.icon(
              onPressed: () => ref.read(tenantProvisioningProvider.notifier).goBackToStoreSetup(),
              icon: const Icon(LucideIcons.arrowLeft, size: 16),
              label: Text(
                'Back',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral700,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            HoverScale(
              child: ElevatedButton.icon(
                onPressed: state.selectedRegion != null ? _provision : null,
                icon: const Icon(LucideIcons.rocket, size: 18),
                label: Text(
                  'Provision Infrastructure',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.selectedRegion != null
                      ? AppTheme.brandEmerald500
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                  foregroundColor: state.selectedRegion != null
                      ? Colors.white
                      : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  shadowColor: AppTheme.brandEmerald500.withValues(alpha: 0.3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }



  // Redundancy Switch Tile builder
  Widget _buildSwitchTile(String label, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppTheme.neutral900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'REDUNDANT CLUSTER',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          LottieToggle(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // Decorative mock indicators for server blades
  Widget _buildMockServerBlades(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (bladeIndex) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle pull tab visual
            Container(width: 4, height: 16, color: const Color(0xFF334155), margin: const EdgeInsets.only(right: 12)),
            // LED Light array
            Row(
              children: List.generate(6, (ledIndex) {
                final isLit = (bladeIndex + ledIndex) % 3 == 0;
                return Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLit ? AppTheme.brandEmerald500 : const Color(0xFF1E293B),
                  ),
                );
              }),
            ),
          ],
        );
      }),
    );
  }

  // State 2: Loading State Console
  Widget _buildConsoleLoadingState(BuildContext context, ProvisioningState state, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF090D16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E293B).withValues(alpha: 0.4),
                    border: Border.all(
                      color: AppTheme.brandEmerald500.withValues(
                        alpha: 0.3 + (0.5 * (1.0 - _pulseAnimation.value)),
                      ),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.brandEmerald500.withValues(
                          alpha: 0.08 * _pulseAnimation.value,
                        ),
                        blurRadius: 15 * _pulseAnimation.value,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: CircularProgressIndicator(
                            value: (state.currentLogStepIndex + 1) / 5.0,
                            strokeWidth: 3,
                            backgroundColor: const Color(0xFF1E293B),
                            color: AppTheme.brandEmerald500,
                          ),
                        ),
                        Transform.scale(
                          scale: _pulseAnimation.value,
                          child: const Icon(
                            LucideIcons.rocket,
                            size: 26,
                            color: AppTheme.brandEmerald500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'PROVISIONING ENVIRONMENT',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Hold tight, configuring cloud SQL schemas and setting resources...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),

          // Console checklist
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF030712),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(state.logs.length, (index) {
                final stepName = state.logs[index];
                final isDone = index < state.currentLogStepIndex;
                final isCurrent = index == state.currentLogStepIndex;

                Color textColor = const Color(0xFF475569);
                Widget prefix = const Icon(LucideIcons.circleDot, size: 12, color: Color(0xFF334155));

                if (isDone) {
                  textColor = AppTheme.brandEmerald500;
                  prefix = const Icon(LucideIcons.checkCircle2, size: 12, color: AppTheme.brandEmerald500);
                } else if (isCurrent) {
                  textColor = Colors.white;
                  prefix = const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: Colors.white,
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      prefix,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          stepName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // State 3: Error State with retry details
  Widget _buildErrorState(BuildContext context, ProvisioningState state, bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: Icon(
                LucideIcons.alertTriangle,
                size: 48,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Provisioning Error',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: isDark ? Colors.white : AppTheme.neutral900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15)),
              ),
              child: Text(
                state.errorMessage.isNotEmpty
                    ? state.errorMessage
                    : 'An unexpected connection or timeout occurred while spawning database schemas.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.redAccent,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // Retry Button
            HoverScale(
              child: SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(tenantProvisioningProvider.notifier).reset();
                    ref.read(tenantProvisioningProvider.notifier).updateTenantId(_tenantIdController.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandTeal900,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.refreshCw, size: 16),
                      const SizedBox(width: 10),
                      Text(
                        'Retry Infrastructure Build',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel Button
            TextButton(
              onPressed: _signOut,
              child: Text(
                'Cancel and Sign Out',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : AppTheme.neutral500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // State 5: Success State
  Widget _buildSuccessState(BuildContext context, ProvisioningState state, bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF0F172A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.brandEmerald500, width: 1.2),
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 32,
                backgroundColor: AppTheme.brandEmerald50,
                child: Icon(
                  LucideIcons.checkCircle,
                  size: 40,
                  color: AppTheme.brandEmerald600,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Store Ready!',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.neutral900,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Your database environment for ${state.tenantId} has been successfully provisioned. Redirecting to your merchant dashboard...',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  height: 1.5,
                  color: isDark ? const Color(0xFFCBD5E1) : AppTheme.neutral700,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppTheme.brandEmerald500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorldMapPainter extends CustomPainter {
  final double? latitude;
  final double? longitude;
  final bool isDark;

  WorldMapPainter({this.latitude, this.longitude, required this.isDark});

  static const List<List<Offset>> _continents = [
    // North America
    [
      Offset(0.02, 0.15), Offset(0.20, 0.15), Offset(0.35, 0.10),
      Offset(0.32, 0.22), Offset(0.26, 0.25), Offset(0.28, 0.35),
      Offset(0.20, 0.40), Offset(0.18, 0.48), Offset(0.12, 0.45),
      Offset(0.10, 0.35), Offset(0.02, 0.25),
    ],
    // Greenland
    [
      Offset(0.34, 0.05), Offset(0.42, 0.05), Offset(0.38, 0.18),
      Offset(0.32, 0.15),
    ],
    // South America
    [
      Offset(0.20, 0.50), Offset(0.28, 0.50), Offset(0.35, 0.58),
      Offset(0.33, 0.68), Offset(0.28, 0.85), Offset(0.25, 0.85),
      Offset(0.22, 0.70), Offset(0.18, 0.60),
    ],
    // Africa
    [
      Offset(0.45, 0.42), Offset(0.52, 0.40), Offset(0.58, 0.45),
      Offset(0.62, 0.55), Offset(0.58, 0.72), Offset(0.55, 0.78),
      Offset(0.53, 0.78), Offset(0.49, 0.60), Offset(0.44, 0.52),
    ],
    // Madagascar
    [
      Offset(0.60, 0.68), Offset(0.62, 0.68), Offset(0.61, 0.75),
      Offset(0.59, 0.75),
    ],
    // Eurasia
    [
      Offset(0.40, 0.25), Offset(0.48, 0.20), Offset(0.58, 0.12),
      Offset(0.75, 0.12), Offset(0.92, 0.15), Offset(0.98, 0.22),
      Offset(0.92, 0.38), Offset(0.85, 0.50), Offset(0.80, 0.48),
      Offset(0.72, 0.58), Offset(0.68, 0.52), Offset(0.58, 0.40),
      Offset(0.50, 0.40), Offset(0.46, 0.35),
    ],
    // Japan
    [
      Offset(0.88, 0.25), Offset(0.90, 0.28), Offset(0.89, 0.35),
      Offset(0.87, 0.32),
    ],
    // United Kingdom / Ireland
    [
      Offset(0.41, 0.22), Offset(0.44, 0.22), Offset(0.43, 0.28),
      Offset(0.40, 0.28),
    ],
    // Iceland
    [
      Offset(0.38, 0.18), Offset(0.41, 0.18), Offset(0.40, 0.22),
      Offset(0.37, 0.22),
    ],
    // Australia
    [
      Offset(0.78, 0.68), Offset(0.88, 0.65), Offset(0.90, 0.75),
      Offset(0.86, 0.82), Offset(0.78, 0.78),
    ],
    // New Zealand
    [
      Offset(0.91, 0.82), Offset(0.93, 0.82), Offset(0.91, 0.88),
      Offset(0.89, 0.88),
    ],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Ocean Background with a subtle gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
            : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // 2. Draw Faint Gridlines (Latitude/Longitude Chart Lines)
    final gridPaint = Paint()
      ..color = isDark 
          ? Colors.white.withOpacity(0.06) 
          : Colors.black.withOpacity(0.04)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Latitudes (Horizontal lines)
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), gridPaint);

    // Longitudes (Vertical lines)
    canvas.drawLine(Offset(size.width * 0.25, 0), Offset(size.width * 0.25, size.height), gridPaint);
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), gridPaint);
    canvas.drawLine(Offset(size.width * 0.75, 0), Offset(size.width * 0.75, size.height), gridPaint);

    // 3. Draw Landmasses (with a premium gradient and stroke)
    final landPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isDark
            ? [const Color(0xFF475569).withOpacity(0.6), const Color(0xFF334155).withOpacity(0.4)]
            : [const Color(0xFFCBD5E1), const Color(0xFF94A3B8)],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = isDark 
          ? const Color(0xFF64748B).withOpacity(0.4) 
          : const Color(0xFF94A3B8).withOpacity(0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw continents
    for (final polygon in _continents) {
      final path = Path();
      if (polygon.isEmpty) continue;
      path.moveTo(polygon[0].dx * size.width, polygon[0].dy * size.height);
      for (int i = 1; i < polygon.length; i++) {
        path.lineTo(polygon[i].dx * size.width, polygon[i].dy * size.height);
      }
      path.close();
      
      canvas.drawPath(path, landPaint);
      canvas.drawPath(path, outlinePaint);
    }

    // 4. Draw Glowing Locator Crosshair (Plus sign with gap and center dot)
    if (latitude != null && longitude != null) {
      // Equirectangular projection translation
      final x = ((longitude! + 180) / 360) * size.width;
      final y = ((90 - latitude!) / 180) * size.height;

      // Center locator dot (AppTheme.brandEmerald500)
      final centerDotPaint = Paint()
        ..color = AppTheme.brandEmerald500
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 1.8, centerDotPaint);

      // Crosshair bars (isDark ? Colors.white : AppTheme.brandTeal900)
      final barPaint = Paint()
        ..color = isDark ? Colors.white : AppTheme.brandTeal900
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.square;

      // Draw the four outer crosshair lines with a gap in the center
      // Left bar
      canvas.drawLine(Offset(x - 11, y), Offset(x - 4, y), barPaint);
      // Right bar
      canvas.drawLine(Offset(x + 4, y), Offset(x + 11, y), barPaint);
      // Top bar
      canvas.drawLine(Offset(x, y - 11), Offset(x, y - 4), barPaint);
      // Bottom bar
      canvas.drawLine(Offset(x, y + 4), Offset(x, y + 11), barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter oldDelegate) {
    return oldDelegate.latitude != latitude || 
           oldDelegate.longitude != longitude || 
           oldDelegate.isDark != isDark;
  }
}
