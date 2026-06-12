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
                width: 700,
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
                    const Icon(LucideIcons.alertTriangle, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${state.duplicateSKUs.length} Duplicate SKUs detected',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
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
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: theme.dividerColor),
                        ),
                        color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : Colors.grey.shade50,
                        child: ExpansionTile(
                          shape: const Border(),
                          initiallyExpanded: true,
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

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    border: Border(top: BorderSide(color: theme.dividerColor)),
                                  ),
                                  child: Row(
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
                                                color: isDuplicate ? Colors.amber.shade700 : null,
                                              ),
                                            ),
                                            if (isDuplicate) ...[
                                              const SizedBox(width: 4),
                                              const Icon(LucideIcons.alertTriangle, size: 12, color: Colors.amber),
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
                                      Text(
                                        '\$$price',
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
      iconColor = Colors.amber;
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
            child: state.errorLog.isEmpty
                ? const Center(
                    child: Text('No validation warnings or errors.', style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: state.errorLog.length,
                    itemBuilder: (context, idx) {
                      final logEntry = state.errorLog[idx];
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
                    },
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
