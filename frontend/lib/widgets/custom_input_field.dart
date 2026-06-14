import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/widgets/custom_tooltip_button.dart';
import 'package:kloudshop/widgets/rich_text_toolbar.dart';

class CustomInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? prefixText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final String? tooltipMessage;
  final bool hasRichTextToolbar;
  final bool isResizable;

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
    this.isResizable = false,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  double _height = 140.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget inputField;
    if (widget.hasRichTextToolbar) {
      inputField = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichTextToolbar(controller: widget.controller),
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              maxLines: null,
              minLines: null,
              expands: true,
              onChanged: widget.onChanged,
              validator: widget.validator,
              decoration: InputDecoration(
                hintText: widget.hint,
                prefixText: widget.prefixText,
                alignLabelWithHint: true,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                  borderSide: BorderSide(
                    color: AppTheme.brandEmerald500,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (widget.isResizable) {
      inputField = TextFormField(
        controller: widget.controller,
        maxLines: null,
        minLines: null,
        expands: true,
        onChanged: widget.onChanged,
        validator: widget.validator,
        decoration: InputDecoration(
          hintText: widget.hint,
          prefixText: widget.prefixText,
          alignLabelWithHint: true,
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
    } else {
      inputField = TextFormField(
        controller: widget.controller,
        maxLines: widget.maxLines,
        onChanged: widget.onChanged,
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.tooltipMessage != null ? null : widget.label,
          hintText: widget.hint,
          prefixText: widget.prefixText,
          alignLabelWithHint: widget.maxLines > 1,
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
    }

    if (widget.isResizable) {
      inputField = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _height,
            child: inputField,
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragUpdate: (details) {
              setState(() {
                _height = (_height + details.delta.dy).clamp(80.0, 600.0);
              });
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeUpDown,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Center(
                  child: Icon(
                    LucideIcons.gripHorizontal,
                    size: 16,
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (widget.tooltipMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(width: 8),
              CustomTooltipButton(message: widget.tooltipMessage!),
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
