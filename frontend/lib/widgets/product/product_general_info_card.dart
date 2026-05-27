import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/glass_card.dart';
import 'package:kloudshop/widgets/custom_input_field.dart';

class ProductGeneralInfoCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController slugController;
  final TextEditingController descriptionController;
  final bool isNewProduct;

  const ProductGeneralInfoCard({
    super.key,
    required this.titleController,
    required this.slugController,
    required this.descriptionController,
    required this.isNewProduct,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      title: 'General Information',
      icon: LucideIcons.info,
      color: AppTheme.brandEmerald500,
      children: [
        CustomInputField(
          label: 'Product Title',
          controller: titleController,
          hint: 'e.g. Classic Cotton T-Shirt',
          validator: (v) => v?.isEmpty == true ? 'Title is required' : null,
          onChanged: (v) {
            if (slugController.text.isEmpty ||
                (isNewProduct &&
                    slugController.text ==
                        titleController.text.toLowerCase().replaceAll(
                          ' ',
                          '-',
                        ))) {
              slugController.text = v.toLowerCase().replaceAll(
                RegExp(r'[^a-z0-9]'),
                '-',
              );
            }
          },
        ),
        const SizedBox(height: 20),
        CustomInputField(
          label: 'URL Slug',
          controller: slugController,
          hint: 'e.g. classic-cotton-t-shirt',
          prefixText: '/products/',
          validator: (v) => v?.isEmpty == true ? 'Slug is required' : null,
        ),
        const SizedBox(height: 20),
        CustomInputField(
          label: 'Description',
          controller: descriptionController,
          hint: 'Describe your product...',
          maxLines: 4,
        ),
      ],
    );
  }
}
