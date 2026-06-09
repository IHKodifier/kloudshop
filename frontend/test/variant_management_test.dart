// ignore_for_file: avoid_print
/// Variant Management Test Suite — VT-001 through VT-007
///
/// Tests the [ProductEditorNotifier] variant engine in isolation:
/// no backend, no Firebase, no UI — pure provider logic.
///
/// Run with:
///   flutter test test/variant_management_test.dart --reporter=expanded
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kloudshop/providers/product_editor_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a fresh [ProviderContainer] with a new-product editor (no existing
/// product).  Caller is responsible for calling [container.dispose()].
ProviderContainer _newProductContainer() {
  return ProviderContainer();
}

/// Convenience: read the notifier for a new product.
ProductEditorNotifier _notifier(ProviderContainer c) =>
    c.read(productEditorProvider(null).notifier);

/// Convenience: read the state for a new product.
ProductEditorState _state(ProviderContainer c) =>
    c.read(productEditorProvider(null));

/// Sets the product title (and therefore slug) on the notifier.
void _setTitle(ProviderContainer c, String title) {
  _notifier(c).updateTitle(title);
}

/// Adds [colorNames] to the Color option in [optionsSchema].
void _addColors(ProviderContainer c, List<String> colorNames) {
  final current = List<Map<String, dynamic>>.from(_state(c).optionsSchema);
  final colorIdx = current.indexWhere(
    (o) => o['name'].toString().trim().toLowerCase() == 'color',
  );
  if (colorIdx == -1) return;
  final updated = Map<String, dynamic>.from(current[colorIdx]);
  updated['values'] = [
    ...List<String>.from(updated['values'] ?? []),
    ...colorNames,
  ];
  current[colorIdx] = updated;
  _notifier(c).updateOptionsSchema(current);
}

/// Removes [colorName] from the Color option.
void _removeColor(ProviderContainer c, String colorName) {
  final current = List<Map<String, dynamic>>.from(_state(c).optionsSchema);
  final colorIdx = current.indexWhere(
    (o) => o['name'].toString().trim().toLowerCase() == 'color',
  );
  if (colorIdx == -1) return;
  final updated = Map<String, dynamic>.from(current[colorIdx]);
  final vals = List<String>.from(updated['values'] ?? [])
    ..remove(colorName);
  updated['values'] = vals;
  current[colorIdx] = updated;
  _notifier(c).updateOptionsSchema(current);
}

/// Clears ALL color values (simulates pressing the delete icon on Color).
void _clearColors(ProviderContainer c) {
  final current = List<Map<String, dynamic>>.from(_state(c).optionsSchema);
  final colorIdx = current.indexWhere(
    (o) => o['name'].toString().trim().toLowerCase() == 'color',
  );
  if (colorIdx == -1) return;
  final updated = Map<String, dynamic>.from(current[colorIdx])
    ..['values'] = <String>[];
  current[colorIdx] = updated;
  _notifier(c).updateOptionsSchema(current);
}

/// Adds a custom option category with [name] and [values].
void _addCustomOption(
    ProviderContainer c, String name, List<String> values) {
  final current = List<Map<String, dynamic>>.from(_state(c).optionsSchema);
  current.add({'name': name, 'values': values});
  _notifier(c).updateOptionsSchema(current);
}

/// Renames an option category from [oldName] to [newName].
void _renameOption(ProviderContainer c, String oldName, String newName) {
  final current = List<Map<String, dynamic>>.from(_state(c).optionsSchema);
  final idx = current.indexWhere(
    (o) => o['name'].toString().trim().toLowerCase() == oldName.toLowerCase(),
  );
  if (idx == -1) return;
  current[idx] = Map<String, dynamic>.from(current[idx])..['name'] = newName;
  _notifier(c).updateOptionsSchema(current);
}

/// Sets a field on the first/sole default variant.
void _setDefaultVariantField(
    ProviderContainer c, String field, dynamic value) {
  final variants = List<Map<String, dynamic>>.from(_state(c).variants);
  final idx = variants.indexWhere((v) => v['is_default'] == true);
  if (idx == -1) return;
  variants[idx] = Map<String, dynamic>.from(variants[idx])..[field] = value;
  _notifier(c).updateVariants(variants);
}

/// Returns only the active variants (is_active != false).
List<Map<String, dynamic>> _activeVariants(ProviderContainer c) =>
    _state(c).variants.where((v) => v['is_active'] != false).toList();

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  // VT-001 — Zero Options → Single Color Option Transition
  // =========================================================================
  group('VT-001: Zero Options to Single Option Transition', () {
    test('fresh product starts with one default variant and empty options', () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');

      final state = _state(c);
      expect(state.variants.length, equals(1));
      expect(state.variants.first['is_default'], isTrue);
      expect(state.variants.first['is_active'], isTrue);

      final colorOpt = state.optionsSchema.firstWhere(
        (o) => o['name'].toString().toLowerCase() == 'color',
      );
      expect(
        List<String>.from(colorOpt['values'] ?? []),
        isEmpty,
        reason: 'Color option should start with zero values',
      );
    });

    test('adding one color + generating creates one variant with SKU suffix',
        () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');
      _setDefaultVariantField(c, 'sku', 'MUG-PREMIUM');
      _addColors(c, ['Pure white']);

      _notifier(c).generateVariantsFromOptions(reconcile: true);

      final active = _activeVariants(c);
      expect(active.length, equals(1));
      expect(
        active.first['sku'].toString().toUpperCase(),
        contains('MUG-PREMIUM'),
        reason: 'SKU should preserve base prefix',
      );
      expect(
        active.first['sku'].toString().toUpperCase(),
        contains('PURE'),
        reason: 'SKU should include color suffix',
      );
      expect(
        Map<String, String>.from(active.first['option_values'] ?? {}),
        containsPair('Color', 'Pure white'),
      );
    });
  });

  // =========================================================================
  // VT-002 — Reconciliation: Pricing & Stock Preserved on Option Addition
  // =========================================================================
  group('VT-002: Reconciliation of Pricing and Stock on Option Addition', () {
    test('adding Size to existing Color variants preserves price & stock', () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');
      _addColors(c, ['Pure white', 'Jet black']);

      // Generate initial 2 color variants (fresh)
      _notifier(c).generateVariantsFromOptions(reconcile: false);

      // Configure prices and stock on generated variants
      final variants = List<Map<String, dynamic>>.from(_state(c).variants);
      for (var i = 0; i < variants.length; i++) {
        final optVals = Map<String, String>.from(variants[i]['option_values'] ?? {});
        if (optVals['Color'] == 'Pure white') {
          variants[i] = Map<String, dynamic>.from(variants[i])
            ..['price'] = '15.00'
            ..['stock'] = '10';
        } else if (optVals['Color'] == 'Jet black') {
          variants[i] = Map<String, dynamic>.from(variants[i])
            ..['price'] = '18.00'
            ..['stock'] = '25';
        }
      }
      _notifier(c).updateVariants(variants);

      // Now add a Size option
      _addCustomOption(c, 'Size', ['S', 'M']);

      // Reconcile
      _notifier(c).generateVariantsFromOptions(reconcile: true);

      final active = _activeVariants(c);
      expect(active.length, equals(4),
          reason: '2 colors × 2 sizes = 4 variants');

      // All Pure white variants should have $15.00
      final whiteVariants = active.where((v) {
        final opts = Map<String, String>.from(v['option_values'] ?? {});
        return opts['Color'] == 'Pure white';
      }).toList();
      expect(whiteVariants.length, equals(2));
      for (final v in whiteVariants) {
        expect(v['price'], equals('15.00'),
            reason: 'Pure white price should be preserved');
      }

      // All Jet black variants should have $18.00
      final blackVariants = active.where((v) {
        final opts = Map<String, String>.from(v['option_values'] ?? {});
        return opts['Color'] == 'Jet black';
      }).toList();
      expect(blackVariants.length, equals(2));
      for (final v in blackVariants) {
        expect(v['price'], equals('18.00'),
            reason: 'Jet black price should be preserved');
      }
    });
  });

  // =========================================================================
  // VT-003 — Collapse to Simple Product with Stock Aggregation
  // =========================================================================
  group('VT-003: Collapse to Simple Product - Stock Aggregation', () {
    test('deleting all colors and generating collapses to base variant with summed stock',
        () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');
      _addColors(c, ['Pure white', 'Jet black']);
      _notifier(c).generateVariantsFromOptions(reconcile: false);

      // Set stock
      final variants = List<Map<String, dynamic>>.from(_state(c).variants);
      for (var i = 0; i < variants.length; i++) {
        final optVals = Map<String, String>.from(variants[i]['option_values'] ?? {});
        if (optVals['Color'] == 'Pure white') {
          variants[i] = Map<String, dynamic>.from(variants[i])
            ..['price'] = '12.50'
            ..['stock'] = '15';
        } else if (optVals['Color'] == 'Jet black') {
          variants[i] = Map<String, dynamic>.from(variants[i])
            ..['price'] = '15.00'
            ..['stock'] = '30';
        }
      }
      _notifier(c).updateVariants(variants);

      // Clear all colors (simulates trash icon on Color option)
      _clearColors(c);

      // Generate — should trigger collapse path
      _notifier(c).generateVariantsFromOptions(reconcile: true);

      final active = _activeVariants(c);
      expect(active.length, equals(1),
          reason: 'Should collapse to exactly one base variant');
      expect(
        Map<String, String>.from(active.first['option_values'] ?? {}),
        isEmpty,
        reason: 'Base variant should have no option values',
      );
      expect(active.first['stock'], equals('45'),
          reason: 'Stock should be aggregated: 15 + 30 = 45');
      expect(active.first['price'], equals('12.50'),
          reason: 'Price copied from first active variant');
    });

    test('base variant reappears in state after collapse (not zero variants)',
        () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');
      _addColors(c, ['Pure white']);
      _notifier(c).generateVariantsFromOptions(reconcile: false);
      _clearColors(c);
      _notifier(c).generateVariantsFromOptions(reconcile: true);

      expect(
        _activeVariants(c).length,
        greaterThan(0),
        reason: 'At least one active variant must exist after collapse',
      );
    });
  });

  // =========================================================================
  // VT-004 — Fresh Generation vs Intelligent Reconciliation
  // =========================================================================
  group('VT-004: Fresh Generation vs Reconciliation', () {
    test('Fresh Generation resets price and stock to defaults', () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');
      _addColors(c, ['Pure white', 'Jet black']);
      _notifier(c).generateVariantsFromOptions(reconcile: false);

      // Configure prices
      final variants = List<Map<String, dynamic>>.from(_state(c).variants);
      for (var i = 0; i < variants.length; i++) {
        variants[i] = Map<String, dynamic>.from(variants[i])
          ..['price'] = '25.00'
          ..['stock'] = '50';
      }
      _notifier(c).updateVariants(variants);

      // Add Material option and use Fresh Generation
      _addCustomOption(c, 'Material', ['Ceramic']);
      _notifier(c).generateVariantsFromOptions(reconcile: false);

      final active = _activeVariants(c);
      expect(active.length, equals(2),
          reason: '2 colors × 1 material = 2 variants');
      for (final v in active) {
        expect(v['price'], equals('0.00'),
            reason: 'Fresh generation resets price to 0.00');
        expect(v['stock'], equals('0'),
            reason: 'Fresh generation resets stock to 0');
      }
    });

    test('Intelligent Reconciliation preserves price and stock', () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');
      _addColors(c, ['Pure white', 'Jet black']);
      _notifier(c).generateVariantsFromOptions(reconcile: false);

      final variants = List<Map<String, dynamic>>.from(_state(c).variants);
      for (var i = 0; i < variants.length; i++) {
        variants[i] = Map<String, dynamic>.from(variants[i])
          ..['price'] = '25.00'
          ..['stock'] = '50';
      }
      _notifier(c).updateVariants(variants);

      _addCustomOption(c, 'Material', ['Ceramic']);
      _notifier(c).generateVariantsFromOptions(reconcile: true);

      final active = _activeVariants(c);
      for (final v in active) {
        expect(v['price'], equals('25.00'),
            reason: 'Reconciliation preserves price');
      }
    });
  });

  // =========================================================================
  // VT-005 — Deletion of Option Values / Retired Variant Stock Aggregation
  // =========================================================================
  group('VT-005: Deletion of Option Values', () {
    test('removing Metallic silver retires it and keeps remaining active', () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');
      _addColors(c, ['Pure white', 'Jet black', 'Metallic silver']);
      _notifier(c).generateVariantsFromOptions(reconcile: false);

      // Set stock on all three
      final variants = List<Map<String, dynamic>>.from(_state(c).variants);
      for (var i = 0; i < variants.length; i++) {
        final opts = Map<String, String>.from(variants[i]['option_values'] ?? {});
        if (opts['Color'] == 'Pure white') {
          variants[i] = Map<String, dynamic>.from(variants[i])
            ..['price'] = '10.00'..['stock'] = '100';
        } else if (opts['Color'] == 'Jet black') {
          variants[i] = Map<String, dynamic>.from(variants[i])
            ..['price'] = '12.00'..['stock'] = '120';
        } else if (opts['Color'] == 'Metallic silver') {
          variants[i] = Map<String, dynamic>.from(variants[i])
            ..['price'] = '15.00'..['stock'] = '80';
        }
      }
      _notifier(c).updateVariants(variants);

      // Remove Metallic silver chip
      _removeColor(c, 'Metallic silver');
      _notifier(c).generateVariantsFromOptions(reconcile: true);

      final active = _activeVariants(c);
      expect(active.length, equals(2),
          reason: 'Only Pure white and Jet black remain active');

      final skus = active.map((v) => v['sku'].toString().toUpperCase()).toList();
      expect(skus.any((s) => s.contains('SILVER')), isFalse,
          reason: 'Metallic silver variant should not be active');
    });

    test('retired variant stock is aggregated into surviving variant', () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');
      _addColors(c, ['Pure white', 'Jet black']);
      _notifier(c).generateVariantsFromOptions(reconcile: false);

      final variants = List<Map<String, dynamic>>.from(_state(c).variants);
      for (var i = 0; i < variants.length; i++) {
        final opts = Map<String, String>.from(variants[i]['option_values'] ?? {});
        if (opts['Color'] == 'Pure white') {
          variants[i] = Map<String, dynamic>.from(variants[i])
            ..['stock'] = '100';
        } else if (opts['Color'] == 'Jet black') {
          variants[i] = Map<String, dynamic>.from(variants[i])
            ..['stock'] = '80';
        }
      }
      _notifier(c).updateVariants(variants);

      // Remove Jet black — its 80 units should be added to Pure white
      _removeColor(c, 'Jet black');
      _notifier(c).generateVariantsFromOptions(reconcile: true);

      final active = _activeVariants(c);
      expect(active.length, equals(1));
      final totalStock = int.parse(active.first['stock'].toString());
      expect(totalStock, equals(180),
          reason: 'Retired variant stock (80) should be added to survivor (100)');
    });
  });

  // =========================================================================
  // VT-006 — Renaming a Custom Option Category
  // =========================================================================
  group('VT-006: Renaming a Custom Option Category', () {
    test('renaming Size to Dimensions propagates to variant option_values keys',
        () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');
      _addCustomOption(c, 'Size', ['Standard', 'Large']);
      _notifier(c).generateVariantsFromOptions(reconcile: false);

      // Configure prices
      final variants = List<Map<String, dynamic>>.from(_state(c).variants);
      for (var i = 0; i < variants.length; i++) {
        final opts = Map<String, String>.from(variants[i]['option_values'] ?? {});
        if (opts['Size'] == 'Standard') {
          variants[i] = Map<String, dynamic>.from(variants[i])
            ..['price'] = '12.00'..['stock'] = '40';
        } else if (opts['Size'] == 'Large') {
          variants[i] = Map<String, dynamic>.from(variants[i])
            ..['price'] = '16.00'..['stock'] = '20';
        }
      }
      _notifier(c).updateVariants(variants);

      // Rename Size → Dimensions
      _renameOption(c, 'Size', 'Dimensions');
      _notifier(c).generateVariantsFromOptions(reconcile: true);

      final active = _activeVariants(c);
      expect(active.length, equals(2));

      for (final v in active) {
        final opts = Map<String, String>.from(v['option_values'] ?? {});
        expect(opts.containsKey('Dimensions'), isTrue,
            reason: 'Renamed option key should appear as Dimensions');
        expect(opts.containsKey('Size'), isFalse,
            reason: 'Old key Size should no longer exist');
      }
    });

    test('Color option name cannot be mutated via updateOptionsSchema', () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');

      // Attempt to rename Color to Finish via the provider
      _renameOption(c, 'Color', 'Finish');

      // The provider guard in updateOptionsSchema should re-inject Color
      final colorOpt = _state(c).optionsSchema.firstWhere(
        (o) => o['name'].toString().trim().toLowerCase() == 'color',
        orElse: () => {},
      );
      expect(
        colorOpt.isNotEmpty,
        isTrue,
        reason: 'Color option should always exist in schema (guard re-injects it)',
      );
    });
  });

  // =========================================================================
  // VT-007 — State Integrity: Only One Deactivatable Variant Rule
  // =========================================================================
  group('VT-007: Edge Case Guards', () {
    test('cannot deactivate the sole active variant', () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');

      // Only one variant exists — the default
      expect(_activeVariants(c).length, equals(1));

      // Attempt to deactivate it via removeVariant (guarded to length > 1)
      _notifier(c).removeVariant(0);

      // Should still have 1 variant
      expect(
        _state(c).variants.length,
        equals(1),
        reason: 'removeVariant should be a no-op when only one variant exists',
      );
    });

    test('SKU generation never produces leading or trailing dashes', () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');
      _addColors(c, ['Pure white']);
      _notifier(c).generateVariantsFromOptions(reconcile: false);

      final active = _activeVariants(c);
      for (final v in active) {
        final sku = v['sku'].toString();
        expect(sku.startsWith('-'), isFalse,
            reason: 'SKU must not start with a dash: $sku');
        expect(sku.endsWith('-'), isFalse,
            reason: 'SKU must not end with a dash: $sku');
        expect(sku.contains('--'), isFalse,
            reason: 'SKU must not have double dashes: $sku');
      }
    });

    test('Cartesian product count is correct: 3 colors x 2 sizes = 6', () {
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');
      _addColors(c, ['Red', 'Green', 'Blue']);
      _addCustomOption(c, 'Size', ['S', 'M']);
      _notifier(c).generateVariantsFromOptions(reconcile: false);

      expect(_activeVariants(c).length, equals(6),
          reason: '3 colors × 2 sizes = 6 variants');
    });

    test('generating with no SKU set on sole variant throws no error', () {
      // The SKU validation lives in the UI layer, not the provider.
      // Provider itself should not crash on empty SKU.
      final c = _newProductContainer();
      addTearDown(c.dispose);

      _setTitle(c, 'Premium Coffee Mug');
      _addColors(c, ['Pure white']);

      expect(
        () => _notifier(c).generateVariantsFromOptions(reconcile: false),
        returnsNormally,
      );
    });
  });
}
