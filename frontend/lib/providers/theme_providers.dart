import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/theme.dart';
import 'package:kloudshop/models/theme_config.dart';
import 'package:kloudshop/services/api_service.dart';

final sidebarExtendedProvider = NotifierProvider<SidebarExtendedNotifier, bool>(
  SidebarExtendedNotifier.new,
);

class SidebarExtendedNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle(bool val) {
    state = val;
  }
}

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

  ThemeConfigModel? _originalConfig;

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

    if (config != null) {
      _originalConfig ??= config;
      if (_history.isEmpty) {
        _addToHistory(config);
      }
    }
    return config;
  }

  int getSessionChangesCount() {
    final current = state.value;
    if (current == null || _originalConfig == null) return 0;
    int changes = 0;
    
    // Compare tokens
    current.draftTokens.forEach((k, v) {
      if (_originalConfig!.draftTokens[k] != v) {
        changes++;
      }
    });
    _originalConfig!.draftTokens.forEach((k, v) {
      if (!current.draftTokens.containsKey(k)) {
        changes++;
      }
    });

    // Compare slots
    current.draftSlots.forEach((k, v) {
      final origVal = _originalConfig!.draftSlots[k];
      if (!_areEqual(origVal, v)) {
        changes++;
      }
    });
    _originalConfig!.draftSlots.forEach((k, v) {
      if (!current.draftSlots.containsKey(k)) {
        changes++;
      }
    });

    // Compare name
    if (current.name != _originalConfig!.name) {
      changes++;
    }

    return changes;
  }

  bool _areEqual(dynamic a, dynamic b) {
    if (a == b) return true;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_areEqual(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_areEqual(a[i], b[i])) return false;
      }
      return true;
    }
    return false;
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

  void deleteTokens(List<String> keysToDelete, {String? editKey}) {
    final current = state.value;
    if (current == null) return;

    final newTokens = {...current.draftTokens};
    for (final key in keysToDelete) {
      newTokens.remove(key);
    }

    final updated = current.copyWith(
      draftTokens: newTokens,
      updatedAt: DateTime.now(),
    );

    state = AsyncValue.data(updated);
    _addToHistory(updated, editKey: editKey ?? 'delete_tokens');
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
      log('Failed to save theme draft: $e');
    }
  }

  Future<void> commitSave() async {
    final current = state.value;
    if (current == null) return;
    
    await saveDraft();
    _originalConfig = current;
    state = AsyncValue.data(current);
  }

  Future<void> revertToOriginal() async {
    if (_originalConfig == null) return;
    
    state = AsyncValue.data(_originalConfig);
    _history.clear();
    _historyIndex = -1;
    _addToHistory(_originalConfig!);
    await saveDraft();
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

// ── Theme Customizer Panel State ──────────────────────────────────────────────

/// Which mode the left icon ribbon is in.
enum CustomizerMode { outline, settings, embeds }

class CustomizerModeNotifier extends Notifier<CustomizerMode> {
  @override
  CustomizerMode build() => CustomizerMode.outline;

  void setMode(CustomizerMode val) {
    state = val;
  }
}

/// Controls which center panel view is active in the customizer.
final customizerModeProvider = NotifierProvider<CustomizerModeNotifier, CustomizerMode>(
  CustomizerModeNotifier.new,
);

class CustomizerNavStackNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void setStack(List<String> val) {
    state = val;
  }
}

/// Breadcrumb navigation stack for center panel drill-down.
/// Empty list = outline root. Each entry is a section/block ID being drilled into.
final customizerNavStackProvider = NotifierProvider<CustomizerNavStackNotifier, List<String>>(
  CustomizerNavStackNotifier.new,
);

class SelectedSectionIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setSelectedId(String? val) {
    state = val;
  }
}

/// Shared selection bus for bi-directional section highlighting.
/// Written by both the outline panel and the canvas preview.
final selectedSectionIdProvider = NotifierProvider<SelectedSectionIdNotifier, String?>(
  SelectedSectionIdNotifier.new,
);

class EnabledFeatureModulesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void setEnabledFeatures(Set<String> val) {
    state = val;
  }
}

/// Set of enabled native feature module IDs for the current merchant.
final enabledFeatureModulesProvider = NotifierProvider<EnabledFeatureModulesNotifier, Set<String>>(
  EnabledFeatureModulesNotifier.new,
);
