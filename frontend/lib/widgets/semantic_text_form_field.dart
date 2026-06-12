import 'package:flutter/material.dart';
import 'package:kloudshop/theme/app_theme.dart';

class SemanticTextFormField extends StatelessWidget {
  final String? initialValue;
  final TextEditingController? controller;
  final String? labelText;
  final String? helperText;
  final String? hintText;
  final bool enabled;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool obscureText;
  final Widget? suffixIcon;
  final int? maxLines;
  final String? errorText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;

  /// The icon to display inside the left shaded prefix container (e.g., LucideIcons.barcode).
  final IconData? prefixIcon;

  /// A custom widget (e.g. Text('$')) to display inside the left shaded prefix container instead of an icon.
  final Widget? prefixWidget;

  const SemanticTextFormField({
    super.key,
    this.initialValue,
    this.controller,
    this.labelText,
    this.helperText,
    this.hintText,
    this.enabled = true,
    this.textInputAction,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.prefixWidget,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLines = 1,
    this.errorText,
    this.focusNode,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final customInputStyle = theme.textTheme.bodyMedium;
    final customLabelStyle = theme.textTheme.bodySmall;
    const customPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);

    Widget? prefix;
    if (prefixWidget != null) {
      prefix = prefixWidget;
    } else if (prefixIcon != null) {
      prefix = Icon(
        prefixIcon,
        color: isDark ? const Color(0xFF34D399) : AppTheme.brandEmerald500,
        size: 20,
      );
    }

    Widget? prefixIconContainer;
    if (prefix != null) {
      prefixIconContainer = Container(
        width: 44,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFECFDF5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(3),
            bottomLeft: Radius.circular(3),
          ),
          border: Border(
            right: BorderSide(
              color: isDark ? const Color(0xFF475569) : const Color(0xFFA7F3D0),
              width: 1,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: prefix,
      );
    }

    return TextFormField(
      initialValue: initialValue,
      controller: controller,
      style: customInputStyle,
      enabled: enabled,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      obscureText: obscureText,
      maxLines: maxLines,
      focusNode: focusNode,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: customLabelStyle,
        helperText: helperText,
        hintText: hintText,
        errorText: errorText,
        prefixIcon: prefixIconContainer,
        prefixIconConstraints: prefixIconContainer != null
            ? const BoxConstraints(
                minWidth: 56,
                minHeight: 40,
                maxWidth: 56,
                maxHeight: 40,
              )
            : null,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
        contentPadding: customPadding,
      ),
    );
  }
}
