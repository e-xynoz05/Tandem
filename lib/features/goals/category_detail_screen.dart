import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/router/route_names.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/goal_model.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/goal_service.dart';
import '../auth/auth_provider.dart';

/// Screen showing all goals and progress for a specific life category.
class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.category});

  final String category;

  IconData _getIcon() {
    switch (category.toLowerCase()) {
      case 'fitness': return Icons.fitness_center_rounded;
      case 'career': return Icons.work_outline_rounded;
      case 'relationships': return Icons.favorite_border_rounded;
      case 'learning': return Icons.book_outlined;
      case 'mindfulness': return Icons.spa_outlined;
      default: return Icons.star_border_rounded;
    }
  }

  Color _getColor() {
    switch (category.toLowerCase()) {
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
    final user = ref.watch(currentUserProvider);

    if (user == null) return const Scaffold(body: Center(child: Text('Please log in')));

    final categoryGoalsAsync = ref.watch(goalsByCategoryProvider(category));

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: themeColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                category[0].toUpperCase() + category.substring(1),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
              background: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.2,
                    child: Hero(
                      tag: 'category_icon_${category.toLowerCase()}',
                      child: Icon(_getIcon(), size: 140, color: Colors.white),
                    ),
                  ),
                  Positioned(
                    bottom: 60,
                    child: Text(
                      'Focus Area',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 2,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Goal List ───────────────────────────────────────────
          categoryGoalsAsync.when(
            data: (goals) {
              if (goals.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyCategoryState(colors: colors, themeColor: themeColor),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final goal = goals[index];
                      return _GoalCategoryTile(goal: goal, colors: colors, themeColor: themeColor);
                    },
                    childCount: goals.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            ),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed(
          RouteNames.createGoal,
          queryParameters: {'category': category},
        ),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Goal'),
      ),
    );
  }
}

class _GoalCategoryTile extends StatelessWidget {
  const _GoalCategoryTile({
    required this.goal,
    required this.colors,
    required this.themeColor,
  });

  final GoalModel goal;
  final ColorTokens colors;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: InkWell(
        onTap: () => context.pushNamed(RouteNames.goalDetails, pathParameters: {'id': goal.id}),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.description ?? '',
                        style: TextStyle(color: colors.textMuted, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(goal.progress * 100).toInt()}%',
                    style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progress,
                backgroundColor: themeColor.withValues(alpha: 0.1),
                color: themeColor,
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCategoryState extends StatelessWidget {
  const _EmptyCategoryState({required this.colors, required this.themeColor});
  final ColorTokens colors;
  final Color themeColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 64, color: themeColor.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          const Text(
            'New Horizons',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 12),
          Text(
            'You haven\'t set any goals in this category yet. Start your journey today!',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textMuted, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

/// Provider for goals filtered by category.
final goalsByCategoryProvider = StreamProvider.family<List<GoalModel>, String>((ref, category) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  return ref.watch(goalServiceProvider).watchGoals(user.uid).map((goals) {
    return goals.where((g) => g.category.name.toLowerCase() == category.toLowerCase()).toList();
  });
});
