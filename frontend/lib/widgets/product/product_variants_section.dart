import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:kloudshop/widgets/lottie_toggle.dart';
import 'package:kloudshop/widgets/upload/compact_media_list_uploader.dart';
import 'package:kloudshop/services/file_uploader.dart';
import 'package:kloudshop/widgets/semantic_text_form_field.dart';

class ProductVariantsSection extends StatefulWidget {
  final List<Map<String, dynamic>> variants;
  final List<Map<String, dynamic>> optionsSchema;
  final String productSlug;
  final bool isNewProduct;
  final bool isDigital;
  final FileUploader uploader;
  final bool showVariantChangeAnimation;
  final VoidCallback onAddVariant;
  final VoidCallback onChanged;

  const ProductVariantsSection({
    super.key,
    required this.variants,
    required this.optionsSchema,
    required this.productSlug,
    required this.isNewProduct,
    required this.isDigital,
    required this.uploader,
    required this.showVariantChangeAnimation,
    required this.onAddVariant,
    required this.onChanged,
  });

  @override
  State<ProductVariantsSection> createState() => _ProductVariantsSectionState();
}

class _ProductVariantsSectionState extends State<ProductVariantsSection> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeOptions = widget.optionsSchema.where((opt) {
      final name = (opt['name'] as String? ?? '').trim();
      final values = List<dynamic>.from(opt['values'] ?? []);
      return name.isNotEmpty && values.isNotEmpty;
    }).toList();

    final visibleVariants = widget.variants.where((v) {
      final optVals = Map<String, String>.from(v['option_values'] ?? {});
      if (activeOptions.isNotEmpty) {
        return optVals.isNotEmpty;
      } else {
        return optVals.isEmpty;
      }
    }).toList();

    final activeCount =
        visibleVariants.where((v) => v['is_active'] ?? true).length;
    final totalCount = visibleVariants.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.layers,
                  size: 20,
                  color: AppTheme.brandEmerald500,
                ),
                const SizedBox(width: 8),
                Text(
                  'Variants & Pricing ($activeCount active of $totalCount)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.showVariantChangeAnimation) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Lottie.network(
                      'https://lottie.host/d19b48b5-55ff-4c28-bb73-90d569653a99/cSwQ8f00Tq.json',
                      repeat: false,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          LucideIcons.check,
                           size: 16,
                          color: AppTheme.brandEmerald500,
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
            HoverScale(
              child: ElevatedButton.icon(
                onPressed: widget.onAddVariant,
                icon: const Icon(
                  LucideIcons.plus,
                  size: 14,
                  color: AppTheme.brandEmerald500,
                ),
                label: const Text(
                  'Add Variant',
                  style: TextStyle(color: AppTheme.brandEmerald500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandEmerald500.withValues(
                    alpha: 0.1,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Builder(
          builder: (context) {
            final activeVariants = visibleVariants
                .where((v) => v['is_active'] ?? true)
                .toList();
            final inactiveVariants = visibleVariants
                .where((v) => !(v['is_active'] ?? true))
                .toList();
            final sortedVariants = [...activeVariants, ...inactiveVariants];

            if (sortedVariants.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.3)
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      size: 32,
                      color: AppTheme.brandEmerald500.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      activeOptions.isNotEmpty
                          ? 'Generate Variant Combinations'
                          : 'No Options Active',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeOptions.isNotEmpty
                          ? 'You have added option categories (such as ${activeOptions.map((o) => o['name']).join(', ')}). Click the "Generate Variants" button above to build the variants list.'
                          : 'This product has no options. It will be sold as a single default product with the main SKU.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedVariants.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final variant = sortedVariants[index];

                return _VariantItemCard(
                  key: ObjectKey(variant),
                  variant: variant,
                  optionsSchema: widget.optionsSchema,
                  productSlug: widget.productSlug,
                  isNewProduct: widget.isNewProduct,
                  isDigital: widget.isDigital,
                  uploader: widget.uploader,
                  isDark: isDark,
                  theme: theme,
                  isAlternate: index % 2 == 1,
                  canDeactivate: totalCount > 1,
                  onChanged: widget.onChanged,
                  onToggleActive: (val) {
                    setState(() {
                      final bool wasDefault = variant['is_default'] ?? false;
                      variant['is_active'] = val;

                      if (!val) {
                        variant['is_expanded'] = false;
                      }

                      if (!val && wasDefault) {
                        variant['is_default'] = false;
                        // Promote the first other active variant to default
                        final firstActive = visibleVariants
                            .where(
                              (v) => v != variant && (v['is_active'] ?? true),
                            )
                            .firstOrNull;
                        if (firstActive != null) {
                          firstActive['is_default'] = true;
                        } else {
                          // Keep it default if no other active variants
                          variant['is_default'] = true;
                        }
                      } else if (val) {
                        // If activating and there is no active default variant, make this default
                        final hasActiveDefault = visibleVariants.any(
                          (v) =>
                              (v['is_active'] ?? true) &&
                              (v['is_default'] ?? false),
                        );
                        if (!hasActiveDefault) {
                          for (var v in visibleVariants) {
                            v['is_default'] = false;
                          }
                          variant['is_default'] = true;
                        }
                      }
                    });
                    widget.onChanged();
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _VariantItemCard extends StatefulWidget {
  final Map<String, dynamic> variant;
  final List<Map<String, dynamic>> optionsSchema;
  final String productSlug;
  final bool isNewProduct;
  final bool isDigital;
  final FileUploader uploader;
  final bool isDark;
  final ThemeData theme;
  final bool isAlternate;
  final bool canDeactivate;
  final VoidCallback onChanged;
  final ValueChanged<bool> onToggleActive;

  const _VariantItemCard({
    super.key,
    required this.variant,
    required this.optionsSchema,
    required this.productSlug,
    required this.isNewProduct,
    required this.isDigital,
    required this.uploader,
    required this.isDark,
    required this.theme,
    required this.isAlternate,
    required this.canDeactivate,
    required this.onChanged,
    required this.onToggleActive,
  });

  @override
  State<_VariantItemCard> createState() => _VariantItemCardState();
}

class _VariantItemCardState extends State<_VariantItemCard> {
  bool _isProcessing = false;

  void _handleToggle(bool val) {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
    });

    BuildContext? dialogContext;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dContext) {
        dialogContext = dContext;
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.theme.dividerColor,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(widget.isDark ? 0.5 : 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppTheme.brandEmerald500,
                      ),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Re-arranging your variants',
                    style: widget.theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        if (dialogContext != null) {
          Navigator.of(dialogContext!).pop();
        }
        widget.onToggleActive(val);
        setState(() {
          _isProcessing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final variant = widget.variant;
    final isDark = widget.isDark;
    final theme = widget.theme;
    final Map<String, String> optionVals = Map<String, String>.from(
      variant['option_values'] ?? {},
    );
    final bool isExpanded = variant['is_expanded'] ?? false;
    final bool isActive = variant['is_active'] ?? true;

    final customInputStyle = theme.textTheme.bodyMedium;
    final customLabelStyle = theme.textTheme.bodySmall;
    const customPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    // Build dynamic option value chips
    final List<Widget> optionChips = [];
    for (var opt in widget.optionsSchema) {
      final String name = opt['name'];
      final List<String> vals = List<String>.from(opt['values']);
      if (name.isNotEmpty && vals.isNotEmpty) {
        final val = optionVals[name] ?? vals.first;
        optionChips.add(
          Chip(
            label: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$name: ',
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  TextSpan(
                    text: val,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.grey[900],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: isDark
                ? const Color(0xFF1E293B)
                : Colors.grey[100],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: isDark ? const Color(0xFF334155) : Colors.grey[300]!,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
        );
      }
    }

    final List<String> vImages = List<String>.from(variant['images'] ?? []);

    final Color cardColor = isActive
        ? (isDark
            ? (widget.isAlternate ? const Color(0xFF0D251A) : const Color(0xFF1E293B))
            : (widget.isAlternate ? const Color(0xFFEBFDF2) : Colors.white))
        : (isDark
            ? (widget.isAlternate ? const Color(0xFF071711).withValues(alpha: 0.5) : const Color(0xFF0F172A).withValues(alpha: 0.5))
            : (widget.isAlternate ? const Color(0xFFF2FDF6) : Colors.grey[50]!));

    final Color borderColor = isActive
        ? (widget.isAlternate
            ? theme.dividerColor
            : (isDark ? const Color(0xFF0F3B25) : const Color(0xFFA7F3D0)))
        : (widget.isAlternate
            ? theme.dividerColor.withValues(alpha: 0.5)
            : (isDark
                ? const Color(0xFF0F3B25).withValues(alpha: 0.5)
                : const Color(0xFFA7F3D0).withValues(alpha: 0.5)));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: isExpanded
          ? const EdgeInsets.all(20)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: isActive ? 1.0 : 0.8,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collapse / Expand Header Row
                  InkWell(
                    onTap: () {
                      setState(() {
                        variant['is_expanded'] = !isExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Opacity(
                            opacity: isActive ? 1.0 : 0.5,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isExpanded
                                      ? LucideIcons.chevronUp
                                      : LucideIcons.chevronDown,
                                  size: 20,
                                  color: AppTheme.brandEmerald500,
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Opacity(
                              opacity: isActive ? 1.0 : 0.5,
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text.rich(
                                      TextSpan(
                                        style: TextStyle(
                                          decoration: isActive
                                              ? null
                                              : TextDecoration.lineThrough,
                                        ),
                                        children: optionVals.isEmpty
                                            ? [
                                                TextSpan(
                                                  text: 'Default Variant',
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.grey[900],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ]
                                            : [
                                                TextSpan(
                                                  text: () {
                                                    final String sku = variant['sku']?.toString() ?? '';
                                                    if (sku.isNotEmpty) return sku;
                                                    final optionStr = optionVals.values.join('-');
                                                    final baseSku = widget.productSlug.isNotEmpty
                                                        ? widget.productSlug.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\-]'), '-')
                                                        : 'PRODUCT';
                                                    final defaultSuffix = optionStr.toUpperCase().replaceAll(
                                                      RegExp(r'[^A-Z0-9\-]'),
                                                      '-',
                                                    );
                                                    return baseSku.isNotEmpty ? '$baseSku-$defaultSuffix' : 'PRODUCT-SKU';
                                                  }(),
                                                  style: TextStyle(
                                                    color: isDark
                                                        ? Colors.white
                                                        : Colors.grey[900],
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (optionChips.isNotEmpty) ...[
                                    const SizedBox(width: 12),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: optionChips,
                                    ),
                                  ],
                                  if (optionVals.isEmpty && variant['sku']?.toString().isNotEmpty == true) ...[
                                    const SizedBox(width: 12),
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.blueGrey.withValues(
                                                  alpha: 0.2,
                                                )
                                              : Colors.blueGrey.withValues(
                                                  alpha: 0.1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          'SKU: ${variant['sku']}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isDark
                                                ? Colors.grey[300]
                                                : Colors.grey[700],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Opacity(
                            opacity: isActive ? 1.0 : 0.5,
                            child: Text(
                              variant['price']?.toString().isNotEmpty == true
                                  ? '\$${variant['price']}'
                                  : '\$0.00',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.brandEmerald500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          LottieToggle(
                            value: isActive,
                            onChanged: widget.canDeactivate ? _handleToggle : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 600),
                    curve: const ElasticOutCurve(0.25),
                    alignment: Alignment.topCenter,
                    child: isExpanded
                        ? Opacity(
                            opacity: isActive ? 1.0 : 0.5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(height: 24),
                                Row(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     // Left Column (60% width)
                                     Expanded(
                                       flex: 3,
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      SemanticTextFormField(
                                                        initialValue: variant['sku'],
                                                        enabled: isActive,
                                                        textInputAction: TextInputAction.next,
                                                        labelText: 'SKU',
                                                        helperText: 'e.g., TS123',
                                                        prefixIcon: LucideIcons.tag,
                                                        onChanged: (v) {
                                                          variant['sku'] = v;
                                                          widget.onChanged();
                                                        },
                                                        validator: (v) => v?.isEmpty == true ? 'Required' : null,
                                                      ),
                                                      if (variant['variant_id'] != null &&
                                                          variant['sku'] != variant['original_sku'])
                                                        Padding(
                                                          padding: const EdgeInsets.only(top: 6.0),
                                                          child: Row(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Icon(
                                                                Icons.warning_amber_rounded,
                                                                color: Colors.amber[700],
                                                                size: 14,
                                                              ),
                                                              const SizedBox(width: 4),
                                                              Expanded(
                                                                child: Text(
                                                                  'Changing this SKU will break external marketing deep links.',
                                                                  style: TextStyle(
                                                                    color: Colors.amber[800],
                                                                    fontSize: 10,
                                                                    fontFamily: 'Inter',
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  flex: 2,
                                                  child: SemanticTextFormField(
                                                    initialValue: variant['price'],
                                                    enabled: isActive,
                                                    textInputAction: TextInputAction.next,
                                                    labelText: 'Price',
                                                    helperText: '0.00',
                                                    prefixWidget: const Text(
                                                      '\$',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.brandEmerald500,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (v) {
                                                      setState(() {
                                                        variant['price'] = v;
                                                      });
                                                      widget.onChanged();
                                                    },
                                                    validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  flex: 2,
                                                  child: SemanticTextFormField(
                                                    initialValue: variant['compare_at_price'],
                                                    enabled: isActive,
                                                    textInputAction: TextInputAction.next,
                                                    labelText: 'Compare At Price',
                                                    helperText: '0.00',
                                                    prefixWidget: const Text(
                                                      '\$',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.brandEmerald500,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (v) {
                                                      variant['compare_at_price'] = v;
                                                      widget.onChanged();
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  flex: 3,
                                                  child: SemanticTextFormField(
                                                    initialValue: variant['barcode'] ?? '',
                                                    enabled: isActive,
                                                    textInputAction: TextInputAction.next,
                                                    labelText: 'Barcode (UPC, EAN, ISBN)',
                                                    helperText: 'Enter product barcode',
                                                    prefixIcon: LucideIcons.barcode,
                                                    onChanged: (v) {
                                                      variant['barcode'] = v;
                                                      widget.onChanged();
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  flex: 2,
                                                  child: SemanticTextFormField(
                                                    initialValue: variant['cost_per_item'] ?? '',
                                                    enabled: isActive,
                                                    textInputAction: TextInputAction.next,
                                                    labelText: 'Cost Per Item',
                                                    helperText: '0.00',
                                                    prefixWidget: const Text(
                                                      '\$',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: AppTheme.brandEmerald500,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (v) {
                                                      variant['cost_per_item'] = v;
                                                      widget.onChanged();
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  flex: 2,
                                                  child: SemanticTextFormField(
                                                    initialValue: variant['stock']?.toString() ?? '',
                                                    enabled: isActive,
                                                    textInputAction: TextInputAction.next,
                                                    labelText: widget.isNewProduct ? 'Initial Stock' : 'Stock',
                                                    helperText: 'e.g., 100',
                                                    prefixIcon: LucideIcons.boxes,
                                                    keyboardType: TextInputType.number,
                                                    onChanged: (v) {
                                                      variant['stock'] = v;
                                                      widget.onChanged();
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                           if (!widget.isDigital) ...[
                                             const SizedBox(height: 16),
                                             const Divider(),
                                             IgnorePointer(
                                               ignoring: !isActive,
                                               child: _buildVariantShippingOverrides(variant),
                                             ),
                                           ],
                                         ],
                                       ),
                                     ),
                                     const SizedBox(width: 24),
                                     // Right Column (40% width)
                                     Expanded(
                                       flex: 2,
                                       child: Column(
                                         crossAxisAlignment: CrossAxisAlignment.start,
                                         children: [
                                           const Text(
                                             'Variant Images',
                                             style: TextStyle(
                                               fontWeight: FontWeight.bold,
                                               fontSize: 13,
                                             ),
                                           ),
                                           const SizedBox(height: 8),
                                           IgnorePointer(
                                             ignoring: !isActive,
                                             child: CompactMediaListUploader(
                                               images: vImages,
                                               uploader: widget.uploader,
                                               onImagesChanged: (newImages) {
                                                 setState(() {
                                                   variant['images'] = newImages;
                                                   if (variant['image_url'] == null ||
                                                       !newImages.contains(variant['image_url'])) {
                                                     variant['image_url'] = newImages.firstOrNull;
                                                   }
                                                 });
                                                 widget.onChanged();
                                               },
                                             ),
                                           ),
                                         ],
                                       ),
                                     ),
                                   ],
                                 ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
  }

  Widget _buildVariantShippingOverrides(Map<String, dynamic> variant) {
    final bool showOverrides = variant['show_shipping_overrides'] ?? false;
    final theme = widget.theme;
    final customInputStyle = theme.textTheme.bodyMedium;
    final customLabelStyle = theme.textTheme.bodySmall;
    final customHintStyle = theme.textTheme.bodyMedium?.copyWith(
      fontStyle: FontStyle.italic,
    );
    const customPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LottieSwitchListTile(
          title: const Text('Override Shipping Specifications'),
          subtitle: const Text(
            "If disabled, this variant inherits the parent product's logistics values. Enable to specify custom dimensions for this specific variant.",
          ),
          value: showOverrides,
          onChanged: (v) {
            setState(() {
              variant['show_shipping_overrides'] = v;
              if (!v) {
                variant['weight_value'] = '';
                variant['length_value'] = '';
                variant['width_value'] = '';
                variant['height_value'] = '';
              }
            });
            widget.onChanged();
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (showOverrides) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: SemanticTextFormField(
                  initialValue: variant['weight_value']?.toString() ?? '',
                  textInputAction: TextInputAction.next,
                  labelText: 'Variant Weight',
                  hintText: 'variant weight',
                  prefixIcon: LucideIcons.scale,
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    variant['weight_value'] = v;
                    widget.onChanged();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: variant['weight_unit'] ?? 'kg',
                  style: customInputStyle,
                  decoration: InputDecoration(
                    labelText: 'Unit',
                    labelStyle: customLabelStyle,
                    border: const OutlineInputBorder(),
                    contentPadding: customPadding,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                    DropdownMenuItem(value: 'lb', child: Text('lb')),
                  ],
                  onChanged: (v) {
                    variant['weight_unit'] = v!;
                    widget.onChanged();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 450;
              return isNarrow
                  ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SemanticTextFormField(
                                initialValue:
                                    variant['length_value']?.toString() ?? '',
                                textInputAction: TextInputAction.next,
                                labelText: 'Variant Length',
                                hintText: 'variant length',
                                prefixIcon: LucideIcons.ruler,
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  variant['length_value'] = v;
                                  widget.onChanged();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SemanticTextFormField(
                                initialValue:
                                    variant['width_value']?.toString() ?? '',
                                textInputAction: TextInputAction.next,
                                labelText: 'Variant Width',
                                hintText: 'variant width',
                                prefixIcon: LucideIcons.ruler,
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  variant['width_value'] = v;
                                  widget.onChanged();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SemanticTextFormField(
                                initialValue:
                                    variant['height_value']?.toString() ?? '',
                                textInputAction: TextInputAction.next,
                                labelText: 'Variant Height',
                                hintText: 'variant height',
                                prefixIcon: LucideIcons.ruler,
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  variant['height_value'] = v;
                                  widget.onChanged();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: variant['dimension_unit'] ?? 'cm',
                                style: customInputStyle,
                                decoration: InputDecoration(
                                  labelText: 'Unit',
                                  labelStyle: customLabelStyle,
                                  border: const OutlineInputBorder(),
                                  contentPadding: customPadding,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'cm',
                                    child: Text('cm'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'in',
                                    child: Text('in'),
                                  ),
                                ],
                                onChanged: (v) {
                                  variant['dimension_unit'] = v!;
                                  widget.onChanged();
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: SemanticTextFormField(
                            initialValue:
                                variant['length_value']?.toString() ?? '',
                            textInputAction: TextInputAction.next,
                            labelText: 'Variant Length',
                            hintText: 'variant length',
                            prefixIcon: LucideIcons.ruler,
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              variant['length_value'] = v;
                              widget.onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SemanticTextFormField(
                            initialValue:
                                variant['width_value']?.toString() ?? '',
                            textInputAction: TextInputAction.next,
                            labelText: 'Variant Width',
                            hintText: 'variant width',
                            prefixIcon: LucideIcons.ruler,
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              variant['width_value'] = v;
                              widget.onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SemanticTextFormField(
                            initialValue:
                                variant['height_value']?.toString() ?? '',
                            textInputAction: TextInputAction.next,
                            labelText: 'Variant Height',
                            hintText: 'variant height',
                            prefixIcon: LucideIcons.ruler,
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              variant['height_value'] = v;
                              widget.onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: variant['dimension_unit'] ?? 'cm',
                            style: customInputStyle,
                            decoration: InputDecoration(
                              labelText: 'Unit',
                              labelStyle: customLabelStyle,
                              border: const OutlineInputBorder(),
                              contentPadding: customPadding,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'cm', child: Text('cm')),
                              DropdownMenuItem(value: 'in', child: Text('in')),
                            ],
                            onChanged: (v) {
                              variant['dimension_unit'] = v!;
                              widget.onChanged();
                            },
                          ),
                        ),
                      ],
                    );
            },
          ),
        ],
      ],
    );
  }
}
