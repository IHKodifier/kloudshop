import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kloudshop/models/catalog.dart';
import 'package:kloudshop/providers/product_editor_provider.dart';
import 'package:kloudshop/widgets/product/product_classification_card.dart';
import 'package:kloudshop/widgets/product/product_seo_card.dart';

class ProductEditorLogisticsStep extends ConsumerStatefulWidget {
  final Product? product;
  const ProductEditorLogisticsStep({super.key, this.product});

  @override
  ConsumerState<ProductEditorLogisticsStep> createState() =>
      _ProductEditorLogisticsStepState();
}

class _ProductEditorLogisticsStepState
    extends ConsumerState<ProductEditorLogisticsStep> {
  late TextEditingController _weightController;
  late TextEditingController _lengthController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _metaTitleController;
  late TextEditingController _metaDescriptionController;
  late TextEditingController _minimumAgeController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(productEditorProvider(widget.product));
    _weightController = TextEditingController(text: state.weightValue);
    _lengthController = TextEditingController(text: state.lengthValue);
    _widthController = TextEditingController(text: state.widthValue);
    _heightController = TextEditingController(text: state.heightValue);
    _metaTitleController = TextEditingController(text: state.metaTitle);
    _metaDescriptionController = TextEditingController(
      text: state.metaDescription,
    );
    _minimumAgeController = TextEditingController(text: state.minimumAgeYears);

    _weightController.addListener(_onWeightChanged);
    _lengthController.addListener(_onLengthChanged);
    _widthController.addListener(_onWidthChanged);
    _heightController.addListener(_onHeightChanged);
    _metaTitleController.addListener(_onMetaTitleChanged);
    _metaDescriptionController.addListener(_onMetaDescriptionChanged);
    _minimumAgeController.addListener(_onMinimumAgeChanged);
  }

  void _onWeightChanged() {
    ref
        .read(productEditorProvider(widget.product).notifier)
        .updateWeightValue(_weightController.text);
  }

  void _onLengthChanged() {
    ref
        .read(productEditorProvider(widget.product).notifier)
        .updateLengthValue(_lengthController.text);
  }

  void _onWidthChanged() {
    ref
        .read(productEditorProvider(widget.product).notifier)
        .updateWidthValue(_widthController.text);
  }

  void _onHeightChanged() {
    ref
        .read(productEditorProvider(widget.product).notifier)
        .updateHeightValue(_heightController.text);
  }

  void _onMetaTitleChanged() {
    ref
        .read(productEditorProvider(widget.product).notifier)
        .updateMetaTitle(_metaTitleController.text);
  }

  void _onMetaDescriptionChanged() {
    ref
        .read(productEditorProvider(widget.product).notifier)
        .updateMetaDescription(_metaDescriptionController.text);
  }

  void _onMinimumAgeChanged() {
    ref
        .read(productEditorProvider(widget.product).notifier)
        .updateMinimumAgeYears(_minimumAgeController.text);
  }

  @override
  void dispose() {
    _weightController.removeListener(_onWeightChanged);
    _lengthController.removeListener(_onLengthChanged);
    _widthController.removeListener(_onWidthChanged);
    _heightController.removeListener(_onHeightChanged);
    _metaTitleController.removeListener(_onMetaTitleChanged);
    _metaDescriptionController.removeListener(_onMetaDescriptionChanged);
    _minimumAgeController.removeListener(_onMinimumAgeChanged);

    _weightController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _metaTitleController.dispose();
    _metaDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productEditorProvider(widget.product));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: ProductClassificationCard(
            status: state.status,
            onStatusChanged: (v) {
              ref
                  .read(productEditorProvider(widget.product).notifier)
                  .updateStatus(v);
            },
            isDigital: state.isDigital,
            onIsDigitalChanged: (v) {
              ref
                  .read(productEditorProvider(widget.product).notifier)
                  .updateIsDigital(v);
            },
            isPerishable: state.isPerishable,
            onIsPerishableChanged: (v) {
              ref
                  .read(productEditorProvider(widget.product).notifier)
                  .updateIsPerishable(v);
            },
            ageVerificationRequired: state.ageVerificationRequired,
            onAgeVerificationRequiredChanged: (v) {
              ref
                  .read(productEditorProvider(widget.product).notifier)
                  .updateAgeVerificationRequired(v);
              if (v) {
                if (_minimumAgeController.text.isEmpty) {
                  _minimumAgeController.text = '21';
                }
              } else {
                _minimumAgeController.clear();
              }
            },
            requiresPrescription: state.requiresPrescription,
            onRequiresPrescriptionChanged: (v) {
              ref
                  .read(productEditorProvider(widget.product).notifier)
                  .updateRequiresPrescription(v);
            },
            minimumAgeController: _minimumAgeController,
            weightController: _weightController,
            weightUnit: state.weightUnit,
            onWeightUnitChanged: (v) {
              ref
                  .read(productEditorProvider(widget.product).notifier)
                  .updateWeightUnit(v);
            },
            lengthController: _lengthController,
            widthController: _widthController,
            heightController: _heightController,
            dimensionUnit: state.dimensionUnit,
            onDimensionUnitChanged: (v) {
              ref
                  .read(productEditorProvider(widget.product).notifier)
                  .updateDimensionUnit(v);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 6,
          child: Column(
            children: [
              ProductSeoCard(
                metaTitleController: _metaTitleController,
                metaDescriptionController: _metaDescriptionController,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
