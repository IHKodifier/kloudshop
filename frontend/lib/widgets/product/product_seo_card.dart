import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/widgets/glass_card.dart';
import 'package:kloudshop/widgets/custom_input_field.dart';

class ProductSeoCard extends StatelessWidget {
  final TextEditingController metaTitleController;
  final TextEditingController metaDescriptionController;

  const ProductSeoCard({
    super.key,
    required this.metaTitleController,
    required this.metaDescriptionController,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      title: 'Search Engine Optimization',
      icon: LucideIcons.search,
      color: const Color(0xFF6366F1),
      children: [
        CustomInputField(
          label: 'Meta Title',
          controller: metaTitleController,
          hint: 'Keep it under 60 characters',
        ),
        const SizedBox(height: 12),
        CustomInputField(
          label: 'Meta Description',
          controller: metaDescriptionController,
          hint: 'Brief summary for search results',
          isResizable: true,
        ),
      ],
    );
  }
}
