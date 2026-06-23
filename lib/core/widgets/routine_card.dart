import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/color_tokens.dart';
import '../theme/theme_provider.dart';

/// A card representing a shared routine item (e.g. "Morning Coffee", "Deep Work").
///
/// Displays an icon, title, description, time badge, and a completion toggle.
/// Used in the Routines tab matching the Stitch "Routine Tracker" design.
class RoutineCard extends ConsumerWidget {
  const RoutineCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.time,
    required this.isCompleted,
    required this.onToggle,
    this.onDelete,
    this.partnerCompleted = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final String time;
  final bool isCompleted;
  final bool partnerCompleted;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = themeMode == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompleted
            ? colors.primary.withValues(alpha: 0.1)
            : colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? colors.primary.withValues(alpha: 0.3)
              : colors.outlineVariant.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary, size: 24),
          ),
          const SizedBox(width: 14),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: colors.text,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: colors.primary.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    // Time badge — Using Tertiary (Laurel Leaf)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.tertiary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        time,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textMuted,
                  ),
                ),
                // Partner indicator — Using Secondary (Celeste)
                if (partnerCompleted) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          size: 14, color: colors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'Partner completed',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Toggle — Premium Pear Toggle
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? colors.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? colors.primary
                      : colors.outline.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: isCompleted ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ] : null,
              ),
              child: isCompleted
                  ? Icon(Icons.check_rounded,
                      color: colors.onPrimary, size: 18)
                  : null,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
