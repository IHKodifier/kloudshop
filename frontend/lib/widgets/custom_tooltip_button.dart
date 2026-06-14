import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/theme/app_theme.dart';

class CustomTooltipButton extends StatelessWidget {
  final String message;
  const CustomTooltipButton({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: message,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.brandEmerald500.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      textStyle: TextStyle(
        color: isDark ? Colors.grey[200] : Colors.grey[800],
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontFamily: 'Outfit',
      ),
      preferBelow: false,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: const Icon(
            LucideIcons.info,
            size: 18,
            color: AppTheme.brandEmerald500,
          ),
        ),
      ),
    );
  }
}
