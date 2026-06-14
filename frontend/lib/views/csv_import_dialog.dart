import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:kloudshop/providers/csv_import_provider.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/utils/download_helper/download_helper.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';


void showCsvImportDialog(BuildContext context, WidgetRef ref) {
  ref.read(csvImportProvider.notifier).reset();
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss CSV Import',
    barrierColor: Colors.black.withOpacity(0.65),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, anim1, anim2) {
      return Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0F172A).withOpacity(0.85)
                  : Colors.white.withOpacity(0.9),
              child: Container(
                width: 950,
                height: 620,
                padding: const EdgeInsets.all(24),
                child: const CsvImportWizard(),
              ),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (context, anim1, anim2, child) {
      return FadeTransition(
        opacity: anim1,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: child,
        ),
      );
    },
  );
}

class CsvImportWizard extends ConsumerStatefulWidget {
  const CsvImportWizard({super.key});

  @override
  ConsumerState<CsvImportWizard> createState() => _CsvImportWizardState();
}

class _CsvImportWizardState extends ConsumerState<CsvImportWizard> {
  bool _isDragging = false;
  bool _isDownloadingTemplate = false;
  final Set<String> _collapsedHandles = {};

  List<String> _getRowErrors(Map<String, dynamic> variant, {required bool isFirstRow}) {
    final errors = <String>[];
    final handle = variant['Handle']?.trim() ?? '';
    final title = variant['Title']?.trim() ?? '';
    final sku = variant['SKU']?.trim() ?? '';
    final priceStr = variant['Price']?.trim() ?? '';
    final comparePriceStr = variant['Compare At Price']?.trim() ?? '';

    // 1. Handle and Title required for the first row of a product group
    if (isFirstRow) {
      if (handle.isEmpty && title.isEmpty) {
        errors.add('Missing Handle and Title');
      } else if (handle.isEmpty) {
        errors.add('Missing Handle');
      } else if (title.isEmpty) {
        errors.add('Missing Title');
      }
    }

    // 2. SKU required
    if (sku.isEmpty) {
      errors.add('Missing SKU');
    }

    // 3. Price required and must be valid non-negative number
    if (priceStr.isEmpty) {
      errors.add('Missing Price');
    } else {
      final priceVal = double.tryParse(priceStr);
      if (priceVal == null) {
        errors.add('error: invalid price');
      } else if (priceVal < 0) {
        errors.add('error: price cannot be negative');
      }
    }

    // 4. Compare At Price validation
    if (comparePriceStr.isNotEmpty) {
      final compareVal = double.tryParse(comparePriceStr);
      final priceVal = double.tryParse(priceStr);
      if (compareVal == null) {
        errors.add('error: invalid price');
      } else if (priceVal != null && compareVal <= priceVal) {
        errors.add('error: price cannot be less than compare at price');
      }
    }

    return errors;
  }

  Future<void> _handleFileSelection(List<int> bytes, String filename) async {
    final notifier = ref.read(csvImportProvider.notifier);
    await notifier.handleFilePicked(Uint8List.fromList(bytes), filename);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );
    if (result != null && result.files.single.bytes != null) {
      await _handleFileSelection(
        result.files.single.bytes!,
        result.files.single.name,
      );
    }
  }

  Future<void> _downloadTemplate() async {
    setState(() => _isDownloadingTemplate = true);
    try {
      final apiService = ref.read(apiServiceProvider);
      final bytes = await apiService.downloadCsvTemplate();
      await saveFile(bytes, 'kloudshop_import_template.csv');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template downloaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download template: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingTemplate = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(csvImportProvider);
    final theme = Theme.of(context);

    if (state.step == CsvImportStep.idle) {
      _collapsedHandles.clear();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title block
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.fileSpreadsheet,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Bulk Product Import',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(LucideIcons.x),
              onPressed: state.step == CsvImportStep.uploading ||
                      state.step == CsvImportStep.polling
                  ? null
                  : () {
                      ref.read(csvImportProvider.notifier).cancelPolling();
                      Navigator.of(context).pop();
                    },
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),

        // Dialog Content Wizard Steps
        Expanded(
          child: _buildStepContent(state),
        ),

        // Bottom Actions
        if (state.step != CsvImportStep.uploading &&
            state.step != CsvImportStep.polling) ...[
          const Divider(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (state.step == CsvImportStep.preview) ...[
                TextButton(
                  onPressed: () => ref.read(csvImportProvider.notifier).reset(),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    // Check duplicate custom SKU validation before proceed
                    if (state.conflictStrategy == ConflictStrategy.customSku) {
                      final values = state.customSkuMap.values.toSet();
                      if (values.contains('') || values.length != state.duplicateSKUs.length) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a unique new SKU for all duplicates.')),
                        );
                        return;
                      }
                    }
                    ref.read(csvImportProvider.notifier).upload();
                  },
                  icon: const Icon(LucideIcons.uploadCloud, size: 16, color: Colors.white),
                  label: const Text('Start Import', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ] else if (state.step == CsvImportStep.done ||
                  state.step == CsvImportStep.error) ...[
                ElevatedButton(
                  onPressed: () {
                    ref.read(csvImportProvider.notifier).cancelPolling();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: () {
                    ref.read(csvImportProvider.notifier).cancelPolling();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStepContent(CsvImportState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    switch (state.step) {
      case CsvImportStep.idle:
        return DropTarget(
          onDragEntered: (detail) => setState(() => _isDragging = true),
          onDragExited: (detail) => setState(() => _isDragging = false),
          onDragDone: (detail) async {
            setState(() => _isDragging = false);
            if (detail.files.isNotEmpty) {
              final file = detail.files.first;
              final bytes = await file.readAsBytes();
              await _handleFileSelection(bytes, file.name);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: _isDragging
                  ? theme.colorScheme.primary.withOpacity(0.08)
                  : isDark
                      ? const Color(0xFF1E293B).withOpacity(0.4)
                      : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isDragging
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.5),
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.uploadCloud,
                  size: 48,
                  color: _isDragging
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Drag & Drop CSV or XLSX file here',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'or browse files on your computer',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                HoverScale(
                  child: ElevatedButton(
                    onPressed: _pickFile,
                    child: const Text('Browse Files'),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.download, size: 16),
                    const SizedBox(width: 8),
                    _isDownloadingTemplate
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : InkWell(
                            onTap: _downloadTemplate,
                            child: Text(
                              'Download CSV Import Template',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tip: Unlimited options dimensions are dynamically parsed.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );

      case CsvImportStep.parsing:
      case CsvImportStep.conflictCheck:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzing file format and duplicates...'),
            ],
          ),
        );

      case CsvImportStep.preview:
        return _buildPreviewStep(state);

      case CsvImportStep.uploading:
      case CsvImportStep.polling:
        return _buildProgressStep(state);

      case CsvImportStep.done:
        return _buildDoneStep(state);

      case CsvImportStep.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Import Error',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  state.errorMessage ?? 'An unknown error occurred.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildPreviewStep(CsvImportState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final warningColor = isDark ? Colors.amber.shade300 : Colors.amber.shade900;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Duplicate warning banner if any duplicates
        if (state.duplicateSKUs.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade700.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.alertTriangle, color: warningColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${state.duplicateSKUs.length} Duplicate SKUs detected',
                      style: TextStyle(fontWeight: FontWeight.bold, color: warningColor),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select a strategy to resolve conflicts with your existing catalog:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Radio<ConflictStrategy>(
                      value: ConflictStrategy.skip,
                      groupValue: state.conflictStrategy,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(csvImportProvider.notifier).setStrategy(val);
                        }
                      },
                    ),
                    const Text('Skip Duplicates'),
                    const SizedBox(width: 16),
                    Radio<ConflictStrategy>(
                      value: ConflictStrategy.overwrite,
                      groupValue: state.conflictStrategy,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(csvImportProvider.notifier).setStrategy(val);
                        }
                      },
                    ),
                    const Text('Overwrite Existing'),
                    const SizedBox(width: 16),
                    Radio<ConflictStrategy>(
                      value: ConflictStrategy.customSku,
                      groupValue: state.conflictStrategy,
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(csvImportProvider.notifier).setStrategy(val);
                        }
                      },
                    ),
                    const Text('Rename SKU on-the-fly'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Rename fields list if Rename strategy selected
        if (state.conflictStrategy == ConflictStrategy.customSku &&
            state.duplicateSKUs.isNotEmpty) ...[
          const Text(
            'Provide custom SKUs:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.duplicateSKUs.length,
              itemBuilder: (context, idx) {
                final origSku = state.duplicateSKUs[idx];
                final currentNew = state.customSkuMap[origSku] ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          origSku,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(LucideIcons.arrowRight, size: 14, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: SizedBox(
                          height: 32,
                          child: TextField(
                            controller: TextEditingController(text: currentNew)
                              ..selection = TextSelection.fromPosition(
                                TextPosition(offset: currentNew.length),
                              ),
                            onChanged: (val) {
                              ref
                                  .read(csvImportProvider.notifier)
                                  .setCustomSku(origSku, val);
                            },
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 0,
                              ),
                              hintText: 'New unique SKU',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Grouped preview grid
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Grouped Products Preview (${state.productGroups.length} items)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'File: ${state.filename}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.productGroups.length,
                    itemBuilder: (context, pIdx) {
                      final group = state.productGroups[pIdx];
                      final hasGroupError = group.variantRows.asMap().entries.any((entry) {
                        return _getRowErrors(entry.value, isFirstRow: entry.key == 0).isNotEmpty;
                      });

                      return Card(
                        key: ValueKey('card_${group.handle}'),
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: hasGroupError ? theme.colorScheme.error : theme.dividerColor,
                            width: hasGroupError ? 1.5 : 1.0,
                          ),
                        ),
                        color: hasGroupError
                            ? (isDark
                                ? theme.colorScheme.error.withOpacity(0.06)
                                : theme.colorScheme.error.withOpacity(0.03))
                            : (isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.grey.shade50),
                        child: ExpansionTile(
                          key: ValueKey('tile_${group.handle}'),
                          shape: const Border(),
                          initiallyExpanded: !_collapsedHandles.contains(group.handle),
                          onExpansionChanged: (isExpanded) {
                            setState(() {
                              if (isExpanded) {
                                _collapsedHandles.remove(group.handle);
                              } else {
                                _collapsedHandles.add(group.handle);
                              }
                            });
                          },
                          trailing: CardDrawerExpansionIcon(
                            key: ValueKey('icon_${group.handle}'),
                            isExpanded: !_collapsedHandles.contains(group.handle),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.title.isNotEmpty ? group.title : 'Untitled Product',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    Text(
                                      'Handle: ${group.handle}',
                                      style: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (hasGroupError) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.alertCircle,
                                        size: 11,
                                        color: theme.colorScheme.onErrorContainer,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Error',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onErrorContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${group.variantRows.length} Variants',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          children: [
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: group.variantRows.length,
                              itemBuilder: (context, vIdx) {
                                final variant = group.variantRows[vIdx];
                                final sku = variant['SKU']?.trim() ?? '';
                                final price = variant['Price']?.trim() ?? '0.00';
                                final stock = variant['Stock']?.trim() ?? 'No stock';
                                
                                // Dynamic option parsing
                                final options = <String>[];
                                for (var k = 1; k < 10; k++) {
                                  final name = variant['Option$k Name']?.trim() ?? '';
                                  final val = variant['Option$k Value']?.trim() ?? '';
                                  if (name.isNotEmpty && val.isNotEmpty) {
                                    options.add('$name: $val');
                                  }
                                }

                                final isDuplicate = state.duplicateSKUs.contains(sku);
                                final compareAt = variant['Compare At Price']?.trim() ?? '';

                                final rowErrors = _getRowErrors(variant, isFirstRow: vIdx == 0);
                                final hasRowError = rowErrors.isNotEmpty;

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: hasRowError
                                        ? (isDark
                                            ? Colors.red.withOpacity(0.12)
                                            : Colors.red.withOpacity(0.06))
                                        : null,
                                    border: Border(top: BorderSide(color: theme.dividerColor)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                Text(
                                                  sku.isNotEmpty ? sku : '[No SKU]',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 13,
                                                    color: sku.isEmpty
                                                        ? theme.colorScheme.error
                                                        : (isDuplicate ? warningColor : null),
                                                  ),
                                                ),
                                                if (isDuplicate) ...[
                                                  const SizedBox(width: 4),
                                                  Icon(LucideIcons.alertTriangle, size: 12, color: warningColor),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Wrap(
                                              spacing: 4,
                                              runSpacing: 2,
                                              children: options.map((opt) {
                                                return Chip(
                                                  label: Text(opt, style: const TextStyle(fontSize: 10)),
                                                  padding: EdgeInsets.zero,
                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                          if (compareAt.isNotEmpty) ...[
                                            Text(
                                              '\$$compareAt',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: rowErrors.any((e) => e.toLowerCase().contains('compare'))
                                                    ? theme.colorScheme.error
                                                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                                                decoration: TextDecoration.lineThrough,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(
                                            '\$$price',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: rowErrors.any((e) => e.toLowerCase().contains('price'))
                                                  ? theme.colorScheme.error
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Text(
                                            'Stock: $stock',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: stock.startsWith('No') ? Colors.orange : Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (hasRowError) ...[
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(
                                              LucideIcons.alertCircle,
                                              size: 12,
                                              color: theme.colorScheme.error,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                rowErrors.join(', '),
                                                style: TextStyle(
                                                  color: theme.colorScheme.error,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStep(CsvImportState state) {
    final theme = Theme.of(context);
    final value = state.rowsTotal > 0 ? (state.rowsProcessed + state.rowsSkipped + state.rowsFailed) / state.rowsTotal : 0.0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.cloudUpload, size: 48, color: Colors.blue),
          const SizedBox(height: 20),
          Text(
            state.step == CsvImportStep.uploading ? 'Uploading import file...' : 'Processing background job...',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${(value * 100).toInt()}% completed (${state.rowsProcessed + state.rowsSkipped + state.rowsFailed}/${state.rowsTotal} rows)',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProgressCounter('Processed', state.rowsProcessed, Colors.green),
              const SizedBox(width: 24),
              _buildProgressCounter('Skipped', state.rowsSkipped, Colors.amber),
              const SizedBox(width: 24),
              _buildProgressCounter('Failed', state.rowsFailed, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCounter(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDoneStep(CsvImportState state) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final isSuccessful = state.jobStatus == 'successful';
    final isPartial = state.jobStatus == 'partial_success';

    Color bannerColor = Colors.red.withOpacity(0.08);
    Color borderColor = Colors.red.withOpacity(0.3);
    IconData icon = LucideIcons.xCircle;
    Color iconColor = Colors.red;
    String title = 'Import Failed';
    String message = 'All rows failed to import. Review the logs below.';

    if (isSuccessful) {
      bannerColor = AppTheme.brandEmerald500.withOpacity(isDark ? 0.15 : 0.08);
      borderColor = AppTheme.brandEmerald600.withOpacity(0.3);
      icon = LucideIcons.checkCircle2;
      iconColor = AppTheme.brandEmerald500;
      title = 'Import Successful';
      message = 'All rows successfully imported. Report has been emailed to you.';
    } else if (isPartial) {
      bannerColor = Colors.amber.withOpacity(isDark ? 0.15 : 0.08);
      borderColor = Colors.amber.shade700.withOpacity(0.3);
      icon = LucideIcons.alertTriangle;
      iconColor = isDark ? Colors.amber.shade300 : Colors.amber.shade900;
      title = 'Import Partially Successful';
      message = 'Some rows imported successfully, while others failed or were skipped.';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bannerColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontWeight: FontWeight.bold, color: iconColor, fontSize: 15),
                    ),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryMetric('Total Rows', state.rowsTotal),
            _buildSummaryMetric('Imported', state.rowsProcessed),
            _buildSummaryMetric('Skipped', state.rowsSkipped),
            _buildSummaryMetric('Failed', state.rowsFailed),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Error Log / Validation Warnings:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor),
            ),
            child: (state.errorLog.isEmpty && state.noStockLog.isEmpty)
                ? const Center(
                    child: Text('No validation warnings or errors.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      if (state.errorLog.isNotEmpty) ...[
                        const Text(
                          'Errors & Skipped Rows:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                        ),
                        const SizedBox(height: 6),
                        ...state.errorLog.map((logEntry) {
                          final row = logEntry['row'] ?? 0;
                          final sku = logEntry['sku'] ?? '';
                          final err = logEntry['error'] ?? '';
                          final isSkip = logEntry['reason'] == 'skipped_duplicate';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Row $row: ',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                if (sku.isNotEmpty)
                                  Text(
                                    '[$sku] ',
                                    style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                                  ),
                                Expanded(
                                  child: Text(
                                    err,
                                    style: TextStyle(
                                      color: isSkip ? Colors.amber.shade700 : Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        if (state.noStockLog.isNotEmpty) const SizedBox(height: 16),
                      ],
                      if (state.noStockLog.isNotEmpty) ...[
                        Row(
                          children: [
                            Icon(LucideIcons.alertTriangle, size: 14, color: Colors.orange.shade800),
                            const SizedBox(width: 6),
                            Text(
                              'Products Without Stock (Seeded with 0 stock):',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.orange.shade800),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...state.noStockLog.map((warnEntry) {
                          final handle = warnEntry['handle'] ?? '';
                          final sku = warnEntry['sku'] ?? '';
                          final title = warnEntry['title'] ?? '';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(LucideIcons.info, size: 12, color: Colors.orange.shade600),
                                const SizedBox(width: 6),
                                if (sku.isNotEmpty)
                                  Text(
                                    '[$sku] ',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                Expanded(
                                  child: Text(
                                    '$title ($handle) — no stock specified. Initial inventory set to 0.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryMetric(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class CardDrawerExpansionIcon extends StatelessWidget {
  final bool isExpanded;

  const CardDrawerExpansionIcon({super.key, required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final neutralColor = theme.colorScheme.onSurfaceVariant.withOpacity(0.7);

    if (isExpanded) {
      // Expanded state (nothing to expand, only to collapse) -> Grey minus.
      return SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: neutralColor,
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Horizontal bar
                Container(
                  width: 12,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: neutralColor,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Collapsed state (something to expand) -> Solid green circle with white '+'
      return SizedBox(
        width: 30,
        height: 30,
        child: Center(
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Horizontal bar
                Container(
                  width: 12,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                // Vertical bar
                Container(
                  width: 1.5,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
