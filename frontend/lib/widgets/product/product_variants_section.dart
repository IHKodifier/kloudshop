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
  final ValueChanged<int> onRemoveVariant;
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
    required this.onRemoveVariant,
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
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.variants.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final variant = widget.variants[index];
            final Map<String, String> optionVals = Map<String, String>.from(
              variant['option_values'] ?? {},
            );
            final bool isExpanded = variant['is_expanded'] ?? false;

            final customInputStyle = theme.textTheme.bodyMedium;
            final customLabelStyle = theme.textTheme.bodySmall;
            const customPadding = EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            );

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
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (newVal) {
                        setState(() {
                          optionVals[name] = newVal!;
                          variant['option_values'] = optionVals;
                        });
                        widget.onChanged();
                      },
                    ),
                  ),
                );
                optionDropdowns.add(const SizedBox(width: 12));
              }
            }

            final List<String> vImages = List<String>.from(
              variant['images'] ?? [],
            );

            return AnimatedContainer(
              duration: const Duration(milliseconds: 25),
              curve: Curves.easeOut,
              padding: isExpanded
                  ? const EdgeInsets.all(20)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
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
                          Icon(
                            isExpanded
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 20,
                            color: AppTheme.brandEmerald500,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    optionVals.isEmpty
                                        ? 'Default Variant'
                                        : optionVals.entries
                                              .map((e) => e.value)
                                              .join(' / '),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
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
                                        borderRadius: BorderRadius.circular(4),
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
                          const SizedBox(width: 16),
                          Text(
                            variant['price']?.toString().isNotEmpty == true
                                ? '\$${variant['price']}'
                                : '\$0.00',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandEmerald500,
                            ),
                          ),
                          if (widget.variants.length > 1) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(
                                LucideIcons.trash2,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => widget.onRemoveVariant(index),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  AnimatedSize(
                    duration: const Duration(milliseconds: 600),
                    curve: const ElasticOutCurve(0.25),
                    alignment: Alignment.topCenter,
                    child: isExpanded
                        ? Column(
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
                                      initialValue: variant['compare_at_price'],
                                      style: customInputStyle,
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
                                        decoration: InputDecoration(
                                          labelText: 'Initial Stock Inventory',
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
                              CompactMediaListUploader(
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

                              // Shipping Overrides Section
                              if (!widget.isDigital) ...[
                                const Divider(height: 24),
                                _buildVariantShippingOverrides(variant),
                              ],
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildVariantShippingOverrides(Map<String, dynamic> variant) {
    final bool showOverrides = variant['show_shipping_overrides'] ?? false;
    final theme = Theme.of(context);
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
