import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/providers/theme_providers.dart';
import 'package:kloudshop/models/feature_module.dart';
import 'package:kloudshop/models/theme_config.dart';

class NativeEmbedsPanel extends ConsumerWidget {
  final ThemeConfigModel? config;
  final String selectedPage;
  final Map<String, dynamic> layout;

  const NativeEmbedsPanel({
    super.key,
    required this.config,
    required this.selectedPage,
    required this.layout,
  });

  String get _slotKey => selectedPage == 'home' ? 'layout' : 'layout_$selectedPage';

  Map<String, dynamic> _getLayoutTree() {
    return layout;
  }

  void _injectSection(WidgetRef ref, KloudFeatureModule module) {
    if (module.themeSectionType == null) return;
    
    final tree = _deepCopyMap(_getLayoutTree());
    final children = List<dynamic>.from(tree['children'] ?? []);

    // Check if section already exists
    final exists = children.any((c) => c['type'] == module.themeSectionType || c['id'] == module.id);
    if (!exists) {
      final newSection = {
        'id': module.id,
        'type': module.themeSectionType,
        'customName': module.label,
        'properties': {
          'padding': 24.0,
          'background_color': '#F8FAFC',
        },
        'children': []
      };

      // Place before footer sections
      int insertIdx = children.length;
      for (int i = 0; i < children.length; i++) {
        final child = children[i];
        if (child is Map<String, dynamic>) {
          final type = (child['type'] ?? '').toString().toLowerCase();
          final id = (child['id'] ?? '').toString().toLowerCase();
          if (type == 'footer' || id.contains('footer')) {
            insertIdx = i;
            break;
          }
        }
      }

      children.insert(insertIdx, newSection);
      final updatedTree = {...tree, 'children': children};
      
      ref.read(activeThemeConfigProvider.notifier).updateSlots({
        _slotKey: updatedTree,
      }, editKey: 'embed_inject_${module.id}');
    }
  }

  void _removeSection(WidgetRef ref, KloudFeatureModule module) {
    if (module.themeSectionType == null) return;

    final tree = _deepCopyMap(_getLayoutTree());
    final children = List<dynamic>.from(tree['children'] ?? []);
    
    children.removeWhere((c) => c['type'] == module.themeSectionType || c['id'] == module.id);
    final updatedTree = {...tree, 'children': children};

    ref.read(activeThemeConfigProvider.notifier).updateSlots({
      _slotKey: updatedTree,
    }, editKey: 'embed_remove_${module.id}');
  }

  Map<String, dynamic> _deepCopyMap(Map<String, dynamic> map) {
    return Map<String, dynamic>.from(
      map.map((key, value) {
        if (value is Map<String, dynamic>) {
          return MapEntry(key, _deepCopyMap(value));
        } else if (value is List) {
          return MapEntry(key, value.map((item) {
            if (item is Map<String, dynamic>) {
              return _deepCopyMap(item);
            }
            return item;
          }).toList());
        }
        return MapEntry(key, value);
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final enabledModules = ref.watch(enabledFeatureModulesProvider);
    final modules = FeatureRegistry.instance.defaultModules;

    // Check currently present section types in layout to sync switches
    final layout = _getLayoutTree();
    final children = layout['children'] as List<dynamic>? ?? [];
    final presentTypes = children.map((c) => (c['type'] ?? '').toString()).toSet();
    final presentIds = children.map((c) => (c['id'] ?? '').toString()).toSet();

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(right: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'App Embeds',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Text(
                    'PLATFORM FEATURES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: theme.hintColor,
                    ),
                  ),
                ),
                
                ...modules.map((module) {
                  // A module is considered enabled if it is in the provider set OR its section type is present in the layout tree
                  final isCurrentlyEnabled = enabledModules.contains(module.id) ||
                      (module.themeSectionType != null && presentTypes.contains(module.themeSectionType)) ||
                      presentIds.contains(module.id);
                  
                  final isPro = module.minPlanTier == 'pro';

                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isCurrentlyEnabled
                        ? AppTheme.brandEmerald500.withOpacity(isDark ? 0.05 : 0.03)
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isCurrentlyEnabled
                            ? AppTheme.brandEmerald500.withOpacity(0.3)
                            : theme.dividerColor.withOpacity(0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                module.icon,
                                size: 18,
                                color: isCurrentlyEnabled ? AppTheme.brandEmerald500 : theme.hintColor,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      module.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrentlyEnabled ? AppTheme.brandEmerald500 : null,
                                      ),
                                    ),
                                    if (isPro) ...[
                                      const SizedBox(width: 6),
                                       Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          'PRO',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFF59E0B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Switch.adaptive(
                                value: isCurrentlyEnabled,
                                activeColor: AppTheme.brandEmerald500,
                                onChanged: (val) {
                                  final currentSet = <String>{...ref.read(enabledFeatureModulesProvider)};
                                  if (val) {
                                    currentSet.add(module.id);
                                    _injectSection(ref, module);
                                  } else {
                                    currentSet.remove(module.id);
                                    _removeSection(ref, module);
                                  }
                                  ref.read(enabledFeatureModulesProvider.notifier).setEnabledFeatures(currentSet);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            module.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              height: 1.3,
                            ),
                          ),
                          if (!isCurrentlyEnabled) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {},
                              child: Text(
                                'Learn more about ${module.label} →',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.brandEmerald500,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
