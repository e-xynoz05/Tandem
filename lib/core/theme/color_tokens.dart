import 'package:flutter/material.dart';

/// Tandem colour palette — Nature & Space (Pear, Rich Black, Laurel Leaf, Celeste, Ceiling White).
///
/// Usage: `ColorTokens.light.primary` or `ColorTokens.dark.primary`.
class ColorTokens {
  const ColorTokens._({
    required this.primary,
    required this.primaryContainer,
    required this.onPrimary,
    required this.onPrimaryContainer,
    required this.secondary,
    required this.secondaryContainer,
    required this.onSecondary,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.tertiaryContainer,
    required this.accent,
    required this.success,
    required this.error,
    required this.errorContainer,
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerLow,
    required this.border,
    required this.outline,
    required this.outlineVariant,
    required this.text,
    required this.textMuted,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.inversePrimary,
  });

  // Primary — Pear
  final Color primary;
  final Color primaryContainer;
  final Color onPrimary;
  final Color onPrimaryContainer;

  // Secondary — Celeste
  final Color secondary;
  final Color secondaryContainer;
  final Color onSecondary;
  final Color onSecondaryContainer;

  // Tertiary — Laurel Leaf
  final Color tertiary;
  final Color tertiaryContainer;

  // Functional
  final Color accent;
  final Color success;
  final Color error;
  final Color errorContainer;

  // Surfaces
  final Color background;
  final Color surface;
  final Color surfaceContainer;
  final Color surfaceContainerHigh;
  final Color surfaceContainerLow;

  // Borders
  final Color border;
  final Color outline;
  final Color outlineVariant;

  // Text
  final Color text;
  final Color textMuted;

  // Inverse
  final Color inverseSurface;
  final Color inverseOnSurface;
  final Color inversePrimary;

  // ─── Light palette (Custom: Pear, Rich Black, Celeste) ───────
  static const light = ColorTokens._(
    // Primary — Pear
    primary: Color(0xFFD1E231),
    primaryContainer: Color(0xFFE6F099),
    onPrimary: Color(0xFF010B13),
    onPrimaryContainer: Color(0xFF010B13),

    // Secondary — Celeste
    secondary: Color(0xFFB2FFFF),
    secondaryContainer: Color(0xFFD9FFFF),
    onSecondary: Color(0xFF010B13),
    onSecondaryContainer: Color(0xFF010B13),

    // Tertiary — Laurel Leaf
    tertiary: Color(0xFF939987),
    tertiaryContainer: Color(0xFFD2D6CB),

    // Functional
    accent: Color(0xFFD1E231),
    success: Color(0xFF939987),
    error: Color(0xFFBA1A1A),
    errorContainer: Color(0xFFFFDAD6),

    // Surfaces
    background: Color(0xFFE9EBE7), // Ceiling White
    surface: Color(0xFFFFFFFF),
    surfaceContainer: Color(0xFFF4F4F4),
    surfaceContainerHigh: Color(0xFFEEEEEE),
    surfaceContainerLow: Color(0xFFFAFAFA),

    // Borders
    border: Color(0xFFD2D6CB),
    outline: Color(0xFF939987),
    outlineVariant: Color(0xFFB2FFFF),

    // Text
    text: Color(0xFF010B13),
    textMuted: Color(0xFF5A5F54),

    // Inverse
    inverseSurface: Color(0xFF010B13),
    inverseOnSurface: Color(0xFFE9EBE7),
    inversePrimary: Color(0xFFD1E231),
  );

  // ─── Dark palette (Custom: Rich Black, Pear, Celeste) ───────
  static const dark = ColorTokens._(
    // Primary — Pear
    primary: Color(0xFFD1E231),
    primaryContainer: Color(0xFF3A4100),
    onPrimary: Color(0xFF010B13),
    onPrimaryContainer: Color(0xFFE6F099),

    // Secondary — Celeste
    secondary: Color(0xFFB2FFFF),
    secondaryContainer: Color(0xFF004F4F),
    onSecondary: Color(0xFF010B13),
    onSecondaryContainer: Color(0xFFD9FFFF),

    // Tertiary — Laurel Leaf
    tertiary: Color(0xFF939987),
    tertiaryContainer: Color(0xFF45483D),

    // Functional
    accent: Color(0xFFD1E231),
    success: Color(0xFFB2FFFF),
    error: Color(0xFFFFB4AB),
    errorContainer: Color(0xFF93000A),

    // Surfaces
    background: Color(0xFF010B13), // Rich Black
    surface: Color(0xFF0A141C),
    surfaceContainer: Color(0xFF141E26),
    surfaceContainerHigh: Color(0xFF1E2830),
    surfaceContainerLow: Color(0xFF050F16),

    // Borders
    border: Color(0xFF2C363E),
    outline: Color(0xFF939987),
    outlineVariant: Color(0xFF45483D),

    // Text
    text: Color(0xFFE9EBE7), // Ceiling White
    textMuted: Color(0xFF939987),

    // Inverse
    inverseSurface: Color(0xFFE9EBE7),
    inverseOnSurface: Color(0xFF010B13),
    inversePrimary: Color(0xFF3A4100),
  );
}
