import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/services/api_service.dart';

class ImportHistoryState {
  final List<Map<String, dynamic>> jobs;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastViewedHistoryAt;

  ImportHistoryState({
    required this.jobs,
    this.isLoading = false,
    this.errorMessage,
    this.lastViewedHistoryAt,
  });

  ImportHistoryState copyWith({
    List<Map<String, dynamic>>? jobs,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastViewedHistoryAt,
  }) {
    return ImportHistoryState(
      jobs: jobs ?? this.jobs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastViewedHistoryAt: lastViewedHistoryAt ?? this.lastViewedHistoryAt,
    );
  }

  int get unreadCount {
    if (lastViewedHistoryAt == null) return jobs.length;
    return jobs.where((job) {
      final createdAtStr = job['created_at'] as String?;
      if (createdAtStr == null) return false;
      try {
        final createdAt = DateTime.parse(createdAtStr);
        return createdAt.isAfter(lastViewedHistoryAt!);
      } catch (_) {
        return false;
      }
    }).length;
  }
}

class ImportHistoryNotifier extends Notifier<ImportHistoryState> {
  Timer? _pollingTimer;

  @override
  ImportHistoryState build() {
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });
    return ImportHistoryState(jobs: []);
  }

  void markAsViewed() {
    state = state.copyWith(lastViewedHistoryAt: DateTime.now());
  }

  Future<void> fetchHistory() async {
    state = state.copyWith(isLoading: state.jobs.isEmpty, errorMessage: null);
    try {
      final apiService = ref.read(apiServiceProvider);
      final jobs = await apiService.getImportHistory();
      state = state.copyWith(jobs: jobs, isLoading: false);
      _checkAndStartHistoryPolling();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void _checkAndStartHistoryPolling() {
    final hasActiveJobs = state.jobs.any((job) {
      final status = job['status'] as String?;
      return status == 'pending' || status == 'processing';
    });

    if (hasActiveJobs) {
      if (_pollingTimer == null || !_pollingTimer!.isActive) {
        _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
          try {
            final apiService = ref.read(apiServiceProvider);
            final jobs = await apiService.getImportHistory();
            state = state.copyWith(jobs: jobs);
            
            final stillHasActive = jobs.any((job) {
              final status = job['status'] as String?;
              return status == 'pending' || status == 'processing';
            });
            
            if (!stillHasActive) {
              timer.cancel();
            }
          } catch (_) {
            // Keep polling silently in background
          }
        });
      }
    } else {
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }
}

final importHistoryProvider = NotifierProvider<ImportHistoryNotifier, ImportHistoryState>(
  ImportHistoryNotifier.new,
);
