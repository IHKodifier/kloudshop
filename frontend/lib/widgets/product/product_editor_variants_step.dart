import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/providers/product_editor_provider.dart';
import 'package:kloudshop/services/file_uploader.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/product/product_options_card.dart';
import 'package:kloudshop/widgets/product/product_variants_section.dart';

class ProductEditorVariantsStep extends ConsumerStatefulWidget {
  final Product? product;
  const ProductEditorVariantsStep({super.key, this.product});

  @override
  ConsumerState<ProductEditorVariantsStep> createState() =>
      _ProductEditorVariantsStepState();
}

class _ProductEditorVariantsStepState
    extends ConsumerState<ProductEditorVariantsStep> {
  late final FileUploader _uploader;
  int _lastVariantCount = 0;
  bool _showVariantChangeAnimation = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _uploader = MockFileUploader(
      apiUpload: (bytes, name) =>
          ref.read(apiServiceProvider).uploadMedia(bytes, name),
    );
    final state = ref.read(productEditorProvider(widget.product));
    _lastVariantCount = state.variants.length;
  }

  void _showNotification(
    BuildContext context,
    String message, {
    bool isError = false,
    bool isDeletion = false,
  }) {
    final bool isFailure = isError || isDeletion;
    final backgroundColor = isFailure
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFF0FDF4);
    final contentColor = isFailure
        ? const Color(0xFF991B1B)
        : const Color(0xFF166534);
    final borderColor = isFailure
        ? const Color(0xFFFECACA)
        : const Color(0xFFBBF7D0);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFailure ? LucideIcons.alertCircle : LucideIcons.checkCircle2,
              color: contentColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  color: contentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  void _handleGenerate(
    BuildContext context,
    WidgetRef ref,
    ProductEditorState state,
    ProductEditorNotifier notifier, {
    bool fromCollapse = false,
  }) async {
    if (state.variants.length == 1) {
      final soleVariant = state.variants.first;
      final sku = (soleVariant['sku'] as String? ?? '').trim();
      if (sku.isEmpty) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('SKU Required'),
              content: const Text(
                'Please set a SKU for the variant before generating option-based combinations.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
        return;
      }
    }

    final activeOptions = state.optionsSchema.where((opt) {
      final name = (opt['name'] as String? ?? '').trim();
      final values = List<dynamic>.from(opt['values'] ?? []);
      return name.isNotEmpty && values.isNotEmpty;
    }).toList();

    // No active options AND this was not triggered by the collapse confirmation:
    // The user clicked Generate Variants with an empty schema — inform them.
    if (activeOptions.isEmpty && !fromCollapse) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF1D4ED8), size: 16),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Add at least one option value (e.g. a colour) to generate variants.',
                    style: TextStyle(
                      color: Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEFF6FF),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 3000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFFBFDBFE)),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        );
      }
      return;
    }

    // ── Full-collapse path (fromCollapse = true, no active options) ──────────
    // The user confirmed via the chip/trash dialog.  Skip the Cartesian product
    // and reconciliation-choice dialog entirely; jump straight to the retirement
    // warning and then execute the collapse inside the provider.
    if (fromCollapse && activeOptions.isEmpty) {
      final List<Map<String, dynamic>> retiringVariants =
          notifier.computeRetiringVariants();

      if (retiringVariants.isNotEmpty && context.mounted) {
        final int retiredStock = retiringVariants.fold(
          0,
          (sum, v) => sum + (int.tryParse(v['stock']?.toString() ?? '0') ?? 0),
        );

        bool? confirmed;
        await showGeneralDialog<void>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Retirement Warning',
          barrierColor: Colors.black.withValues(alpha: 0.70),
          transitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (ctx, anim1, anim2) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              backgroundColor:
                  isDark ? const Color(0xFF0F172A) : Colors.white,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber[700]!
                                  .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(LucideIcons.triangleAlert,
                                color: Colors.amber[600], size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Collapse to Simple Product',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                                Text(
                                  '${retiringVariants.length} variant${retiringVariants.length == 1 ? '' : 's'} will be retired',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Removing all option values will retire all ${retiringVariants.length} variant${retiringVariants.length == 1 ? '' : 's'} and revert this product to a single default variant. '
                        'You will lose the granular stock, price, compareAt price, and SKU data for each retiring variant. '
                        'The total stock ($retiredStock units) will be aggregated into the default variant.',
                        style: const TextStyle(fontSize: 13, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF052E16)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppTheme.brandEmerald500
                                .withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(LucideIcons.mail,
                                size: 16,
                                color: AppTheme.brandEmerald500),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'A detailed retirement report (SKUs, prices, compareAt prices, stock levels) will be sent to your merchant email so you can reconcile your physical inventory.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  color: isDark
                                      ? Colors.green[200]
                                      : Colors.green[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              confirmed = false;
                              Navigator.pop(ctx);
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(LucideIcons.check, size: 16),
                            label: const Text(
                              'Yes, Collapse Product',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            onPressed: () {
                              confirmed = true;
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

        if (confirmed != true) return;
      }

      // Execute collapse
      setState(() => _isGenerating = true);
      await Future.delayed(const Duration(milliseconds: 100));
      notifier.generateVariantsFromOptions(reconcile: true);

      // Send retirement report
      if (retiringVariants.isNotEmpty) {
        final afterState = ref.read(productEditorProvider(widget.product));
        final surviving = afterState.variants
            .where((v) => v['is_active'] != false)
            .toList();
        final survivingSku = surviving.isNotEmpty
            ? surviving.first['sku'].toString()
            : afterState.slug.toUpperCase();
        final int aggregatedStock = retiringVariants.fold(
          0,
          (sum, v) =>
              sum + (int.tryParse(v['stock']?.toString() ?? '0') ?? 0),
        );
        ref.read(apiServiceProvider).sendVariantRetirementReport(
          productTitle: afterState.title,
          productSlug: afterState.slug,
          productId: widget.product?.id,
          retiringVariants: retiringVariants,
          aggregatedStock: aggregatedStock,
          survivingVariantSku: survivingSku,
        );
      }

      if (mounted) setState(() => _isGenerating = false);
      if (context.mounted) {
        _showNotification(context, 'Product collapsed to a single default variant.');
      }
      return;
    }
    // ── end full-collapse path ────────────────────────────────────────────────

    List<Map<String, String>> cartesianProduct(
      List<Map<String, dynamic>> options,
      int index,
    ) {
      if (index == options.length) {
        return [{}];
      }

      final currentOpt = options[index];
      final currentName = currentOpt['name'] as String;
      final currentValues = List<String>.from(currentOpt['values'] ?? []);

      final subProducts = cartesianProduct(options, index + 1);
      final List<Map<String, String>> result = [];

      for (var val in currentValues) {
        for (var subProduct in subProducts) {
          result.add({currentName: val, ...subProduct});
        }
      }
      return result;
    }

    final permutations = cartesianProduct(activeOptions, 0);

    // Detect if permutations have changed
    bool permutationsChanged = false;
    if (state.variants.isNotEmpty) {
      if (permutations.length != state.variants.length) {
        permutationsChanged = true;
      } else {
        for (var perm in permutations) {
          final hasMatch = state.variants.any((v) {
            final vOpts = Map<String, String>.from(v['option_values'] ?? {});
            if (vOpts.length != perm.length) return false;
            return perm.entries.every((e) => vOpts[e.key] == e.value);
          });
          if (!hasMatch) {
            permutationsChanged = true;
            break;
          }
        }
      }
    }

    bool reconcileMode = true;
    if (permutationsChanged) {
      bool? shouldProceed;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Reconciliation Choice',
        barrierColor: Colors.black.withValues(alpha: 0.65),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim1, anim2) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final Color activeBorder = AppTheme.brandEmerald500;
              final Color inactiveBorder = isDark ? const Color(0xFF334155) : Colors.grey[200]!;
              final Color activeBg = AppTheme.brandEmerald500.withValues(alpha: 0.1);
              final Color inactiveBg = isDark ? const Color(0xFF1E293B) : Colors.white;

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                backgroundColor: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.9) : Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 520),
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber[500]!.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.merge_type_rounded, color: Colors.amber[600], size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Reconcile Variants?',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You have modified option categories or values. Choose how you want to update the existing variant configurations:',
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Option 1: Intelligent Reconciliation
                      InkWell(
                        canRequestFocus: false,
                        onTap: () {
                          setDialogState(() {
                            reconcileMode = true;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: reconcileMode ? activeBg : inactiveBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: reconcileMode ? activeBorder : inactiveBorder,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Radio<bool>(
                                value: true,
                                groupValue: reconcileMode,
                                activeColor: AppTheme.brandEmerald500,
                                onChanged: (val) {
                                  setDialogState(() {
                                    reconcileMode = true;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Intelligent Reconciliation (Recommended)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFamily: 'Outfit',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Preserves configured pricing, stock levels, images, and shipping overrides from matched old variants. Custom SKUs will propagate with option suffixes.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Option 2: Fresh Generation
                      InkWell(
                        canRequestFocus: false,
                        onTap: () {
                          setDialogState(() {
                            reconcileMode = false;
                          });
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: !reconcileMode ? activeBg : inactiveBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: !reconcileMode ? activeBorder : inactiveBorder,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Radio<bool>(
                                value: false,
                                groupValue: reconcileMode,
                                activeColor: AppTheme.brandEmerald500,
                                onChanged: (val) {
                                  setDialogState(() {
                                    reconcileMode = false;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Fresh Generation',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        fontFamily: 'Outfit',
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Discards all current variants and generates new ones with default pricing, stock, and slug-based SKUs. Any manual overrides will be lost.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              shouldProceed = false;
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              shouldProceed = true;
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandEmerald500,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: const Text(
                              'Apply Selection',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (shouldProceed != true) {
        return; // User cancelled
      }
    }

    // ── Retirement warning ────────────────────────────────────────────────
    // Dry-run: find which active variants will be retired by this operation.
    // Show a blocking warning dialog if any exist so the merchant can opt out.
    final List<Map<String, dynamic>> retiringVariants =
        notifier.computeRetiringVariants();

    if (retiringVariants.isNotEmpty && context.mounted) {
      final int retiredStock = retiringVariants.fold(
        0,
        (sum, v) => sum + (int.tryParse(v['stock']?.toString() ?? '0') ?? 0),
      );

      bool? confirmed;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Retirement Warning',
        barrierColor: Colors.black.withValues(alpha: 0.70),
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (ctx, anim1, anim2) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            backgroundColor:
                isDark ? const Color(0xFF0F172A) : Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber[700]!
                                .withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(LucideIcons.triangleAlert,
                              color: Colors.amber[600], size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Variants Will Be Retired',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              Text(
                                '${retiringVariants.length} variant${retiringVariants.length == 1 ? '' : 's'} will become inactive',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Retiring variant rows
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber[700]!
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                            child: Text(
                              'Variants being retired:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Outfit',
                                color: Colors.amber[700],
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const Divider(height: 1, indent: 14, endIndent: 14),
                          ...retiringVariants.asMap().entries.map((entry) {
                            final v = entry.value;
                            final opts = Map<String, String>.from(
                                v['option_values'] ?? {});
                            final optStr = opts.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join(' · ');
                            final compareAt =
                                v['compare_at_price']?.toString() ?? '';
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                border: entry.key <
                                        retiringVariants.length - 1
                                    ? Border(
                                        bottom: BorderSide(
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.07)
                                              : Colors.grey[200]!,
                                        ),
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v['sku']?.toString() ?? '—',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            fontFamily: 'Outfit',
                                          ),
                                        ),
                                        if (optStr.isNotEmpty)
                                          Text(
                                            optStr,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Price: \$${v['price']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (compareAt.isNotEmpty)
                                        Text(
                                          'Was: \$$compareAt',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.grey[500]
                                                : Colors.grey[500],
                                            fontFamily: 'Inter',
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                      Text(
                                        'Stock: ${v['stock']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'Inter',
                                          color: isDark
                                              ? Colors.blue[300]
                                              : Colors.blue[700],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stock aggregation notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF172554)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.blue[300]!
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.layers,
                              size: 16,
                              color: isDark
                                  ? Colors.blue[300]
                                  : Colors.blue[700]),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Their combined stock ($retiredStock units) will be aggregated and assigned to the surviving variant. You will lose per-variant stock granularity.',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Inter',
                                color: isDark
                                    ? Colors.blue[200]
                                    : Colors.blue[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Email report notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF052E16)
                            : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              AppTheme.brandEmerald500.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(LucideIcons.mail,
                              size: 16,
                              color: AppTheme.brandEmerald500),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'A detailed report with SKUs, prices, compareAt prices, and stock levels of all retiring variants will be sent to your registered merchant email so you can reconcile your physical stock.',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Inter',
                                color: isDark
                                    ? Colors.green[200]
                                    : Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            confirmed = false;
                            Navigator.pop(ctx);
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(LucideIcons.check, size: 16),
                          label: const Text(
                            'Proceed with Retirement',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          onPressed: () {
                            confirmed = true;
                            Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (confirmed != true) return; // User cancelled retirement
    }
    // ── end retirement warning ────────────────────────────────────────────

    setState(() {
      _isGenerating = true;
    });

    // Yield a frame to let the loading spinner render on the button
    await Future.delayed(const Duration(milliseconds: 100));

    notifier.generateVariantsFromOptions(reconcile: reconcileMode);

    // ── Post-generation: send retirement report if any variants were retired
    if (retiringVariants.isNotEmpty) {
      final afterState = ref.read(productEditorProvider(widget.product));
      // Find the first surviving active variant SKU
      final surviving = afterState.variants
          .where((v) => v['is_active'] != false)
          .toList();
      final survivingSku = surviving.isNotEmpty
          ? surviving.first['sku'].toString()
          : afterState.slug.toUpperCase();
      final int aggregatedStock = retiringVariants.fold(
        0,
        (sum, v) => sum + (int.tryParse(v['stock']?.toString() ?? '0') ?? 0),
      );
      // Fire-and-forget — non-fatal if it fails
      ref.read(apiServiceProvider).sendVariantRetirementReport(
        productTitle: afterState.title,
        productSlug: afterState.slug,
        productId: widget.product?.id,
        retiringVariants: retiringVariants,
        aggregatedStock: aggregatedStock,
        survivingVariantSku: survivingSku,
      );
    }

    final updatedState = ref.read(productEditorProvider(widget.product));
    final List<String> names = updatedState.variants.map((v) {
      final sku = v['sku'] as String? ?? '';
      final optionValues = Map<String, String>.from(v['option_values'] ?? {});
      final optionStr = optionValues.values.join('-');
      final suffix = optionStr.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9\-]'),
        '-',
      );
      final urlSlug = updatedState.slug.isNotEmpty
          ? '${updatedState.slug}-$suffix'
          : suffix;
      return '$sku ($urlSlug)';
    }).toList();

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });
    }

    if (!context.mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Variants Generated',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  child: Lottie.network(
                    'https://lottie.host/c5c8e31a-e8f0-466d-9db8-5d2df1c469f6/mH9y7G1j7C.json',
                    repeat: false,
                    frameBuilder: (context, child, composition) {
                      if (composition == null) {
                        return const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppTheme.brandEmerald500,
                            ),
                          ),
                        );
                      }
                      return child;
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        LucideIcons.checkCircle2,
                        size: 80,
                        color: AppTheme.brandEmerald500,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Variants Generated Successfully!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Created ${permutations.length} variants:',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: names.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 8),
                    itemBuilder: (context, idx) {
                      return Row(
                        children: [
                          const Icon(
                            LucideIcons.check,
                            color: AppTheme.brandEmerald500,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              names[idx],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  void _addVariant(ProductEditorNotifier notifier) {
    notifier.addVariant();
    _showNotification(context, 'Variant added');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productEditorProvider(widget.product));
    final notifier = ref.read(productEditorProvider(widget.product).notifier);

    if (state.variants.length != _lastVariantCount) {
      final hasPreviousCount = _lastVariantCount > 0;
      _lastVariantCount = state.variants.length;
      if (hasPreviousCount) {
        _showVariantChangeAnimation = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _showVariantChangeAnimation = false;
            });
          }
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductOptionsCard(
          optionsSchema: state.optionsSchema,
          isGenerating: _isGenerating,
          onGenerateVariants: () => _handleGenerate(context, ref, state, notifier),
          onChanged: (newSchema) {
            notifier.updateOptionsSchema(newSchema);
          },
          onCollapseConfirmed: () => _handleGenerate(context, ref,
              ref.read(productEditorProvider(widget.product)), notifier,
              fromCollapse: true),
        ),
        const SizedBox(height: 16),
        ProductVariantsSection(
          variants: state.variants,
          optionsSchema: state.optionsSchema,
          productSlug: state.slug,
          isNewProduct: widget.product == null,
          isDigital: state.isDigital,
          uploader: _uploader,
          showVariantChangeAnimation: _showVariantChangeAnimation,
          onAddVariant: () => _addVariant(notifier),
          onChanged: () {
            notifier.updateVariants(List.from(state.variants));
          },
        ),
      ],
    );
  }
}
