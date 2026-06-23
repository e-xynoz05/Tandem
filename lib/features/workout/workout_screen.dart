import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import 'workout_provider.dart';

/// Workout tab — matching the Stitch "Workout Decider" screen.
///
/// "What's the move today, team?" — a shared workout planning interface
/// with mode selection (Solo/Duo/Guided), duration/intensity controls,
/// and suggested routines.
class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  int _selectedMode = 1; // 0=Solo, 1=Duo, 2=Guided
  double _duration = 30;
  double _intensity = 0.6;

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(workoutPlansProvider);
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Header ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
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
                              "What's the move\ntoday, team?",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Time to sync up and break a sweat.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.fitness_center_rounded,
                            color: Colors.white, size: 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Mode Selector ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workout Mode',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _ModeChip(
                        label: 'Solo',
                        icon: Icons.person_rounded,
                        isSelected: _selectedMode == 0,
                        onTap: () => setState(() => _selectedMode = 0),
                        colors: colors,
                      ),
                      const SizedBox(width: 10),
                      _ModeChip(
                        label: 'Duo',
                        icon: Icons.people_rounded,
                        isSelected: _selectedMode == 1,
                        onTap: () => setState(() => _selectedMode = 1),
                        colors: colors,
                      ),
                      const SizedBox(width: 10),
                      _ModeChip(
                        label: 'Guided',
                        icon: Icons.headset_rounded,
                        isSelected: _selectedMode == 2,
                        onTap: () => setState(() => _selectedMode = 2),
                        colors: colors,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ─── Duration & Intensity ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Duration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Duration',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: colors.text,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_duration.toInt()} min',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: colors.primary,
                        inactiveTrackColor:
                            colors.primary.withValues(alpha: 0.12),
                        thumbColor: colors.primary,
                        overlayColor: colors.primary.withValues(alpha: 0.1),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _duration,
                        min: 10,
                        max: 90,
                        divisions: 8,
                        onChanged: (v) => setState(() => _duration = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Intensity
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Intensity',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: colors.text,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _intensityLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: colors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: colors.secondary,
                        inactiveTrackColor:
                            colors.secondary.withValues(alpha: 0.12),
                        thumbColor: colors.secondary,
                        overlayColor:
                            colors.secondary.withValues(alpha: 0.1),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _intensity,
                        min: 0,
                        max: 1,
                        divisions: 4,
                        onChanged: (v) =>
                            setState(() => _intensity = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Suggested Routines ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(
                'Suggested Routines',
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
              delegate: SliverChildListDelegate([
                _SuggestedRoutineCard(
                  title: 'Evening Flow',
                  subtitle: '30 min · Light Yoga',
                  icon: Icons.self_improvement_rounded,
                  accentColor: colors.secondary,
                  colors: colors,
                  onTap: () {},
                ),
                _SuggestedRoutineCard(
                  title: 'Park Loop',
                  subtitle: '45 min · Moderate Run',
                  icon: Icons.directions_run_rounded,
                  accentColor: colors.primary,
                  colors: colors,
                  onTap: () {},
                ),
                _SuggestedRoutineCard(
                  title: 'Power Circuit',
                  subtitle: '25 min · High Intensity',
                  icon: Icons.flash_on_rounded,
                  accentColor: colors.tertiary,
                  colors: colors,
                  onTap: () {},
                ),
              ]),
            ),
          ),

          // ─── Today's Plan (existing data) ─────────────────────
          plansAsync.when(
            data: (plans) {
              final today = DateTime.now().weekday - 1;
              final todayPlans =
                  plans.where((p) => p.assignedDays.contains(today)).toList();

              if (todayPlans.isEmpty) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: _TodayPlanCard(
                      plan: todayPlans.first, colors: colors),
                ),
              );
            },
            loading: () =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) =>
                const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // ─── Start Button ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Start workout session
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    "Let's Go! 🔥",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
      ),
    );
  }

  String get _intensityLabel {
    if (_intensity <= 0.25) return 'Light';
    if (_intensity <= 0.5) return 'Moderate';
    if (_intensity <= 0.75) return 'Intense';
    return 'Maximum';
  }
}

// ─── Mode Chip ──────────────────────────────────────────────────────
class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary
                : colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? null
                : Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.3)),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : colors.textMuted,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : colors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Suggested Routine Card ─────────────────────────────────────────
class _SuggestedRoutineCard extends StatelessWidget {
  const _SuggestedRoutineCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.colors,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final ColorTokens colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: colors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}

// ─── Today's Plan Card ──────────────────────────────────────────────
class _TodayPlanCard extends ConsumerWidget {
  const _TodayPlanCard({required this.plan, required this.colors});
  final dynamic plan;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const Text('YOUR PLAN',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(plan.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('${plan.exercises.length} Exercises',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(activeSessionProvider.notifier).startSession(plan);
                context.pushNamed('active-session');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: colors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Start Session',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
