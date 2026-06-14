import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/hover_scale.dart';
import 'package:kloudshop/providers/product_editor_provider.dart';
import 'package:kloudshop/widgets/product/product_editor_info_step.dart';
import 'package:kloudshop/widgets/product/product_editor_logistics_step.dart';
import 'package:kloudshop/widgets/product/product_editor_variants_step.dart';
import 'package:kloudshop/widgets/product/product_editor_stepper_header.dart';

class ProductEditorView extends ConsumerStatefulWidget {
  final Product? product; // null if creating new
  const ProductEditorView({super.key, this.product});

  static Future<bool?> show(BuildContext context, {Product? product}) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss Product Editor',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        final dialogWidth = screenWidth > 900
            ? screenWidth * 0.82
            : screenWidth * 0.95;
        final dialogHeight = screenHeight * 0.9;

        return Center(
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ProductEditorView(product: product),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutQuad),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  ConsumerState<ProductEditorView> createState() => _ProductEditorViewState();
}

class _ProductEditorViewState extends ConsumerState<ProductEditorView> {
  final _formKey = GlobalKey<FormState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  int _currentStep = 0;

  void _showNotification(
    String message, {
    bool isError = false,
    bool isDeletion = false,
  }) {
    final bool isFailure = isError || isDeletion;
    final backgroundColor = isFailure
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFF0FDF4);
    final contentColor = isFailure
        ? const Color(0xFF991B1B)
        : const Color(0xFF166534);
    final borderColor = isFailure
        ? const Color(0xFFFECACA)
        : const Color(0xFFBBF7D0);

    _messengerKey.currentState?.clearSnackBars();
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFailure ? LucideIcons.alertCircle : LucideIcons.checkCircle2,
              color: contentColor,
              size: 16,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: TextStyle(
                  color: contentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: borderColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _showNotification(
        'Validation failed. Please check your inputs across all steps.',
        isError: true,
      );
      return;
    }

    final state = ref.read(productEditorProvider(widget.product));

    // Validate age gating compliance fields
    if (state.ageVerificationRequired) {
      final age = int.tryParse(state.minimumAgeYears);
      if (age == null || age <= 0) {
        _showNotification(
          'Error: Minimum age must be a positive number greater than zero.',
          isError: true,
        );
        return;
      }
    }

    // Validate variant pricing
    for (var v in state.variants) {
      final price = double.tryParse(v['price'].toString()) ?? 0.0;
      if (price < 0.0) {
        _showNotification(
          'Error: Variant price cannot be negative.',
          isError: true,
        );
        return;
      }
      final compareAtStr = v['compare_at_price'].toString();
      if (compareAtStr.isNotEmpty) {
        final compareAt = double.tryParse(compareAtStr);
        if (compareAt != null && compareAt < 0.0) {
          _showNotification(
            'Error: Variant compare-at price cannot be negative.',
            isError: true,
          );
          return;
        }
      }

      // Validate variant shipping overrides if enabled
      if (v['show_shipping_overrides'] == true) {
        final weightStr = v['weight_value']?.toString() ?? '';
        if (weightStr.isNotEmpty) {
          final weight = double.tryParse(weightStr);
          if (weight == null || weight <= 0.0) {
            _showNotification(
              'Error: Variant weight override must be a positive number greater than zero.',
              isError: true,
            );
            return;
          }
        }
        final lengthStr = v['length_value']?.toString() ?? '';
        if (lengthStr.isNotEmpty) {
          final length = double.tryParse(lengthStr);
          if (length == null || length <= 0.0) {
            _showNotification(
              'Error: Variant length override must be a positive number greater than zero.',
              isError: true,
            );
            return;
          }
        }
        final widthStr = v['width_value']?.toString() ?? '';
        if (widthStr.isNotEmpty) {
          final width = double.tryParse(widthStr);
          if (width == null || width <= 0.0) {
            _showNotification(
              'Error: Variant width override must be a positive number greater than zero.',
              isError: true,
            );
            return;
          }
        }
        final heightStr = v['height_value']?.toString() ?? '';
        if (heightStr.isNotEmpty) {
          final height = double.tryParse(heightStr);
          if (height == null || height <= 0.0) {
            _showNotification(
              'Error: Variant height override must be a positive number greater than zero.',
              isError: true,
            );
            return;
          }
        }
      }
    }

    final skus = state.variants.map((v) => v['sku'] as String).toList();
    if (skus.toSet().length != skus.length) {
      _showNotification(
        'Error: Each variant must have a unique SKU',
        isError: true,
      );
      return;
    }

    final changedSkuVariants = state.variants.where((v) {
      return v['variant_id'] != null &&
          v['sku'] != null &&
          v['original_sku'] != null &&
          v['sku'] != v['original_sku'];
    }).toList();

    bool emailSkuReport = true;
    if (changedSkuVariants.isNotEmpty) {
      bool? shouldProceed;
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'SKU Modifications Warning',
        barrierColor: Colors.black.withValues(alpha: 0.65),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim1, anim2) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
              final Color subtextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                backgroundColor: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.9) : Colors.white,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 550),
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red[500]!.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.warning_amber_rounded, color: Colors.red[600], size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'SKU Modifications Detected',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Outfit',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You have updated the SKU for one or more existing variants. This will change their deep-link URLs and could temporarily break linked Google Shopping campaigns, social merchandise tags, or bookmarks.',
                        style: TextStyle(
                          fontSize: 14,
                          color: subtextColor,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Modified SKUs:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontFamily: 'Outfit',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
                          ),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: changedSkuVariants.length,
                          separatorBuilder: (context, index) => const Divider(height: 12),
                          itemBuilder: (context, idx) {
                            final v = changedSkuVariants[idx];
                            final opts = Map<String, String>.from(v['option_values'] ?? {});
                            final optionStr = opts.values.join(' / ');
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    optionStr.isNotEmpty ? optionStr : 'Variant #${idx + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                      fontFamily: 'Outfit',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        v['original_sku'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.red[400],
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 12, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        v['sku'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.brandEmerald500,
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Checkbox for report
                      CheckboxListTile(
                        value: emailSkuReport,
                        onChanged: (val) {
                          setDialogState(() {
                            emailSkuReport = val ?? false;
                          });
                        },
                        title: const Text(
                          'I understand, send me a report with the old and new SKUs and URL slugs in my email and I will update my campaigns.',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Inter',
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppTheme.brandEmerald500,
                      ),
                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              shouldProceed = false;
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel & Edit',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              shouldProceed = true;
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.brandEmerald500,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            child: const Text(
                              'Proceed and Save',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Outfit',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (shouldProceed != true) {
        return; // User cancelled
      }
    }

    final success = await ref
        .read(productEditorProvider(widget.product).notifier)
        .save(ref.read(apiServiceProvider), widget.product?.id, emailSkuReport: emailSkuReport);

    if (success && mounted) {
      Navigator.pop(context, true);
    } else if (!success && mounted) {
      final errorMsg =
          ref.read(productEditorProvider(widget.product)).errorMessage ??
              'Unknown error occurred';
      _showNotification('Error: $errorMsg', isError: true);
    }
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(productEditorProvider(widget.product));

    Widget stepContent;
    switch (_currentStep) {
      case 0:
        stepContent = ProductEditorInfoStep(product: widget.product);
        break;
      case 1:
        stepContent = ProductEditorLogisticsStep(product: widget.product);
        break;
      case 2:
      default:
        stepContent = ProductEditorVariantsStep(product: widget.product);
        break;
    }

    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            widget.product == null ? 'New Product' : 'Edit Product',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(color: theme.dividerColor, height: 1),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: HoverScale(
                child: ElevatedButton.icon(
                  onPressed: state.isSaving ? null : _save,
                  icon: const Icon(
                    LucideIcons.save,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Save Product',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  ProductEditorStepperHeader(
                    currentStep: _currentStep,
                    onStepTapped: (index) {
                      if (index < _currentStep || _formKey.currentState!.validate()) {
                        setState(() {
                          _currentStep = index;
                        });
                      }
                    },
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeIn,
                        switchOutCurve: Curves.easeOut,
                        child: KeyedSubtree(
                          key: ValueKey<int>(_currentStep),
                          child: stepContent,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
                      border: Border(
                        top: BorderSide(color: theme.dividerColor),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentStep > 0)
                          ElevatedButton.icon(
                            onPressed: () => setState(() => _currentStep--),
                            icon: const Icon(LucideIcons.arrowLeft, size: 16),
                            label: const Text('Back'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? const Color(0xFF334155)
                                  : Colors.grey[200],
                              foregroundColor: isDark
                                  ? Colors.grey[200]
                                  : Colors.black87,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                side: BorderSide.none,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          )
                        else
                          const SizedBox.shrink(),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_currentStep < 2) {
                              if (_formKey.currentState!.validate()) {
                                setState(() => _currentStep++);
                              }
                            } else {
                              _save();
                            }
                          },
                          icon: Icon(
                            _currentStep < 2
                                ? LucideIcons.arrowRight
                                : LucideIcons.save,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            _currentStep < 2 ? 'Next' : 'Save Product',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.brandEmerald500,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (state.isSaving)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Center(
                    child: Card(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 24,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppTheme.brandEmerald500,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Saving Product...',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Syncing product details with database',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
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
        ),
      ),
    );
  }
}
