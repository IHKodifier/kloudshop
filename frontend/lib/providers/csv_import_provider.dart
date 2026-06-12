import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/providers/catalog_providers.dart';
import 'package:kloudshop/providers/import_history_provider.dart';

enum CsvImportStep { idle, parsing, conflictCheck, preview, uploading, polling, done, error }
enum ConflictStrategy { skip, overwrite, customSku }

class CsvProductGroup {
  final String handle;
  final String title;
  final List<Map<String, String>> variantRows;

  CsvProductGroup({
    required this.handle,
    required this.title,
    required this.variantRows,
  });
}

class CsvImportState {
  final CsvImportStep step;
  final String? filename;
  final Uint8List? fileBytes;
  final List<CsvProductGroup> productGroups;
  final List<String> duplicateSKUs;
  final ConflictStrategy conflictStrategy;
  final Map<String, String> customSkuMap; // originalSku -> newSku
  final String? jobId;
  final int rowsTotal;
  final int rowsProcessed;
  final int rowsFailed;
  final int rowsSkipped;
  final String jobStatus; // pending|processing|successful|partial_success|failed
  final List<Map<String, dynamic>> errorLog;
  final List<Map<String, dynamic>> noStockLog;
  final String? errorMessage;

  CsvImportState({
    required this.step,
    this.filename,
    this.fileBytes,
    required this.productGroups,
    required this.duplicateSKUs,
    required this.conflictStrategy,
    required this.customSkuMap,
    this.jobId,
    this.rowsTotal = 0,
    this.rowsProcessed = 0,
    this.rowsFailed = 0,
    this.rowsSkipped = 0,
    this.jobStatus = 'pending',
    required this.errorLog,
    required this.noStockLog,
    this.errorMessage,
  });

  CsvImportState copyWith({
    CsvImportStep? step,
    String? filename,
    Uint8List? fileBytes,
    List<CsvProductGroup>? productGroups,
    List<String>? duplicateSKUs,
    ConflictStrategy? conflictStrategy,
    Map<String, String>? customSkuMap,
    String? jobId,
    int? rowsTotal,
    int? rowsProcessed,
    int? rowsFailed,
    int? rowsSkipped,
    String? jobStatus,
    List<Map<String, dynamic>>? errorLog,
    List<Map<String, dynamic>>? noStockLog,
    String? errorMessage,
  }) {
    return CsvImportState(
      step: step ?? this.step,
      filename: filename ?? this.filename,
      fileBytes: fileBytes ?? this.fileBytes,
      productGroups: productGroups ?? this.productGroups,
      duplicateSKUs: duplicateSKUs ?? this.duplicateSKUs,
      conflictStrategy: conflictStrategy ?? this.conflictStrategy,
      customSkuMap: customSkuMap ?? this.customSkuMap,
      jobId: jobId ?? this.jobId,
      rowsTotal: rowsTotal ?? this.rowsTotal,
      rowsProcessed: rowsProcessed ?? this.rowsProcessed,
      rowsFailed: rowsFailed ?? this.rowsFailed,
      rowsSkipped: rowsSkipped ?? this.rowsSkipped,
      jobStatus: jobStatus ?? this.jobStatus,
      errorLog: errorLog ?? this.errorLog,
      noStockLog: noStockLog ?? this.noStockLog,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CsvImportNotifier extends Notifier<CsvImportState> {
  @override
  CsvImportState build() {
    return CsvImportState(
      step: CsvImportStep.idle,
      productGroups: [],
      duplicateSKUs: [],
      conflictStrategy: ConflictStrategy.skip,
      customSkuMap: {},
      errorLog: [],
      noStockLog: [],
    );
  }

  void reset() {
    state = CsvImportState(
      step: CsvImportStep.idle,
      productGroups: [],
      duplicateSKUs: [],
      conflictStrategy: ConflictStrategy.skip,
      customSkuMap: {},
      errorLog: [],
      noStockLog: [],
    );
  }

  void setStrategy(ConflictStrategy strategy) {
    state = state.copyWith(conflictStrategy: strategy);
  }

  void setCustomSku(String originalSku, String newSku) {
    final updatedMap = Map<String, String>.from(state.customSkuMap);
    updatedMap[originalSku] = newSku;
    state = state.copyWith(customSkuMap: updatedMap);
  }

  Future<void> handleFilePicked(Uint8List bytes, String filename) async {
    state = state.copyWith(step: CsvImportStep.parsing, filename: filename, fileBytes: bytes, errorMessage: null);
    try {
      final List<Map<String, String>> rows = await compute(_parseRowsCompute, _ParseParams(bytes, filename));
      if (rows.isEmpty) {
        state = state.copyWith(step: CsvImportStep.error, errorMessage: 'File is empty or has no data rows');
        return;
      }

      final groups = groupRowsByHandle(rows);
      if (groups.isEmpty) {
        state = state.copyWith(step: CsvImportStep.error, errorMessage: 'Could not parse any valid product handle groups');
        return;
      }

      final allSkus = <String>{};
      for (final row in rows) {
        final sku = row['SKU']?.trim() ?? '';
        if (sku.isNotEmpty) {
          allSkus.add(sku);
        }
      }

      state = state.copyWith(
        step: CsvImportStep.conflictCheck,
        productGroups: groups,
        rowsTotal: rows.length,
      );

      if (allSkus.isNotEmpty) {
        final apiService = ref.read(apiServiceProvider);
        final duplicates = await apiService.checkSkuExists(allSkus.toList());
        
        if (duplicates.isNotEmpty) {
          final defaultCustomSkuMap = <String, String>{};
          for (final dup in duplicates) {
            defaultCustomSkuMap[dup] = '$dup-dup';
          }
          state = state.copyWith(
            step: CsvImportStep.preview,
            duplicateSKUs: duplicates,
            customSkuMap: defaultCustomSkuMap,
          );
        } else {
          state = state.copyWith(step: CsvImportStep.preview, duplicateSKUs: []);
        }
      } else {
        state = state.copyWith(step: CsvImportStep.preview, duplicateSKUs: []);
      }
    } catch (e) {
      state = state.copyWith(step: CsvImportStep.error, errorMessage: 'Failed to parse file: $e');
    }
  }

  Future<void> upload() async {
    if (state.fileBytes == null || state.filename == null) return;
    
    state = state.copyWith(step: CsvImportStep.uploading, errorMessage: null);
    try {
      final apiService = ref.read(apiServiceProvider);
      
      String strategyStr = 'skip';
      if (state.conflictStrategy == ConflictStrategy.overwrite) {
        strategyStr = 'overwrite';
      } else if (state.conflictStrategy == ConflictStrategy.customSku) {
        strategyStr = 'custom_sku';
      }

      final job = await apiService.uploadCsvImport(
        bytes: state.fileBytes!,
        filename: state.filename!,
        conflictStrategy: strategyStr,
        customSkuMap: state.customSkuMap,
      );

      final jobId = job['job_id'] as String;
      state = state.copyWith(
        step: CsvImportStep.polling,
        jobId: jobId,
        jobStatus: job['status'] ?? 'pending',
      );

      _startPolling(jobId);
    } catch (e) {
      state = state.copyWith(step: CsvImportStep.error, errorMessage: 'Upload failed: $e');
    }
  }

  Timer? _pollingTimer;

  void _startPolling(String jobId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final apiService = ref.read(apiServiceProvider);
        final job = await apiService.getImportJobStatus(jobId);
        
        final String status = job['status'] ?? 'pending';
        final int processed = job['rows_processed'] ?? 0;
        final int total = job['rows_total'] ?? state.rowsTotal;
        final int failed = job['rows_failed'] ?? 0;
        final int skipped = job['rows_skipped'] ?? 0;
        final List<Map<String, dynamic>> errors = List<Map<String, dynamic>>.from(job['error_log'] ?? []);
        final List<Map<String, dynamic>> noStock = List<Map<String, dynamic>>.from(job['no_stock_log'] ?? []);

        state = state.copyWith(
          jobStatus: status,
          rowsProcessed: processed,
          rowsTotal: total,
          rowsFailed: failed,
          rowsSkipped: skipped,
          errorLog: errors,
          noStockLog: noStock,
        );

        if (status == 'successful' || status == 'partial_success' || status == 'failed') {
          timer.cancel();
          state = state.copyWith(step: CsvImportStep.done);
          // Refresh catalog page
          ref.invalidate(productsProvider);
          // Refresh import history
          ref.read(importHistoryProvider.notifier).fetchHistory();
        }
      } catch (e) {
        timer.cancel();
        state = state.copyWith(step: CsvImportStep.error, errorMessage: 'Polling failed: $e');
      }
    });
  }

  void cancelPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}

final csvImportProvider = NotifierProvider<CsvImportNotifier, CsvImportState>(
  CsvImportNotifier.new,
);

List<Map<String, String>> parseFileBytes(Uint8List bytes, String filename) {
  if (filename.toLowerCase().endsWith('.xlsx')) {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) return [];
    final table = excel.tables[excel.tables.keys.first]!;
    if (table.maxRows <= 1) return [];
    
    final headers = table.rows.first.map((cell) => cell?.value?.toString().trim() ?? '').toList();
    final List<Map<String, String>> result = [];
    for (var i = 1; i < table.rows.length; i++) {
      final row = table.rows[i];
      final Map<String, String> rowMap = {};
      var hasAnyValue = false;
      for (var j = 0; j < headers.length; j++) {
        if (j < row.length) {
          final val = row[j]?.value?.toString().trim() ?? '';
          if (val.isNotEmpty) hasAnyValue = true;
          rowMap[headers[j]] = val;
        } else {
          rowMap[headers[j]] = '';
        }
      }
      if (hasAnyValue) {
        result.add(rowMap);
      }
    }
    return result;
  } else {
    final text = utf8.decode(bytes, allowMalformed: true);
    final normalizedText = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final csvRows = const CsvToListConverter(eol: '\n').convert(normalizedText);
    if (csvRows.length <= 1) return [];
    final headers = csvRows.first.map((e) => e?.toString().trim() ?? '').toList();
    final List<Map<String, String>> result = [];
    for (var i = 1; i < csvRows.length; i++) {
      final row = csvRows[i];
      final Map<String, String> rowMap = {};
      var hasAnyValue = false;
      for (var j = 0; j < headers.length; j++) {
        if (j < row.length) {
          final val = row[j]?.toString().trim() ?? '';
          if (val.isNotEmpty) hasAnyValue = true;
          rowMap[headers[j]] = val;
        } else {
          rowMap[headers[j]] = '';
        }
      }
      if (hasAnyValue) {
        result.add(rowMap);
      }
    }
    return result;
  }
}

List<CsvProductGroup> groupRowsByHandle(List<Map<String, String>> rows) {
  final Map<String, CsvProductGroup> groupMap = {};
  final List<CsvProductGroup> orderedGroups = [];
  String? lastHandle;

  for (final row in rows) {
    final handle = row['Handle']?.trim() ?? '';
    final title = row['Title']?.trim() ?? '';

    if (handle.isNotEmpty) {
      lastHandle = handle;
      if (groupMap.containsKey(handle)) {
        groupMap[handle]!.variantRows.add(row);
      } else {
        final newGroup = CsvProductGroup(
          handle: handle,
          title: title.isNotEmpty ? title : handle,
          variantRows: [row],
        );
        groupMap[handle] = newGroup;
        orderedGroups.add(newGroup);
      }
    } else if (lastHandle != null && groupMap.containsKey(lastHandle)) {
      groupMap[lastHandle]!.variantRows.add(row);
    }
  }
  return orderedGroups;
}

class _ParseParams {
  final Uint8List bytes;
  final String filename;
  _ParseParams(this.bytes, this.filename);
}

List<Map<String, String>> _parseRowsCompute(_ParseParams params) {
  return parseFileBytes(params.bytes, params.filename);
}
