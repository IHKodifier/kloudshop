import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/color_preset.dart';
import 'package:kloudshop/services/api_service.dart';

final List<ColorPreset> defaultPresets = [
  ColorPreset(
    presetId: 'd1',
    tenantId: 'default',
    name: 'Pure white',
    hexCode: '#ffffff',
    createdAt: DateTime(2026),
  ),
  ColorPreset(
    presetId: 'd2',
    tenantId: 'default',
    name: 'Jet black',
    hexCode: '#000000',
    createdAt: DateTime(2026),
  ),
  ColorPreset(
    presetId: 'd3',
    tenantId: 'default',
    name: 'Metallic silver',
    hexCode: '#c0c0c0',
    createdAt: DateTime(2026),
  ),
];

class ColorPresetsNotifier extends AsyncNotifier<List<ColorPreset>> {
  @override
  FutureOr<List<ColorPreset>> build() async {
    final apiService = ref.watch(apiServiceProvider);
    try {
      final dbPresets = await apiService.listColorPresets();
      if (dbPresets.isEmpty) {
        return defaultPresets;
      }
      return dbPresets;
    } catch (e) {
      // If fetching fails, degrade gracefully to default presets
      return defaultPresets;
    }
  }

  Future<void> addPreset(String name, String hexCode) async {
    final apiService = ref.read(apiServiceProvider);
    final currentList = state.value ?? defaultPresets;
    
    // Generate temporary ID for optimistic UI update
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempPreset = ColorPreset(
      presetId: tempId,
      tenantId: 'temp',
      name: name,
      hexCode: hexCode,
      createdAt: DateTime.now(),
    );

    state = AsyncValue.data([...currentList, tempPreset]);

    try {
      final newPreset = await apiService.createColorPreset(name, hexCode);
      
      // Update state with actual preset from DB
      final updatedList = (state.value ?? []).map((p) {
        return p.presetId == tempId ? newPreset : p;
      }).toList();
      state = AsyncValue.data(updatedList);
    } catch (e) {
      // Rollback on error
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  Future<void> updatePreset(String presetId, String name, String hexCode) async {
    final apiService = ref.read(apiServiceProvider);
    final currentList = state.value ?? defaultPresets;

    // Optimistically update locally
    state = AsyncValue.data(
      currentList.map((p) {
        if (p.presetId == presetId) {
          return ColorPreset(
            presetId: presetId,
            tenantId: p.tenantId,
            name: name,
            hexCode: hexCode,
            createdAt: p.createdAt,
          );
        }
        return p;
      }).toList(),
    );

    if (presetId.startsWith('d')) {
      // Offline fallback preset, only update locally
      return;
    }

    try {
      final updated = await apiService.updateColorPreset(presetId, name, hexCode);
      // Update with actual server response
      state = AsyncValue.data(
        (state.value ?? []).map((p) => p.presetId == presetId ? updated : p).toList(),
      );
    } catch (e) {
      // Rollback on error
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }

  Future<void> removePreset(String presetId) async {
    final apiService = ref.read(apiServiceProvider);
    final currentList = state.value ?? defaultPresets;

    // Offline fallback presets are only filtered locally
    if (presetId.startsWith('d')) {
      state = AsyncValue.data(
        currentList.where((p) => p.presetId != presetId).toList(),
      );
      return;
    }

    // Optimistically remove from UI
    state = AsyncValue.data(
      currentList.where((p) => p.presetId != presetId).toList(),
    );

    try {
      await apiService.deleteColorPreset(presetId);
    } catch (e) {
      // Rollback on error
      state = AsyncValue.data(currentList);
      rethrow;
    }
  }
}

final colorPresetsProvider =
    AsyncNotifierProvider<ColorPresetsNotifier, List<ColorPreset>>(
      ColorPresetsNotifier.new,
    );
