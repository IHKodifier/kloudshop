import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kloudshop/providers/import_history_provider.dart';

void showImportHistoryPanel(BuildContext context, WidgetRef ref, Offset buttonOffset) {
  ref.read(importHistoryProvider.notifier).markAsViewed();
  
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      
      return Stack(
        children: [
          // Dismiss tap target
          GestureDetector(
            onTap: () => entry.remove(),
            behavior: HitTestBehavior.translucent,
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          
          // Positioned panel card
          Positioned(
            right: 24,
            top: buttonOffset.dy + 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Material(
                  color: isDark
                      ? const Color(0xFF0F172A).withOpacity(0.9)
                      : Colors.white.withOpacity(0.95),
                  elevation: 16,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Container(
                    width: 380,
                    height: 480,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(LucideIcons.history, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Import History',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: () => entry.remove(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        
                        // List
                        Expanded(
                          child: Consumer(
                            builder: (context, ref, child) {
                              final history = ref.watch(importHistoryProvider);
                              
                              if (history.isLoading) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              
                              if (history.errorMessage != null) {
                                return Center(
                                  child: Text(
                                    'Failed to load history: ${history.errorMessage}',
                                    style: const TextStyle(color: Colors.red, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }
                              
                              if (history.jobs.isEmpty) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(LucideIcons.inbox, size: 36, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'No imports in this store yet.',
                                        style: TextStyle(color: Colors.grey, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              
                              return ListView.separated(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemCount: history.jobs.length,
                                separatorBuilder: (context, idx) => const Divider(),
                                itemBuilder: (context, idx) {
                                  final job = history.jobs[idx];
                                  final filename = job['source_filename'] ?? 'import.csv';
                                  final status = job['status'] ?? 'pending';
                                  
                                  // Date
                                  String dateStr = '';
                                  final createdAtStr = job['created_at'] as String?;
                                  if (createdAtStr != null) {
                                    try {
                                      final date = DateTime.parse(createdAtStr);
                                      dateStr = DateFormat('MMM dd, hh:mm a').format(date);
                                    } catch (_) {}
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              filename,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildStatusBadge(status),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            dateStr,
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                          Text(
                                            '${job['rows_processed'] ?? 0} imported · ${job['rows_failed'] ?? 0} failed',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      if (status == 'processing' || status == 'pending') ...[
                                        const SizedBox(height: 6),
                                        const ClipRRect(
                                          borderRadius: BorderRadius.all(Radius.circular(2)),
                                          child: LinearProgressIndicator(minHeight: 2),
                                        ),
                                      ],
                                      if (status == 'successful' || status == 'partial_success' || status == 'failed') ...[
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () {
                                            entry.remove();
                                            _showReportDetailsDialog(context, job);
                                          },
                                          child: Text(
                                            'View Report Summary',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
  
  Overlay.of(context).insert(entry);
}

Widget _buildStatusBadge(String status) {
  Color color = Colors.grey;
  String label = 'Pending';
  
  switch (status) {
    case 'processing':
      color = Colors.blue;
      label = 'Processing';
      break;
    case 'successful':
      color = Colors.green;
      label = 'Success';
      break;
    case 'partial_success':
      color = Colors.amber;
      label = 'Partial';
      break;
    case 'failed':
      color = Colors.red;
      label = 'Failed';
      break;
  }
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withOpacity(0.3), width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (status == 'processing' || status == 'pending') ...[
          _PulsingDot(color: color),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

void _showReportDetailsDialog(BuildContext context, Map<String, dynamic> job) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final errors = List<Map<String, dynamic>>.from(job['error_log'] ?? []);
  
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 550),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Import Report Summary',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'File: ${job['source_filename'] ?? 'import.csv'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Divider(),
              
              // Metric counters
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetric('Total Rows', job['rows_total'] ?? 0),
                  _buildMetric('Imported', job['rows_processed'] ?? 0),
                  _buildMetric('Skipped', job['rows_skipped'] ?? 0),
                  _buildMetric('Failed', job['rows_failed'] ?? 0),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              
              // Error log section
              const SizedBox(height: 12),
              const Text(
                'Validation Log / Warnings:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: errors.isEmpty
                      ? const Center(
                          child: Text('No validation warnings or errors.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: errors.length,
                          itemBuilder: (context, idx) {
                            final err = errors[idx];
                            final row = err['row'] ?? 0;
                            final sku = err['sku'] ?? '';
                            final msg = err['error'] ?? '';
                            final isSkip = err['reason'] == 'skipped_duplicate';

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
                                      msg,
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
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildMetric(String label, int val) {
  return Column(
    children: [
      Text(
        '$val',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
    ],
  );
}
