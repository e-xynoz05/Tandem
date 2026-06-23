import 'package:flutter/material.dart';

/// Convenience extensions on core Dart / Flutter types.

extension DateTimeX on DateTime {
  /// `true` if this [DateTime] is today in local time.
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// `true` if this [DateTime] is yesterday in local time.
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }
}

extension ContextX on BuildContext {
  /// Shorthand for `Theme.of(this)`.
  ThemeData get theme => Theme.of(this);

  /// Shorthand for `Theme.of(this).colorScheme`.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Shorthand for `Theme.of(this).textTheme`.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Shorthand for `MediaQuery.sizeOf(this)`.
  Size get screenSize => MediaQuery.sizeOf(this);
}

extension StringX on String {
  /// Capitalises the first character of the string.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
