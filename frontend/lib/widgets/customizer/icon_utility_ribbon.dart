import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:kloudshop/theme/app_theme.dart';
import 'package:kloudshop/providers/theme_providers.dart';

class IconUtilityRibbon extends ConsumerWidget {
  const IconUtilityRibbon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(customizerModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final dividerColor = theme.dividerColor;

    return Container(
      width: 48,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(right: BorderSide(color: dividerColor, width: 1)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          // Exit button (top)
          _RibbonButton(
            icon: LucideIcons.logOut,
            tooltip: 'Exit Editor',
            onTap: () {
              Navigator.of(context).maybePop();
            },
            isActive: false,
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Divider(color: dividerColor, height: 1),
          ),
          const SizedBox(height: 12),
          // Mode icons
          _RibbonButton(
            icon: LucideIcons.layoutList,
            tooltip: 'Sections',
            onTap: () {
              ref.read(customizerModeProvider.notifier).setMode(CustomizerMode.outline);
            },
            isActive: mode == CustomizerMode.outline,
          ),
          const SizedBox(height: 10),
          _RibbonButton(
            icon: LucideIcons.settings,
            tooltip: 'Theme Settings',
            onTap: () {
              ref.read(customizerModeProvider.notifier).setMode(CustomizerMode.settings);
            },
            isActive: mode == CustomizerMode.settings,
          ),
          const SizedBox(height: 10),
          _RibbonButton(
            icon: LucideIcons.grid3x3,
            tooltip: 'App Embeds',
            onTap: () {
              ref.read(customizerModeProvider.notifier).setMode(CustomizerMode.embeds);
            },
            isActive: mode == CustomizerMode.embeds,
          ),
        ],
      ),
    );
  }
}

class _RibbonButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isActive;

  const _RibbonButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeBgColor = AppTheme.brandEmerald500.withOpacity(0.15);
    final activeIconColor = AppTheme.brandEmerald500;
    final inactiveIconColor = theme.hintColor;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isActive ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? activeIconColor : inactiveIconColor,
          ),
        ),
      ),
    );
  }
}
