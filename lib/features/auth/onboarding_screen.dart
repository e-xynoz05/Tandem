import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import 'auth_provider.dart';

/// Onboarding screen — 3-slide PageView introducing core features.
///
/// Slide 1: Welcome message and categories
/// Slide 2: Duo features introduction
/// Slide 3: Consistency and streaks
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    ref.read(authProvider.notifier).completeOnboarding();
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ─── Skip button ─────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // ─── Page content ────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _Slide1(colors: colors),
                  _Slide2(colors: colors),
                  _Slide3(colors: colors),
                ],
              ),
            ),

            // ─── Dots + CTA ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page dots
                  Row(
                    children: List.generate(3, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? colors.primary
                              : colors.textMuted.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // CTA button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _onNext,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                      ),
                      child: Text(
                        _currentPage == 2 ? "Let's go" : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Slide 1: "Track every part of your life"
// ═══════════════════════════════════════════════════════════════════

class _Slide1 extends StatelessWidget {
  const _Slide1({required this.colors});
  final ColorTokens colors;

  static const _categories = <_CategoryIcon>[
    _CategoryIcon(Icons.fitness_center_rounded, 'Fitness'),
    _CategoryIcon(Icons.auto_stories_rounded, 'Learning'),
    _CategoryIcon(Icons.restaurant_rounded, 'Nutrition'),
    _CategoryIcon(Icons.self_improvement_rounded, 'Mindfulness'),
    _CategoryIcon(Icons.work_rounded, 'Career'),
    _CategoryIcon(Icons.favorite_rounded, 'Health'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.track_changes_rounded, size: 40, color: colors.primary),
          ),
          const SizedBox(height: 32),

          Text(
            'Track every part\nof your life',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'From workouts to habits — log it all\nand watch yourself grow.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: colors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 36),

          // Category icons in a circular layout
          SizedBox(
            height: 140,
            child: _CategoryCircle(
              categories: _categories,
              colors: colors,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryIcon {
  const _CategoryIcon(this.icon, this.label);
  final IconData icon;
  final String label;
}

class _CategoryCircle extends StatelessWidget {
  const _CategoryCircle({required this.categories, required this.colors});
  final List<_CategoryIcon> categories;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    final paletteColors = [
      colors.secondary,
      colors.primary,
      colors.success,
      colors.accent,
      colors.primary,
      colors.secondary,
    ];

    return Center(
      child: SizedBox(
        width: 260,
        height: 140,
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(categories.length, (i) {
            final angle = (i * 2 * math.pi / categories.length) - math.pi / 2;
            final radiusX = 100.0;
            final radiusY = 50.0;
            final x = 130 + math.cos(angle) * radiusX;
            final y = 70 + math.sin(angle) * radiusY;

            return Positioned(
              left: x - 24,
              top: y - 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: paletteColors[i].withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      categories[i].icon,
                      color: paletteColors[i],
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    categories[i].label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Slide 2: "Connect with your duo partner"
// ═══════════════════════════════════════════════════════════════════

class _Slide2 extends StatelessWidget {
  const _Slide2({required this.colors});
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Duo icon representation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: colors.primary, size: 32),
              ),
              const SizedBox(width: 8),
              Icon(Icons.favorite_rounded, color: colors.secondary, size: 28),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: colors.secondary, size: 32),
              ),
            ],
          ),
          const SizedBox(height: 28),

          Text(
            'Connect with your\nduo partner',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pair up with a friend and hold each\nother accountable every day.',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: colors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Mock duo progress comparison
          _DuoComparisonCard(colors: colors),
        ],
      ),
    );
  }
}

class _DuoComparisonCard extends StatelessWidget {
  const _DuoComparisonCard({required this.colors});
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(
            'This Week',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // You
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(Icons.person, color: colors.primary, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text('You',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    _ProgressRow(
                        label: 'Tasks', value: 0.7, color: colors.primary),
                    const SizedBox(height: 6),
                    _ProgressRow(
                        label: 'Streak',
                        value: 0.85,
                        color: colors.accent),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 80,
                color: colors.textMuted.withValues(alpha: 0.15),
              ),
              // Partner
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.secondary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person,
                          color: colors.secondary, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text('Partner',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    _ProgressRow(
                        label: 'Tasks',
                        value: 0.55,
                        color: colors.secondary),
                    const SizedBox(height: 6),
                    _ProgressRow(
                        label: 'Streak',
                        value: 0.6,
                        color: colors.accent),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 10),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  Slide 3: "Build streaks. Stay consistent."
// ═══════════════════════════════════════════════════════════════════

class _Slide3 extends StatelessWidget {
  const _Slide3({required this.colors});
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_fire_department_rounded, size: 40, color: colors.accent),
          ),
          const SizedBox(height: 28),

          Text(
            'Build streaks.\nStay consistent.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Every day you show up, your streak grows.\nStay consistent and reach your potential!',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: colors.textMuted, height: 1.5),
          ),
          const SizedBox(height: 32),

          // Streak calendar mockup
          _StreakCalendar(colors: colors),
        ],
      ),
    );
  }
}

class _StreakCalendar extends StatelessWidget {
  const _StreakCalendar({required this.colors});
  final ColorTokens colors;

  // Simulated streak data: 1 = active, 0 = missed, -1 = future
  static const _data = [
    1, 1, 1, 0, 1, 1, 1, // Week 1
    1, 1, 1, 1, 1, 0, 1, // Week 2
    1, 1, 1, 1, 1, 1, 1, // Week 3
    1, 1, -1, -1, -1, -1, -1, // Week 4 (partial)
  ];

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Header with streak count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      color: colors.accent, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    '18 day streak',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              Text(
                'April',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _dayLabels
                .map((d) => SizedBox(
                      width: 28,
                      child: Center(
                        child: Text(
                          d,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: colors.textMuted, fontSize: 11),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Calendar grid
          ...List.generate(4, (week) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (day) {
                  final idx = week * 7 + day;
                  final val = idx < _data.length ? _data[idx] : -1;

                  Color bgColor;
                  Color? iconColor;
                  IconData? icon;

                  if (val == 1) {
                    bgColor = colors.success.withValues(alpha: 0.2);
                    iconColor = colors.success;
                    icon = Icons.check_rounded;
                  } else if (val == 0) {
                    bgColor = colors.secondary.withValues(alpha: 0.12);
                    iconColor = colors.secondary.withValues(alpha: 0.5);
                    icon = Icons.close_rounded;
                  } else {
                    bgColor = colors.textMuted.withValues(alpha: 0.06);
                  }

                  return Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: icon != null
                        ? Icon(icon, color: iconColor, size: 14)
                        : null,
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}
