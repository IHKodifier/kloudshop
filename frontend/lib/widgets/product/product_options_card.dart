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
  /// Called immediately after the user confirms the collapse dialog
  /// (removing the last option value).  The parent should use this to
  /// trigger generateVariantsFromOptions + send the retirement report.
  final VoidCallback? onCollapseConfirmed;

  const ProductOptionsCard({
    super.key,
    required this.optionsSchema,
    this.isGenerating = false,
    required this.onGenerateVariants,
    required this.onChanged,
    this.onCollapseConfirmed,
  });

  @override
  State<ProductOptionsCard> createState() => _ProductOptionsCardState();
}

class _ProductOptionsCardState extends State<ProductOptionsCard> {
  void _confirmCollapse(BuildContext context, VoidCallback onConfirm) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
              SizedBox(width: 12),
              Text(
                'Collapse to Simple Product?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deleting all options will collapse this product back into a single default variant.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 14),
              ),
              SizedBox(height: 8),
              Text(
                '• Custom rates and stock for other variants will be retired.\n'
                '• Active stock counts will be summed up automatically.\n'
                '• A mandatory summary report of the deactivated variants will be sent to your email.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandEmerald500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Confirm Collapse',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

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
        () {
          final colorEntryList = widget.optionsSchema.asMap().entries.where(
            (e) => e.value['name'].toString().trim().toLowerCase() == 'color',
          ).toList();

          final MapEntry<int, Map<String, dynamic>>? colorEntry =
              colorEntryList.isNotEmpty ? colorEntryList.first : null;

          final otherEntries = widget.optionsSchema.asMap().entries.where(
            (e) => colorEntry == null || e.key != colorEntry.key,
          ).toList();

          Widget buildEditor(int idx, Map<String, dynamic> opt) {
            final siblingNames = widget.optionsSchema
                .asMap()
                .entries
                .where((e) => e.key != idx)
                .map((e) => e.value['name'].toString())
                .toList();
            final isColor = opt['name'].toString().trim().toLowerCase() == 'color';

            return OptionCategoryEditor(
              key: ValueKey('opt-$idx-${opt['name']}'),
              option: opt,
              siblingNames: siblingNames,
              onDelete: () {
                final List<Map<String, dynamic>> newSchema;
                if (isColor) {
                  // Clear selected colors instead of removing option category
                  newSchema = widget.optionsSchema.map((m) {
                    if (m['name'].toString().trim().toLowerCase() == 'color') {
                      return {
                        ...m,
                        'values': <String>[],
                      };
                    }
                    return Map<String, dynamic>.from(m);
                  }).toList();
                } else {
                  newSchema = widget.optionsSchema
                      .asMap()
                      .entries
                      .where((e) => e.key != idx)
                      .map((e) => Map<String, dynamic>.from(e.value))
                      .toList();
                }

                final activeOpts = newSchema.where((opt) {
                  final name = (opt['name'] as String? ?? '').trim();
                  final values = List<dynamic>.from(opt['values'] ?? []);
                  return name.isNotEmpty && values.isNotEmpty;
                }).toList();

                final currentActiveOpts = widget.optionsSchema.where((opt) {
                  final name = (opt['name'] as String? ?? '').trim();
                  final values = List<dynamic>.from(opt['values'] ?? []);
                  return name.isNotEmpty && values.isNotEmpty;
                }).toList();

                if (currentActiveOpts.isNotEmpty && activeOpts.isEmpty) {
                  _confirmCollapse(context, () {
                    widget.onChanged(newSchema);
                    widget.onCollapseConfirmed?.call();
                  });
                } else {
                  widget.onChanged(newSchema);
                }
              },
              onChanged: (updatedOpt) {
                final newSchema = widget.optionsSchema
                    .map((m) => Map<String, dynamic>.from(m))
                    .toList();

                // Guard: Color category name is immutable — forcibly restore it
                // even if a UI bypass somehow fires an onChanged with a mutated name.
                final originalName = widget.optionsSchema[idx]['name']
                    .toString()
                    .trim()
                    .toLowerCase();
                if (originalName == 'color') {
                  updatedOpt = Map<String, dynamic>.from(updatedOpt)
                    ..['name'] = 'Color';
                }

                newSchema[idx] = updatedOpt;

                final activeOpts = newSchema.where((opt) {
                  final name = (opt['name'] as String? ?? '').trim();
                  final values = List<dynamic>.from(opt['values'] ?? []);
                  return name.isNotEmpty && values.isNotEmpty;
                }).toList();

                final currentActiveOpts = widget.optionsSchema.where((opt) {
                  final name = (opt['name'] as String? ?? '').trim();
                  final values = List<dynamic>.from(opt['values'] ?? []);
                  return name.isNotEmpty && values.isNotEmpty;
                }).toList();

                if (currentActiveOpts.isNotEmpty && activeOpts.isEmpty) {
                  _confirmCollapse(context, () {
                    widget.onChanged(newSchema);
                    widget.onCollapseConfirmed?.call();
                  });
                } else {
                  widget.onChanged(newSchema);
                }
              },
            );
          }

          final isDesktop = MediaQuery.of(context).size.width >= 900;
          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (colorEntry != null)
                        buildEditor(colorEntry.key, colorEntry.value)
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: otherEntries
                        .map((e) => buildEditor(e.key, e.value))
                        .toList(),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (colorEntry != null) ...[
                  buildEditor(colorEntry.key, colorEntry.value),
                  const SizedBox(height: 16),
                ],
                ...otherEntries.map((e) => buildEditor(e.key, e.value)),
              ],
            );
          }
        }(),
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
