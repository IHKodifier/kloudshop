import 'package:flutter/material.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/custom_tooltip_button.dart';
import 'package:kloudshop/widgets/rich_text_toolbar.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? prefixText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final String? tooltipMessage;
  final bool hasRichTextToolbar;

  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.prefixText,
    this.validator,
    this.onChanged,
    this.tooltipMessage,
    this.hasRichTextToolbar = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget inputField = TextFormField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: tooltipMessage != null ? null : label,
        hintText: hint,
        prefixText: prefixText,
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppTheme.brandEmerald500,
            width: 1.5,
          ),
        ),
      ),
    );

    if (hasRichTextToolbar) {
      inputField = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichTextToolbar(controller: controller),
          inputField,
        ],
      );
    }

    if (tooltipMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              CustomTooltipButton(message: tooltipMessage!),
            ],
          ),
          const SizedBox(height: 8),
          inputField,
        ],
      );
    }

    return inputField;
  }
}
