import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class ThemeToggleSwitch extends StatelessWidget {
  final bool value; // true = dark mode, false = light mode
  final ValueChanged<bool> onChanged;

  const ThemeToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Clean track colors
    final lightTrackColor = theme.brightness == Brightness.dark
        ? const Color(0xFF334155) // Slate-700
        : const Color(0xFFE2E8F0); // Slate-200
        
    final darkTrackColor = const Color(0xFF1E293B); // Slate-800

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: 58,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: value ? darkTrackColor : lightTrackColor,
            border: Border.all(
              color: value ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Faint Moon icon on the left (visible when thumb is on the right / Light Mode)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: value ? 0.0 : 0.45,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      LucideIcons.moon,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),

              // Faint Sun icon on the right (visible when thumb is on the left / Dark Mode)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: value ? 0.45 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(
                      LucideIcons.sun,
                      size: 13,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),

              // Sliding Thumb
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    alignment: value ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: value ? const Color(0xFF0F172A) : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: value
                              ? const Icon(
                                  LucideIcons.moon,
                                  key: ValueKey('moon_icon'),
                                  size: 13,
                                  color: Color(0xFFE2E8F0),
                                )
                              : const Icon(
                                  LucideIcons.sun,
                                  key: ValueKey('sun_icon'),
                                  size: 13,
                                  color: Color(0xFFD97706), // Amber-600
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
