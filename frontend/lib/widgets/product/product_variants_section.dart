import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:kloudshop/widgets/upload/compact_media_list_uploader.dart';
import 'package:kloudshop/services/file_uploader.dart';

class ProductVariantsSection extends StatefulWidget {
  final List<Map<String, dynamic>> variants;
  final List<Map<String, dynamic>> optionsSchema;
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
                  'Variants & Pricing (${widget.variants.length})',
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
            final activeVariants = widget.variants
                .where((v) => v['is_active'] ?? true)
                .toList();
            final inactiveVariants = widget.variants
                .where((v) => !(v['is_active'] ?? true))
                .toList();
            final sortedVariants = [...activeVariants, ...inactiveVariants];

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedVariants.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final variant = sortedVariants[index];
                // Unique key based on ID, SKU, and active state to trigger transition when reordered
                final keyString =
                    '${variant['variant_id'] ?? ''}_${variant['sku'] ?? ''}_${variant['is_active'] ?? true}';

                return _VariantItemCard(
                  key: ValueKey(keyString),
                  variant: variant,
                  optionsSchema: widget.optionsSchema,
                  isNewProduct: widget.isNewProduct,
                  isDigital: widget.isDigital,
                  uploader: widget.uploader,
                  isDark: isDark,
                  theme: theme,
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
                        final firstActive = widget.variants
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
                        final hasActiveDefault = widget.variants.any(
                          (v) =>
                              (v['is_active'] ?? true) &&
                              (v['is_default'] ?? false),
                        );
                        if (!hasActiveDefault) {
                          for (var v in widget.variants) {
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
  final bool isNewProduct;
  final bool isDigital;
  final FileUploader uploader;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onChanged;
  final ValueChanged<bool> onToggleActive;

  const _VariantItemCard({
    super.key,
    required this.variant,
    required this.optionsSchema,
    required this.isNewProduct,
    required this.isDigital,
    required this.uploader,
    required this.isDark,
    required this.theme,
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

    // Build dynamic option dropdowns
    final List<Widget> optionDropdowns = [];
    for (var opt in widget.optionsSchema) {
      final String name = opt['name'];
      final List<String> vals = List<String>.from(opt['values']);
      if (name.isNotEmpty && vals.isNotEmpty) {
        if (!vals.contains(optionVals[name])) {
          optionVals[name] = vals.first;
          variant['option_values'] = optionVals;
        }
        optionDropdowns.add(
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: optionVals[name],
              style: customInputStyle,
              decoration: InputDecoration(
                labelText: name,
                labelStyle: customLabelStyle,
                border: const OutlineInputBorder(),
                contentPadding: customPadding,
              ),
              items: vals
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: isActive
                  ? (newVal) {
                      setState(() {
                        optionVals[name] = newVal!;
                        variant['option_values'] = optionVals;
                      });
                      widget.onChanged();
                    }
                  : null,
            ),
          ),
        );
        optionDropdowns.add(const SizedBox(width: 12));
      }
    }

    final List<String> vImages = List<String>.from(variant['images'] ?? []);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: isExpanded
          ? const EdgeInsets.all(20)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive
            ? (isDark ? const Color(0xFF1E293B) : Colors.white)
            : (isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                  : Colors.grey[50]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? theme.dividerColor
              : theme.dividerColor.withValues(alpha: 0.5),
          width: isActive ? 1.0 : 0.8,
        ),
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
                                    child: Text(
                                      optionVals.isEmpty
                                          ? 'Default Variant'
                                          : optionVals.entries
                                                .map((e) => e.value)
                                                .join(' / '),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        decoration: isActive
                                            ? null
                                            : TextDecoration.lineThrough,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (variant['sku']?.toString().isNotEmpty ==
                                      true) ...[
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
                          _LottieToggle(
                            value: isActive,
                            onChanged: _handleToggle,
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
                                if (optionDropdowns.isNotEmpty) ...[
                                  Row(children: optionDropdowns),
                                  const SizedBox(height: 12),
                                ],
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        initialValue: variant['sku'],
                                        style: customInputStyle,
                                        enabled: isActive,
                                        decoration: InputDecoration(
                                          labelText: 'SKU',
                                          labelStyle: customLabelStyle,
                                          border: const OutlineInputBorder(),
                                          contentPadding: customPadding,
                                        ),
                                        onChanged: (v) {
                                          variant['sku'] = v;
                                          widget.onChanged();
                                        },
                                        validator: (v) => v?.isEmpty == true
                                            ? 'Required'
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        initialValue: variant['price'],
                                        style: customInputStyle,
                                        enabled: isActive,
                                        decoration: InputDecoration(
                                          labelText: 'Price',
                                          labelStyle: customLabelStyle,
                                          prefixText: '\$',
                                          prefixStyle: customInputStyle,
                                          border: const OutlineInputBorder(),
                                          contentPadding: customPadding,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) {
                                          setState(() {
                                            variant['price'] = v;
                                          });
                                          widget.onChanged();
                                        },
                                        validator: (v) =>
                                            double.tryParse(v ?? '') == null
                                            ? 'Invalid'
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 2,
                                      child: TextFormField(
                                        initialValue:
                                            variant['compare_at_price'],
                                        style: customInputStyle,
                                        enabled: isActive,
                                        decoration: InputDecoration(
                                          labelText: 'Compare At',
                                          labelStyle: customLabelStyle,
                                          prefixText: '\$',
                                          prefixStyle: customInputStyle,
                                          border: const OutlineInputBorder(),
                                          contentPadding: customPadding,
                                        ),
                                        keyboardType: TextInputType.number,
                                        onChanged: (v) {
                                          variant['compare_at_price'] = v;
                                          widget.onChanged();
                                        },
                                      ),
                                    ),
                                    if (widget.isNewProduct) ...[
                                      const SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: TextFormField(
                                          initialValue: variant['stock'],
                                          style: customInputStyle,
                                          enabled: isActive,
                                          decoration: InputDecoration(
                                            labelText:
                                                'Initial Stock Inventory',
                                            labelStyle: customLabelStyle,
                                            border: const OutlineInputBorder(),
                                            contentPadding: customPadding,
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) {
                                            variant['stock'] = v;
                                            widget.onChanged();
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),

                                // Media Section for Variant
                                const SizedBox(height: 16),
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
                                            !newImages.contains(
                                              variant['image_url'],
                                            )) {
                                          variant['image_url'] =
                                              newImages.firstOrNull;
                                        }
                                      });
                                      widget.onChanged();
                                    },
                                  ),
                                ),

                                // Shipping Overrides Section
                                if (!widget.isDigital) ...[
                                  const Divider(height: 24),
                                  IgnorePointer(
                                    ignoring: !isActive,
                                    child: _buildVariantShippingOverrides(
                                      variant,
                                    ),
                                  ),
                                ],
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
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  variant['show_shipping_overrides'] = !showOverrides;
                });
              },
              icon: Icon(
                showOverrides ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
                color: AppTheme.brandEmerald500,
              ),
              label: Text(
                showOverrides
                    ? 'Hide Shipping Overrides'
                    : 'Configure Shipping Overrides',
                style: const TextStyle(
                  color: AppTheme.brandEmerald500,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (showOverrides) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: variant['weight_value']?.toString() ?? '',
                  style: customInputStyle,
                  decoration: InputDecoration(
                    labelText: 'Variant Weight',
                    labelStyle: customLabelStyle,
                    hintText: 'variant weight',
                    hintStyle: customHintStyle,
                    border: const OutlineInputBorder(),
                    contentPadding: customPadding,
                  ),
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
                              child: TextFormField(
                                initialValue:
                                    variant['length_value']?.toString() ?? '',
                                style: customInputStyle,
                                decoration: InputDecoration(
                                  labelText: 'Variant Length',
                                  labelStyle: customLabelStyle,
                                  hintText: 'variant length',
                                  hintStyle: customHintStyle,
                                  border: const OutlineInputBorder(),
                                  contentPadding: customPadding,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  variant['length_value'] = v;
                                  widget.onChanged();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue:
                                    variant['width_value']?.toString() ?? '',
                                style: customInputStyle,
                                decoration: InputDecoration(
                                  labelText: 'Variant Width',
                                  labelStyle: customLabelStyle,
                                  hintText: 'variant width',
                                  hintStyle: customHintStyle,
                                  border: const OutlineInputBorder(),
                                  contentPadding: customPadding,
                                ),
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
                              child: TextFormField(
                                initialValue:
                                    variant['height_value']?.toString() ?? '',
                                style: customInputStyle,
                                decoration: InputDecoration(
                                  labelText: 'Variant Height',
                                  labelStyle: customLabelStyle,
                                  hintText: 'variant height',
                                  hintStyle: customHintStyle,
                                  border: const OutlineInputBorder(),
                                  contentPadding: customPadding,
                                ),
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
                          child: TextFormField(
                            initialValue:
                                variant['length_value']?.toString() ?? '',
                            style: customInputStyle,
                            decoration: InputDecoration(
                              labelText: 'Variant Length',
                              labelStyle: customLabelStyle,
                              hintText: 'variant length',
                              hintStyle: customHintStyle,
                              border: const OutlineInputBorder(),
                              contentPadding: customPadding,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              variant['length_value'] = v;
                              widget.onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue:
                                variant['width_value']?.toString() ?? '',
                            style: customInputStyle,
                            decoration: InputDecoration(
                              labelText: 'Variant Width',
                              labelStyle: customLabelStyle,
                              hintText: 'variant width',
                              hintStyle: customHintStyle,
                              border: const OutlineInputBorder(),
                              contentPadding: customPadding,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              variant['width_value'] = v;
                              widget.onChanged();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue:
                                variant['height_value']?.toString() ?? '',
                            style: customInputStyle,
                            decoration: InputDecoration(
                              labelText: 'Variant Height',
                              labelStyle: customLabelStyle,
                              hintText: 'variant height',
                              hintStyle: customHintStyle,
                              border: const OutlineInputBorder(),
                              contentPadding: customPadding,
                            ),
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

class _LottieToggle extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LottieToggle({required this.value, required this.onChanged});

  @override
  State<_LottieToggle> createState() => _LottieToggleState();
}

class _LottieToggleState extends State<_LottieToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
    _controller.value = widget.value ? 0.5 : 0.0;
    _initialized = true;
  }

  @override
  void didUpdateWidget(_LottieToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && _initialized) {
      if (widget.value) {
        if (_controller.value >= 0.9) {
          _controller.value = 0.0;
        }
        _controller.animateTo(
          0.5,
          duration: const Duration(milliseconds: 1800),
        );
      } else {
        if (_controller.value <= 0.1) {
          _controller.value = 0.5;
        }
        _controller.animateTo(
          1.0,
          duration: const Duration(milliseconds: 1800),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isAnimating) return;

    final bool nextVal = !widget.value;
    if (nextVal) {
      if (_controller.value >= 0.9) {
        _controller.value = 0.0;
      }
      _controller.animateTo(
        0.5,
        duration: const Duration(milliseconds: 1800),
      ).then((_) {
        if (mounted) {
          widget.onChanged(true);
        }
      });
    } else {
      if (_controller.value <= 0.1) {
        _controller.value = 0.5;
      }
      _controller.animateTo(
        1.0,
        duration: const Duration(milliseconds: 1800),
      ).then((_) {
        if (mounted) {
          widget.onChanged(false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: 66,
          height: 30,
          child: ClipRect(
            child: OverflowBox(
              minWidth: 84,
              maxWidth: 84,
              minHeight: 63,
              maxHeight: 63,
              child: Lottie.asset(
                'assets/68be063a-1151-11ee-9102-1b5da2d32f76.json',
                controller: _controller,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
