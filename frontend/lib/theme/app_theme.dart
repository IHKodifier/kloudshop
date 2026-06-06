import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.navBackground,
    required this.onNavBackground,
    required this.onNavBackgroundMuted,
    required this.navActive,
    required this.textBody,
    required this.textPlaceholder,
    required this.borderSubtle,
  });

  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color navBackground;
  final Color onNavBackground;
  final Color onNavBackgroundMuted;
  final Color navActive;
  final Color textBody;
  final Color textPlaceholder;
  final Color borderSubtle;

  @override
  AppColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? navBackground,
    Color? onNavBackground,
    Color? onNavBackgroundMuted,
    Color? navActive,
    Color? textBody,
    Color? textPlaceholder,
    Color? borderSubtle,
  }) => AppColors(
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successContainer: successContainer ?? this.successContainer,
    warning: warning ?? this.warning,
    onWarning: onWarning ?? this.onWarning,
    warningContainer: warningContainer ?? this.warningContainer,
    navBackground: navBackground ?? this.navBackground,
    onNavBackground: onNavBackground ?? this.onNavBackground,
    onNavBackgroundMuted: onNavBackgroundMuted ?? this.onNavBackgroundMuted,
    navActive: navActive ?? this.navActive,
    textBody: textBody ?? this.textBody,
    textPlaceholder: textPlaceholder ?? this.textPlaceholder,
    borderSubtle: borderSubtle ?? this.borderSubtle,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t) ?? success,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t) ?? onSuccess,
      successContainer:
          Color.lerp(successContainer, other.successContainer, t) ??
          successContainer,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      onWarning: Color.lerp(onWarning, other.onWarning, t) ?? onWarning,
      warningContainer:
          Color.lerp(warningContainer, other.warningContainer, t) ??
          warningContainer,
      navBackground:
          Color.lerp(navBackground, other.navBackground, t) ?? navBackground,
      onNavBackground:
          Color.lerp(onNavBackground, other.onNavBackground, t) ??
          onNavBackground,
      onNavBackgroundMuted:
          Color.lerp(onNavBackgroundMuted, other.onNavBackgroundMuted, t) ??
          onNavBackgroundMuted,
      navActive: Color.lerp(navActive, other.navActive, t) ?? navActive,
      textBody: Color.lerp(textBody, other.textBody, t) ?? textBody,
      textPlaceholder:
          Color.lerp(textPlaceholder, other.textPlaceholder, t) ??
          textPlaceholder,
      borderSubtle:
          Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
    );
  }
}

class AppTheme {
  // Light Theme Constants
  static const Color brandTeal900 = Color(0xFF134E4A);
  static const Color brandTeal500 = Color(0xFF124B47);
  static const Color brandEmerald500 = Color(0xFF047857);
  static const Color brandEmerald600 = Color(0xFF065F46);
  static const Color brandEmerald50 = Color(0xFFECFDF5);
  static const Color brandTeal50 = Color(0xFFF0FDFA);

  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral700 = Color(0xFF374151);
  static const Color neutral900 = Color(0xFF111827);

  static TextTheme _buildTextTheme(
    TextTheme base,
    Color baseColor,
    Color mutedColor,
  ) {
    final displayStyle = GoogleFonts.outfit(color: baseColor);
    final bodyStyle = GoogleFonts.inter(color: mutedColor);

    return base.copyWith(
      displayLarge: displayStyle.copyWith(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.72,
      ),
      displayMedium: displayStyle.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.6,
      ),
      displaySmall: displayStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.48,
      ),
      headlineLarge: displayStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: displayStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: displayStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: displayStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: displayStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: displayStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: bodyStyle.copyWith(fontSize: 16),
      bodyMedium: bodyStyle.copyWith(fontSize: 14),
      bodySmall: bodyStyle.copyWith(fontSize: 12),
      labelLarge: displayStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: bodyStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: bodyStyle.copyWith(fontSize: 10, fontWeight: FontWeight.w500),
    );
  }

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: brandTeal500,
        onPrimary: neutral0,
        primaryContainer: brandTeal50,
        onPrimaryContainer: brandTeal900,
        secondary: brandTeal900,
        onSecondary: neutral0,
        tertiary: brandEmerald500,
        onTertiary: neutral0,
        surface: neutral0,
        onSurface: neutral900,
        surfaceContainerLowest: neutral50,
        surfaceContainerLow: neutral100,
        outline: neutral200,
        outlineVariant: neutral100,
        onSurfaceVariant: neutral500,
        error: Color(0xFFEF4444),
        errorContainer: Color(0xFFFEF2F2),
      ),
      chipTheme: const ChipThemeData(
        side: BorderSide(color: neutral200, width: 1.2),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        indicatorColor: brandTeal50,
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: brandTeal500, size: 24),
        unselectedIconTheme: IconThemeData(color: neutral500, size: 24),
        selectedLabelTextStyle: TextStyle(
          color: brandTeal500,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: TextStyle(color: neutral500),
      ),
      textTheme: _buildTextTheme(
        ThemeData.light().textTheme,
        neutral900,
        neutral700,
      ),
      extensions: const [
        AppColors(
          success: brandEmerald500,
          onSuccess: neutral0,
          successContainer: brandEmerald50,
          warning: Color(0xFFF59E0B),
          onWarning: Color(0xFF92400E),
          warningContainer: Color(0xFFFFFBEB),
          navBackground: brandTeal900,
          onNavBackground: neutral0,
          onNavBackgroundMuted: Color(0xFF99C4C2),
          navActive: brandTeal500,
          textBody: neutral700,
          textPlaceholder: neutral400,
          borderSubtle: neutral100,
        ),
      ],
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: brandTeal500,
        onPrimary: neutral0,
        surface: Color(0xFF0F172A), // Slate 900
        onSurface: Color(0xFFF8FAFC), // Slate 50
        surfaceContainerLowest: Color(0xFF020617), // Real deep black
        surfaceContainerLow: Color(0xFF1E293B), // Slate 800
        surfaceContainer: Color(0xFF334155), // Slate 700
        outline: Color(0xFF475569), // Slate 600
        onSurfaceVariant: Color(0xFFCBD5E1), // Slate 300
      ),
      chipTheme: const ChipThemeData(
        side: BorderSide(color: Color(0xFF475569), width: 1.2),
      ),
      primaryColor: brandTeal500,
      scaffoldBackgroundColor: const Color(0xFF020617),
      navigationRailTheme: const NavigationRailThemeData(
        indicatorColor: brandTeal500,
        backgroundColor: Color(0xFF0F172A),
        selectedIconTheme: IconThemeData(color: Colors.white, size: 24),
        unselectedIconTheme: IconThemeData(color: Color(0xFF94A3B8), size: 24),
        selectedLabelTextStyle: TextStyle(
          color: brandTeal500,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelTextStyle: TextStyle(color: Color(0xFF94A3B8)),
      ),
      cardColor: const Color(0xFF1E293B), // Slate 800
      hintColor: const Color(0xFF94A3B8), // Slate 400
      dividerColor: const Color(0xFF334155), // Slate 700
      textTheme: _buildTextTheme(
        ThemeData.dark().textTheme,
        const Color(0xFFF1F5F9),
        const Color(0xFFCBD5E1),
      ),
      extensions: const [
        AppColors(
          success: Color(0xFF34D399),
          onSuccess: neutral0,
          successContainer: Color(0xFF065F46),
          warning: Color(0xFFFBBF24),
          onWarning: Color(0xFF92400E),
          warningContainer: Color(0xFF451A03),
          navBackground: Color(0xFF0F172A),
          onNavBackground: neutral0,
          onNavBackgroundMuted: Color(0xFF94A3B8),
          navActive: brandTeal500,
          textBody: Color(0xFFE2E8F0),
          textPlaceholder: Color(0xFF64748B),
          borderSubtle: Color(0xFF334155),
        ),
      ],
    );
  }
}
