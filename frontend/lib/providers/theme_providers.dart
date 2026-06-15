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

final editingThemeConfigIdProvider = NotifierProvider<EditingThemeConfigIdNotifier, String?>(
  EditingThemeConfigIdNotifier.new,
);

class EditingThemeConfigIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setConfigId(String? val) {
    state = val;
  }
}

final themeConfigurationsProvider = FutureProvider<List<ThemeConfigModel>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.listThemeConfigurations();
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

  String? _lastEditKey;
  DateTime? _lastEditTime;

  @override
  FutureOr<ThemeConfigModel?> build() async {
    ref.onDispose(() => _saveTimer?.cancel());

    final editingId = ref.watch(editingThemeConfigIdProvider);
    ThemeConfigModel? config;
    if (editingId == null) {
      config = await ref.watch(apiServiceProvider).getActiveTheme();
    } else {
      config = await ref.watch(apiServiceProvider).getThemeConfig(editingId);
    }

    if (config != null && _history.isEmpty) {
      _addToHistory(config);
    }
    return config;
  }

  void _addToHistory(ThemeConfigModel config, {String? editKey}) {
    final now = DateTime.now();
    final isDebounced = editKey != null &&
        _lastEditKey == editKey &&
        _lastEditTime != null &&
        now.difference(_lastEditTime!) < const Duration(milliseconds: 500);

    _lastEditKey = editKey;
    _lastEditTime = now;

    if (isDebounced && _historyIndex >= 0 && _historyIndex < _history.length) {
      _history[_historyIndex] = config;
      return;
    }

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
    final editingId = ref.read(editingThemeConfigIdProvider);
    if (editingId == null) {
      state = await AsyncValue.guard(
        () => ref.read(apiServiceProvider).getActiveTheme(),
      );
    } else {
      state = await AsyncValue.guard(
        () => ref.read(apiServiceProvider).getThemeConfig(editingId),
      );
    }
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
    updateTokens({key: value}, editKey: key);
  }

  void updateTokens(Map<String, dynamic> newTokens, {String? editKey}) {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      draftTokens: {...current.draftTokens, ...newTokens},
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    _addToHistory(updated, editKey: editKey);
    _debouncedSave();
  }

  void updateLocalSlot(String key, String value) {
    updateSlots({key: value}, editKey: key);
  }

  void updateSlots(Map<String, dynamic> newSlots, {String? editKey}) {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      draftSlots: {...current.draftSlots, ...newSlots},
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    _addToHistory(updated, editKey: editKey);
    _debouncedSave();
  }

  void updateName(String newName) {
    final current = state.value;
    if (current == null) return;

    final updated = current.copyWith(
      name: newName,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    _addToHistory(updated, editKey: 'name');
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
          .updateThemeConfigById(
            current.configId,
            name: current.name,
            tokens: current.draftTokens,
            slots: current.draftSlots,
          );
    } catch (e) {
      // Log error but keep local state for now
      log('Failed to save theme draft: $e');
    }
  }

  Future<void> publish() async {
    final current = state.value;
    if (current == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(apiServiceProvider).publishThemeById(current.configId),
    );
  }
}
