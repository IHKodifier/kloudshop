import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/glass_card.dart';
import 'package:kloudshop/widgets/product/option_category_editor.dart';

class ProductOptionsCard extends StatefulWidget {
  final List<Map<String, dynamic>> optionsSchema;
  final bool isGenerating;
  final VoidCallback onGenerateVariants;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  const ProductOptionsCard({
    super.key,
    required this.optionsSchema,
    this.isGenerating = false,
    required this.onGenerateVariants,
    required this.onChanged,
  });

  @override
  State<ProductOptionsCard> createState() => _ProductOptionsCardState();
}

class _ProductOptionsCardState extends State<ProductOptionsCard> {
  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Add Option Category',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Size, Material',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Category name is required';
                    }
                    final normalized = v.trim().toLowerCase();
                    if (widget.optionsSchema.any((opt) => opt['name'].toString().trim().toLowerCase() == normalized)) {
                      return 'This category name already exists';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final name = nameController.text.trim();

                final newSchema = widget.optionsSchema
                    .map((m) => Map<String, dynamic>.from(m))
                    .toList()
                  ..add({
                    'name': name,
                    'values': <String>[],
                  });
                widget.onChanged(newSchema);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandEmerald500,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

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
          final siblingNames = widget.optionsSchema
              .asMap()
              .entries
              .where((e) => e.key != idx)
              .map((e) => e.value['name'].toString())
              .toList();
          return OptionCategoryEditor(
            key: ValueKey('opt-$idx-${opt['name']}'),
            option: opt,
            siblingNames: siblingNames,
            onDelete: () {
              final newSchema = widget.optionsSchema
                  .asMap()
                  .entries
                  .where((e) => e.key != idx)
                  .map((e) => Map<String, dynamic>.from(e.value))
                  .toList();
              widget.onChanged(newSchema);
            },
            onChanged: (updatedOpt) {
              final newSchema = widget.optionsSchema
                  .map((m) => Map<String, dynamic>.from(m))
                  .toList();
              newSchema[idx] = updatedOpt;
              widget.onChanged(newSchema);
            },
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
              onPressed: () => _showAddCategoryDialog(context),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Add Option Category'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.brandEmerald500,
              ),
            ),
            if (widget.optionsSchema.isNotEmpty)
              ElevatedButton.icon(
                onPressed: widget.isGenerating ? null : widget.onGenerateVariants,
                icon: widget.isGenerating
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        LucideIcons.refreshCw,
                        size: 14,
                        color: Colors.white,
                      ),
                label: Text(
                  widget.isGenerating ? 'Generating...' : 'Generate Variants',
                  style: const TextStyle(color: Colors.white),
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
