import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/models/daily_score_model.dart';
import '../stats/stats_provider.dart';
import '../routines/routine_provider.dart';

/// Growth tab — matching the Stitch "Growth Graph" screen.
///
/// "Mutual Growth" — tracking shared journey and individual progress
/// with a Symmetry Map (radar chart), category breakdown with change
/// indicators, and shared goal progress.
class GrowthScreen extends ConsumerWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colors = themeMode == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    // Use Routine-based progress instead of Task-based progress
    final progress = ref.watch(routineProgressProvider);
    
    // Map the graph according to work from routine
    final dailyScoresAsync = ref.watch(routineHistoryProvider);
    final partnerScoresAsync = ref.watch(partnerRoutineHistoryProvider);
    
    final stats = ref.watch(computedStatsProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
              decoration: BoxDecoration(
                color: colors.background,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mutual Growth',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: colors.text,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tracking your shared journey.',
                              style: TextStyle(
                                fontSize: 14,
                                color: colors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Life Insight Card ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _LifeInsightCard(stats: stats, colors: colors),
            ),
          ),

          // ─── Symmetry Map (Radar) ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: _SymmetryMap(
                progress: progress,
                partnerHistory: partnerScoresAsync.value ?? [],
                colors: colors,
              ),
            ),
          ),

          // ─── Category Breakdown ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Text(
                'Category Breakdown',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                progress.entries.map((entry) {
                  return _CategoryBreakdownCard(
                    category: entry.key,
                    progress: entry.value,
                    colors: colors,
                  );
                }).toList(),
              ),
            ),
          ),

          // ─── Shared Goal Progress ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: _SharedGoalCard(colors: colors),
            ),
          ),

          // ─── 30-Day Momentum Chart ────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: _MomentumChart(
                dailyScores: dailyScoresAsync.value ?? [],
                partnerScores: partnerScoresAsync.value ?? [],
                colors: colors,
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }
}

// ─── Life Insight Card ──────────────────────────────────────────────
class _LifeInsightCard extends StatelessWidget {
  const _LifeInsightCard({required this.stats, required this.colors});
  final StatsStats stats;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;
    Color color;

    if (stats.overallLifeScore < 0.4) {
      message =
          'Your ${stats.weakestCategory} needs some love. Small steps matter!';
      icon = Icons.trending_up_rounded;
      color = colors.primary;
    } else if (stats.overallLifeScore > 0.7) {
      message = 'Incredible harmony! All areas are thriving. 🌱';
      icon = Icons.spa_rounded;
      color = colors.secondary;
    } else {
      message =
          'Great momentum in ${stats.strongestCategory}. Keep building!';
      icon = Icons.auto_awesome_rounded;
      color = colors.tertiary;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Symmetry Map (Radar Chart) ─────────────────────────────────────
class _SymmetryMap extends StatelessWidget {
  const _SymmetryMap({
    required this.progress,
    required this.partnerHistory,
    required this.colors,
  });

  final Map<String, double> progress;
  final List<DailyScoreModel> partnerHistory;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    final categories = [
      'fitness',
      'career',
      'relationships',
      'learning',
      'mindfulness'
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Symmetry Map',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: colors.text,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: RadarChart(
              RadarChartData(
                dataSets: [
                  // User data — Primary (Pear)
                  RadarDataSet(
                    fillColor: colors.primary.withValues(alpha: 0.2),
                    borderColor: colors.primary,
                    borderWidth: 2,
                    entryRadius: 3,
                    dataEntries: categories
                        .map((cat) => RadarEntry(
                            value: (progress[cat] ?? 0.0) * 100))
                        .toList(),
                  ),
                  // Partner data — Secondary (Celeste)
                  if (partnerHistory.isNotEmpty)
                    RadarDataSet(
                      fillColor: colors.secondary.withValues(alpha: 0.15),
                      borderColor: colors.secondary,
                      borderWidth: 2,
                      entryRadius: 2,
                      dataEntries: categories.map((cat) {
                        final lastScore = partnerHistory.last;
                        double val = 0;
                        if (cat == 'fitness') val = lastScore.fitness;
                        if (cat == 'career') val = lastScore.career;
                        if (cat == 'relationships') {
                          val = lastScore.relationships;
                        }
                        if (cat == 'learning') val = lastScore.learning;
                        if (cat == 'mindfulness') val = lastScore.mindfulness;
                        return RadarEntry(value: val * 100);
                      }).toList(),
                    ),
                ],
                radarBorderData: const BorderSide(color: Colors.transparent),
                radarBackgroundColor: Colors.transparent,
                gridBorderData: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.3),
                    width: 1),
                tickBorderData:
                    const BorderSide(color: Colors.transparent),
                ticksTextStyle:
                    const TextStyle(color: Colors.transparent),
                getTitle: (index, angle) {
                  final cat = categories[index];
                  final icons = {
                    'fitness': '💪',
                    'career': '🎯',
                    'relationships': '❤️',
                    'learning': '📚',
                    'mindfulness': '🧘',
                  };
                  return RadarChartTitle(
                    text: icons[cat] ??
                        cat[0].toUpperCase() + cat.substring(0, 3),
                    angle: angle,
                  );
                },
                titlePositionPercentageOffset: 0.15,
                titleTextStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ChartLegend(colors: colors, showPartner: partnerHistory.isNotEmpty),
        ],
      ),
    );
  }
}

// ─── Category Breakdown Card ────────────────────────────────────────
class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({
    required this.category,
    required this.progress,
    required this.colors,
  });

  final String category;
  final double progress;
  final ColorTokens colors;

  int get _changePercent {
    switch (category) {
      case 'fitness':
        return 12;
      case 'career':
        return 5;
      case 'relationships':
        return 24;
      case 'learning':
        return 8;
      case 'mindfulness':
        return -2;
      default:
        return 0;
    }
  }

  IconData get _icon {
    switch (category) {
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'career':
        return Icons.work_rounded;
      case 'relationships':
        return Icons.favorite_rounded;
      case 'learning':
        return Icons.menu_book_rounded;
      case 'mindfulness':
        return Icons.self_improvement_rounded;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = _changePercent >= 0;
    final changeColor = isPositive ? colors.secondary : colors.primary;
    final displayName =
        category[0].toUpperCase() + category.substring(1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon, color: colors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) =>
                      LinearProgressIndicator(
                    value: value,
                    backgroundColor:
                        colors.outlineVariant.withValues(alpha: 0.2),
                    color: colors.primary,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 12,
                    color: changeColor,
                  ),
                  Text(
                    '${_changePercent.abs()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: changeColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared Goal Card ───────────────────────────────────────────────
class _SharedGoalCard extends StatelessWidget {
  const _SharedGoalCard({required this.colors});
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.secondary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Shared Goal',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Meditate together 10 times',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: 0.7,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '7 of 10 completed',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                '70%',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 30-Day Momentum Chart ──────────────────────────────────────────
class _MomentumChart extends StatelessWidget {
  const _MomentumChart({
    required this.dailyScores,
    required this.partnerScores,
    required this.colors,
  });

  final List<DailyScoreModel> dailyScores;
  final List<DailyScoreModel> partnerScores;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '30-Day Momentum',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: colors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 7,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('D${value.toInt()}',
                              style: TextStyle(
                                  color: colors.textMuted, fontSize: 9)),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // User line — Primary
                  LineChartBarData(
                    spots: dailyScores
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                            e.key.toDouble(), e.value.overall * 100))
                        .toList(),
                    isCurved: true,
                    color: colors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  // Partner line — Secondary
                  if (partnerScores.isNotEmpty)
                    LineChartBarData(
                      spots: partnerScores
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                              e.key.toDouble(), e.value.overall * 100))
                          .toList(),
                      isCurved: true,
                      color: colors.secondary,
                      barWidth: 2,
                      dashArray: [5, 5],
                      dotData: const FlDotData(show: false),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ChartLegend(colors: colors, showPartner: partnerScores.isNotEmpty),
        ],
      ),
    );
  }
}

// ─── Chart Legend ───────────────────────────────────────────────────
class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.colors, this.showPartner = false});
  final ColorTokens colors;
  final bool showPartner;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(label: 'You', color: colors.primary),
        if (showPartner) ...[
          const SizedBox(width: 20),
          _LegendDot(label: 'Partner', color: colors.secondary),
        ],
      ],
    );
  }
}

class _LegendDot extends ConsumerWidget {
  const _LegendDot({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? ColorTokens.dark.textMuted
                    : ColorTokens.light.textMuted)),
      ],
    );
  }
}
