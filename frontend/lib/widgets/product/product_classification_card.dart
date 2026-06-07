import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/glass_card.dart';
import 'package:kloudshop/widgets/lottie_toggle.dart';

class ProductClassificationCard extends StatefulWidget {
  final String status;
  final ValueChanged<String> onStatusChanged;
  final bool isDigital;
  final ValueChanged<bool> onIsDigitalChanged;
  final bool isPerishable;
  final ValueChanged<bool> onIsPerishableChanged;
  final bool ageVerificationRequired;
  final ValueChanged<bool> onAgeVerificationRequiredChanged;
  final bool requiresPrescription;
  final ValueChanged<bool> onRequiresPrescriptionChanged;
  final TextEditingController minimumAgeController;
  final TextEditingController weightController;
  final String weightUnit;
  final ValueChanged<String> onWeightUnitChanged;
  final TextEditingController lengthController;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final String dimensionUnit;
  final ValueChanged<String> onDimensionUnitChanged;

  const ProductClassificationCard({
    super.key,
    required this.status,
    required this.onStatusChanged,
    required this.isDigital,
    required this.onIsDigitalChanged,
    required this.isPerishable,
    required this.onIsPerishableChanged,
    required this.ageVerificationRequired,
    required this.onAgeVerificationRequiredChanged,
    required this.requiresPrescription,
    required this.onRequiresPrescriptionChanged,
    required this.minimumAgeController,
    required this.weightController,
    required this.weightUnit,
    required this.onWeightUnitChanged,
    required this.lengthController,
    required this.widthController,
    required this.heightController,
    required this.dimensionUnit,
    required this.onDimensionUnitChanged,
  });

  @override
  State<ProductClassificationCard> createState() =>
      _ProductClassificationCardState();
}

class _ProductClassificationCardState extends State<ProductClassificationCard> {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      title: 'Status & Classification',
      icon: LucideIcons.tags,
      color: const Color(0xFFF59E0B),
      children: [
        DropdownButtonFormField<String>(
          initialValue: widget.status,
          decoration: InputDecoration(
            labelText: 'Product Status',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppTheme.brandEmerald500,
                width: 1.5,
              ),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'draft', child: Text('Draft')),
            DropdownMenuItem(value: 'published', child: Text('Published')),
            DropdownMenuItem(value: 'archived', child: Text('Archived')),
          ],
          onChanged: (v) {
            if (v != null) widget.onStatusChanged(v);
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 500;

            final digitalSwitch = LottieSwitchListTile(
              title: const Text('Digital Product'),
              subtitle: const Text(
                'This product is a file or service and does not require shipping',
              ),
              value: widget.isDigital,
              onChanged: widget.onIsDigitalChanged,
              contentPadding: EdgeInsets.zero,
            );

            final perishableSwitch = LottieSwitchListTile(
              title: const Text('Perishable Product'),
              subtitle: const Text(
                'Requires special shipping or temperature control; mandates batch tracking',
              ),
              value: widget.isPerishable,
              onChanged: widget.onIsPerishableChanged,
              contentPadding: EdgeInsets.zero,
            );

            final ageGatedColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LottieSwitchListTile(
                  title: const Text('Age-Gated Product'),
                  subtitle: const Text(
                    'Enforce age validation at checkout for restricted items',
                  ),
                  value: widget.ageVerificationRequired,
                  onChanged: widget.onAgeVerificationRequiredChanged,
                  contentPadding: EdgeInsets.zero,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: widget.ageVerificationRequired
                      ? Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: SizedBox(
                            width: 180,
                            child: TextFormField(
                              controller: widget.minimumAgeController,
                              decoration: InputDecoration(
                                labelText: 'MINIMUM AGE',
                                labelStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: AppTheme.brandEmerald500,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (widget.ageVerificationRequired) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  final age = int.tryParse(value);
                                  if (age == null || age <= 0) {
                                    return 'Must be > 0';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            );

            final prescriptionSwitch = LottieSwitchListTile(
              title: const Text('Prescription Required'),
              subtitle: const Text(
                'Require prescription validation and document upload',
              ),
              value: widget.requiresPrescription,
              onChanged: widget.onRequiresPrescriptionChanged,
              contentPadding: EdgeInsets.zero,
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  digitalSwitch,
                  const SizedBox(height: 12),
                  perishableSwitch,
                  const SizedBox(height: 12),
                  ageGatedColumn,
                  const SizedBox(height: 12),
                  prescriptionSwitch,
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: digitalSwitch),
                      const SizedBox(width: 24),
                      Expanded(child: perishableSwitch),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: ageGatedColumn),
                      const SizedBox(width: 24),
                      Expanded(child: prescriptionSwitch),
                    ],
                  ),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 8),
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutBack,
          child: !widget.isDigital
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Default Physical Shipping Specs',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Lottie.network(
                          'https://lottie.host/d19b48b5-55ff-4c28-bb73-90d569653a99/cSwQ8f00Tq.json',
                          width: 28,
                          height: 28,
                          repeat: false,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              LucideIcons.package,
                              size: 20,
                              color: AppTheme.brandEmerald500,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: widget.weightController,
                            decoration: const InputDecoration(
                              labelText: 'Default Weight',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            initialValue: widget.weightUnit,
                            decoration: const InputDecoration(
                              labelText: 'Unit',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'kg', child: Text('kg')),
                              DropdownMenuItem(value: 'lb', child: Text('lb')),
                            ],
                            onChanged: (v) {
                              if (v != null) widget.onWeightUnitChanged(v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 450;
                        return isNarrow
                            ? Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: widget.lengthController,
                                          decoration: const InputDecoration(
                                            labelText: 'Length',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) => setState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: TextFormField(
                                          controller: widget.widthController,
                                          decoration: const InputDecoration(
                                            labelText: 'Width',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) => setState(() {}),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: widget.heightController,
                                          decoration: const InputDecoration(
                                            labelText: 'Height',
                                            border: OutlineInputBorder(),
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (v) => setState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          initialValue: widget.dimensionUnit,
                                          decoration: const InputDecoration(
                                            labelText: 'Unit',
                                            border: OutlineInputBorder(),
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'cm',
                                              child: Text('cm'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'in',
                                              child: Text('in'),
                                            ),
                                          ],
                                          onChanged: (v) {
                                            if (v != null) {
                                              widget.onDimensionUnitChanged(v);
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: widget.lengthController,
                                      decoration: const InputDecoration(
                                        labelText: 'Length',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: widget.widthController,
                                      decoration: const InputDecoration(
                                        labelText: 'Width',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: widget.heightController,
                                      decoration: const InputDecoration(
                                        labelText: 'Height',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (v) => setState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      initialValue: widget.dimensionUnit,
                                      decoration: const InputDecoration(
                                        labelText: 'Unit',
                                        border: OutlineInputBorder(),
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'cm',
                                          child: Text('cm'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'in',
                                          child: Text('in'),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) {
                                          widget.onDimensionUnitChanged(v);
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              );
                      },
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
