import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/glass_card.dart';
import 'package:kloudshop/widgets/product/option_category_editor.dart';

class ProductOptionsCard extends StatefulWidget {
  final List<Map<String, dynamic>> optionsSchema;
  final VoidCallback onGenerateVariants;
  final VoidCallback onChanged;

  const ProductOptionsCard({
    super.key,
    required this.optionsSchema,
    required this.onGenerateVariants,
    required this.onChanged,
  });

  @override
  State<ProductOptionsCard> createState() => _ProductOptionsCardState();
}

class _ProductOptionsCardState extends State<ProductOptionsCard> {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      title: 'Product Options',
      icon: LucideIcons.sliders,
      color: const Color(0xFF8B5CF6),
      children: [
        const Text(
          'Define variant attributes like Size, Color, or Material. These will be used to generate specific product variants.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        ...widget.optionsSchema.asMap().entries.map((entry) {
          final idx = entry.key;
          final opt = entry.value;
          return OptionCategoryEditor(
            key: ValueKey('opt-$idx-${opt['name']}'),
            option: opt,
            onDelete: () {
              setState(() {
                widget.optionsSchema.removeAt(idx);
              });
              widget.onChanged();
            },
            onChanged: widget.onChanged,
          );
        }),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  widget.optionsSchema.add({'name': '', 'values': <String>[]});
                });
                widget.onChanged();
              },
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add Option Category'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.brandEmerald500,
              ),
            ),
            if (widget.optionsSchema.isNotEmpty)
              ElevatedButton.icon(
                onPressed: widget.onGenerateVariants,
                icon: const Icon(
                  LucideIcons.refreshCw,
                  size: 14,
                  color: Colors.white,
                ),
                label: const Text(
                  'Generate Variants',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.brandEmerald500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
