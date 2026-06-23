import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/color_tokens.dart';
import '../theme/theme_provider.dart';

/// Specially themed progress bar for life categories.
class CategoryProgressBar extends ConsumerWidget {
  const CategoryProgressBar({
    super.key,
    required this.category,
    required this.progress,
    required this.onTap,
  });

  final String category;
  final double progress;
  final VoidCallback onTap;

  IconData _getIcon() {
    switch (category) {
      case 'fitness': return Icons.fitness_center_rounded;
      case 'career': return Icons.work_outline_rounded;
      case 'relationships': return Icons.favorite_border_rounded;
      case 'learning': return Icons.book_outlined;
      case 'mindfulness': return Icons.spa_outlined;
      default: return Icons.star_border_rounded;
    }
  }

  Color _getColor() {
    switch (category) {
      case 'fitness': return const Color(0xFF1A1C1A);
      case 'career': return const Color(0xFFA43B2F);
      case 'relationships': return const Color(0xFFFF7F6E);
      case 'learning': return const Color(0xFF1A1C1A);
      case 'mindfulness': return const Color(0xFF1A1C1A);
      default: return const Color(0xFFA43B2F);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;
    final themeColor = _getColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Hero(
                    tag: 'category_icon_$category',
                    child: Icon(_getIcon(), color: themeColor, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category[0].toUpperCase() + category.substring(1),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: colors.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  height: 8,
                  width: MediaQuery.of(context).size.width * 0.8 * progress,
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: themeColor.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
