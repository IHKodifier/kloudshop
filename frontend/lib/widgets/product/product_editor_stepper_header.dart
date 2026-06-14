import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/theme/app_theme.dart';

class ProductEditorStepperHeader extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepTapped;

  const ProductEditorStepperHeader({
    super.key,
    required this.currentStep,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final steps = [
      'Basic Info & Media',
      'Logistics & SEO',
      'Options & Variants',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.grey[50],
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: List.generate(steps.length, (index) {
          final isActive = currentStep == index;
          final isCompleted = currentStep > index;

          return Expanded(
            child: InkWell(
              onTap: () => onStepTapped(index),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.brandEmerald500
                          : (isCompleted
                              ? AppTheme.brandEmerald500.withValues(
                                  alpha: 0.15,
                                )
                              : Colors.transparent),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive || isCompleted
                            ? AppTheme.brandEmerald500
                            : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(
                              LucideIcons.check,
                              size: 16,
                              color: AppTheme.brandEmerald500,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isActive
                                    ? Colors.white
                                    : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      steps[index],
                      style: TextStyle(
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isActive
                            ? AppTheme.brandEmerald500
                            : (isDark ? Colors.grey[400] : Colors.grey[600]),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (index < steps.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: isDark ? Colors.grey[700] : Colors.grey[300],
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
