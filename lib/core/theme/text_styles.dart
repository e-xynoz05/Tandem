import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tandem typography scale — Plus Jakarta Sans.
///
/// Matches the Stitch "Shared Harmony" design system typography tokens.
class AppTextStyles {
  AppTextStyles._();

  static final String? _fontFamily =
      GoogleFonts.plusJakartaSans().fontFamily;

  /// Display — 40px, Bold, tight tracking
  static TextStyle display(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
        letterSpacing: -0.8,
      );

  /// Headline Large — 28px, SemiBold
  static TextStyle h1(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  /// Headline Medium — 20px, SemiBold
  static TextStyle h2(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.4,
      );

  /// Body Large — 18px, Regular
  static TextStyle bodyLarge(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.6,
      );

  /// Body Medium — 16px, Regular
  static TextStyle body(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.6,
      );

  /// Label Small — 12px, SemiBold, tracked
  static TextStyle caption(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.0,
        letterSpacing: 0.6,
      );

  /// Label Medium — 14px, Medium
  static TextStyle label(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      );
}
