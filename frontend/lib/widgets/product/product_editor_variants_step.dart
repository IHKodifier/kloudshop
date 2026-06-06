import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/providers/product_editor_provider.dart';
import 'package:kloudshop/services/file_uploader.dart';
import 'package:kloudshop/services/api_service.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/product/product_options_card.dart';
import 'package:kloudshop/widgets/product/product_variants_section.dart';

class ProductEditorVariantsStep extends ConsumerStatefulWidget {
  final Product? product;
  const ProductEditorVariantsStep({super.key, this.product});

  @override
  ConsumerState<ProductEditorVariantsStep> createState() =>
      _ProductEditorVariantsStepState();
}

class _ProductEditorVariantsStepState
    extends ConsumerState<ProductEditorVariantsStep> {
  late final FileUploader _uploader;
  int _lastVariantCount = 0;
  bool _showVariantChangeAnimation = false;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _uploader = MockFileUploader(
      apiUpload: (bytes, name) =>
          ref.read(apiServiceProvider).uploadMedia(bytes, name),
    );
    final state = ref.read(productEditorProvider(widget.product));
    _lastVariantCount = state.variants.length;
  }

  void _showNotification(
    BuildContext context,
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

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
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

  void _handleGenerate(
    BuildContext context,
    WidgetRef ref,
    ProductEditorState state,
    ProductEditorNotifier notifier,
  ) async {
    final activeOptions = state.optionsSchema.where((opt) {
      final name = (opt['name'] as String? ?? '').trim();
      final values = List<dynamic>.from(opt['values'] ?? []);
      return name.isNotEmpty && values.isNotEmpty;
    }).toList();

    if (activeOptions.isEmpty) return;

    setState(() {
      _isGenerating = true;
    });

    // Yield a frame to let the loading spinner render on the button
    await Future.delayed(const Duration(milliseconds: 100));

    List<Map<String, String>> cartesianProduct(
      List<Map<String, dynamic>> options,
      int index,
    ) {
      if (index == options.length) {
        return [{}];
      }

      final currentOpt = options[index];
      final currentName = currentOpt['name'] as String;
      final currentValues = List<String>.from(currentOpt['values'] ?? []);

      final subProducts = cartesianProduct(options, index + 1);
      final List<Map<String, String>> result = [];

      for (var val in currentValues) {
        for (var subProduct in subProducts) {
          result.add({currentName: val, ...subProduct});
        }
      }
      return result;
    }

    final permutations = cartesianProduct(activeOptions, 0);
    final List<String> names = permutations
        .map((perm) => perm.values.join(' / '))
        .toList();

    notifier.generateVariantsFromOptions();

    if (mounted) {
      setState(() {
        _isGenerating = false;
      });
    }

    if (!context.mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Variants Generated',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  child: Lottie.network(
                    'https://lottie.host/c5c8e31a-e8f0-466d-9db8-5d2df1c469f6/mH9y7G1j7C.json',
                    repeat: false,
                    frameBuilder: (context, child, composition) {
                      if (composition == null) {
                        return const Center(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: AppTheme.brandEmerald500,
                            ),
                          ),
                        );
                      }
                      return child;
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        LucideIcons.checkCircle2,
                        size: 80,
                        color: AppTheme.brandEmerald500,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Variants Generated Successfully!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Created ${permutations.length} variants:',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  width: double.maxFinite,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : Colors.grey[200]!,
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: names.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 8),
                    itemBuilder: (context, idx) {
                      return Row(
                        children: [
                          const Icon(
                            LucideIcons.check,
                            color: AppTheme.brandEmerald500,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              names[idx],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.brandEmerald500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  void _addVariant(ProductEditorNotifier notifier) {
    notifier.addVariant();
    _showNotification(context, 'Variant added');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productEditorProvider(widget.product));
    final notifier = ref.read(productEditorProvider(widget.product).notifier);

    if (state.variants.length != _lastVariantCount) {
      final hasPreviousCount = _lastVariantCount > 0;
      _lastVariantCount = state.variants.length;
      if (hasPreviousCount) {
        _showVariantChangeAnimation = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {});
          }
        });
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted) {
            setState(() {
              _showVariantChangeAnimation = false;
            });
          }
        });
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductOptionsCard(
          optionsSchema: state.optionsSchema,
          isGenerating: _isGenerating,
          onGenerateVariants: () => _handleGenerate(context, ref, state, notifier),
          onChanged: (newSchema) {
            notifier.updateOptionsSchema(newSchema);
          },
        ),
        const SizedBox(height: 16),
        ProductVariantsSection(
          variants: state.variants,
          optionsSchema: state.optionsSchema,
          isNewProduct: widget.product == null,
          isDigital: state.isDigital,
          uploader: _uploader,
          showVariantChangeAnimation: _showVariantChangeAnimation,
          onAddVariant: () => _addVariant(notifier),
          onChanged: () {
            notifier.updateVariants(List.from(state.variants));
          },
        ),
      ],
    );
  }
}
