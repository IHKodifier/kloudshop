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
  }) =>
      AppColors(
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
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      onNavBackground: Color.lerp(onNavBackground, other.onNavBackground, t)!,
      onNavBackgroundMuted: Color.lerp(onNavBackgroundMuted, other.onNavBackgroundMuted, t)!,
      navActive: Color.lerp(navActive, other.navActive, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textPlaceholder: Color.lerp(textPlaceholder, other.textPlaceholder, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
    );
  }
}

class AppTheme {
  // Light Theme Constants
  static const Color brandTeal900 = Color(0xFF134E4A);
  static const Color brandTeal500 = Color(0xFF14B8A6);
  static const Color brandEmerald500 = Color(0xFF10B981);
  static const Color brandEmerald600 = Color(0xFF059669);
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

  static TextTheme _buildTextTheme(Color baseColor, Color mutedColor) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: -0.72,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: -0.3,
        height: 1.2,
      ),
      headlineLarge: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.3,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: mutedColor,
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: mutedColor,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: mutedColor,
        height: 1.5,
      ),
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
      textTheme: _buildTextTheme(neutral900, neutral700),
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
        surface: Color(0xFF1E293B),
        onSurface: Color(0xFFF1F5F9),
        surfaceContainerLowest: Color(0xFF0F172A),
        outline: Color(0xFF334155),
        onSurfaceVariant: Color(0xFF94A3B8),
      ),
      textTheme: _buildTextTheme(const Color(0xFFF1F5F9), const Color(0xFFCBD5E1)),
      extensions: const [
        AppColors(
          success: Color(0xFF34D399),
          onSuccess: neutral0,
          successContainer: Color(0xFF065F46),
          warning: Color(0xFFFBBF24),
          onWarning: Color(0xFF92400E),
          warningContainer: Color(0xFF451A03),
          navBackground: brandTeal900,
          onNavBackground: neutral0,
          onNavBackgroundMuted: Color(0xFF99C4C2),
          navActive: brandTeal500,
          textBody: Color(0xFFCBD5E1),
          textPlaceholder: Color(0xFF64748B),
          borderSubtle: Color(0xFF1E293B),
        ),
      ],
    );
  }
}
