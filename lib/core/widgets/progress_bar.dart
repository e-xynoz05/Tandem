import 'package:flutter/material.dart';

/// A themed linear progress bar with rounded ends and an animated fill.
class TandemProgressBar extends StatelessWidget {
  const TandemProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  });

  /// Progress value between 0.0 and 1.0.
  final double value;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ??
        theme.colorScheme.primary.withValues(alpha: 0.12);
    final fg = foregroundColor ?? theme.colorScheme.primary;
    final radius = borderRadius ?? BorderRadius.circular(height / 2);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // Track
            Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: radius,
              ),
            ),
            // Fill
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: fg,
                  borderRadius: radius,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
