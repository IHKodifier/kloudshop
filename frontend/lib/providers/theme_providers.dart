import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/theme.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/services/api_service.dart';

final themesProvider = FutureProvider<List<ThemeModel>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.listThemes();
});

final activeThemeConfigProvider =
    AsyncNotifierProvider<ActiveThemeConfigNotifier, ThemeConfigModel?>(
      ActiveThemeConfigNotifier.new,
    );

class ActiveThemeConfigNotifier extends AsyncNotifier<ThemeConfigModel?> {
  Timer? _saveTimer;
  final List<ThemeConfigModel> _history = [];
  int _historyIndex = -1;
  static const int _maxHistory = 50;

  @override
  FutureOr<ThemeConfigModel?> build() async {
    ref.onDispose(() => _saveTimer?.cancel());

    final config = await ref.watch(apiServiceProvider).getActiveTheme();
    if (config != null && _history.isEmpty) {
      _addToHistory(config);
    }
    return config;
  }

  void _addToHistory(ThemeConfigModel config) {
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(config);
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    } else {
      _historyIndex++;
    }
  }

  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  void undo() {
    if (!canUndo) return;
    _historyIndex--;
    state = AsyncValue.data(_history[_historyIndex]);
    _debouncedSave();
  }

  void redo() {
    if (!canRedo) return;
    _historyIndex++;
    state = AsyncValue.data(_history[_historyIndex]);
    _debouncedSave();
  }

  Future<void> fetch() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(apiServiceProvider).getActiveTheme(),
    );
  }

  Future<void> selectTheme(String themeId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(apiServiceProvider).selectTheme(themeId),
    );
    if (state.value != null) {
      _history.clear();
      _historyIndex = -1;
      _addToHistory(state.value!);
    }
  }

  void updateLocalToken(String key, String value) {
    updateTokens({key: value});
  }

  void updateTokens(Map<String, dynamic> newTokens) {
    final current = state.value;
    if (current == null) return;

    final updated = ThemeConfigModel(
      configId: current.configId,
      tenantId: current.tenantId,
      themeId: current.themeId,
      draftTokens: {...current.draftTokens, ...newTokens},
      liveTokens: current.liveTokens,
      draftSlots: current.draftSlots,
      liveSlots: current.liveSlots,
      isActive: current.isActive,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    _addToHistory(updated);
    _debouncedSave();
  }

  void updateLocalSlot(String key, String value) {
    updateSlots({key: value});
  }

  void updateSlots(Map<String, dynamic> newSlots) {
    final current = state.value;
    if (current == null) return;

    final updated = ThemeConfigModel(
      configId: current.configId,
      tenantId: current.tenantId,
      themeId: current.themeId,
      draftTokens: current.draftTokens,
      liveTokens: current.liveTokens,
      draftSlots: {...current.draftSlots, ...newSlots},
      liveSlots: current.liveSlots,
      isActive: current.isActive,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    _addToHistory(updated);
    _debouncedSave();
  }

  void _debouncedSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () => saveDraft());
  }

  Future<void> saveDraft() async {
    final current = state.value;
    if (current == null) return;

    try {
      await ref
          .read(apiServiceProvider)
          .updateThemeConfig(
            tokens: current.draftTokens,
            slots: current.draftSlots,
          );
    } catch (e) {
      // Log error but keep local state for now
      log('Failed to save theme draft: $e');
    }
  }

  Future<void> publish() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(apiServiceProvider).publishTheme(),
    );
  }
}
