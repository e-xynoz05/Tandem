import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/router/route_names.dart';
import '../../core/models/task_model.dart';
import '../../core/services/goal_service.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/category_progress_bar.dart';
import '../../core/widgets/confetti_overlay.dart';
import '../../core/widgets/shared_progress_ring.dart';
import '../auth/auth_provider.dart';
import 'home_provider.dart';
import '../../core/services/notification_service.dart';
import 'package:uuid/uuid.dart';
import 'task_card.dart';
import 'widgets/streak_row.dart';
import '../duo/duo_provider.dart';

/// The central hub of Tandem — "Home Dashboard" from Stitch.
///
/// Warm cream background with coral accents, shared energy ring,
/// daily focus cards, today's tasks, and life balance bars.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    final user = ref.watch(currentUserProvider);
    final tasksAsync = ref.watch(todayTasksProvider);
    final categoryProgress = ref.watch(lifeProgressProvider);
    final homeState = ref.watch(homeProvider);

    return ConfettiOverlay(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: colors.background,
          ),
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ─── Header Section ───────────────────────────────────
                  SliverToBoxAdapter(
                    child: _HomeHeader(user: user, colors: colors),
                  ),

                  // ─── Our Energy Ring ──────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 26, 24, 8),
                      child: ref.watch(partnerUserProvider).when(
                            data: (partner) => _OurEnergySection(
                              progress: ref.watch(overallProgressProvider),
                              partner: partner,
                              colors: colors,
                            ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                    ),
                  ),


                  // ─── Today's Tasks ────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Today's Progress",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: colors.text,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              final colors = ref.read(themeModeProvider) == ThemeMode.dark
                                  ? ColorTokens.dark
                                  : ColorTokens.light;
                              _showAddTaskSheet(context, ref, colors);
                            },
                            icon: Icon(Icons.add_rounded,
                                size: 18, color: colors.primary),
                            label: Text('Add Task',
                                style: TextStyle(color: colors.primary)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  tasksAsync.when(
                    data: (tasks) {
                      if (tasks.isEmpty) {
                        return SliverToBoxAdapter(
                          child: _EmptyTaskState(colors: colors),
                        );
                      }
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final task = tasks[index];
                            return TaskCard(
                              task: task,
                              onToggle: () async {
                                final isNowCompleted = !task.isCompleted;
                                await ref.read(goalServiceProvider).toggleTask(
                                      user!.uid,
                                      task.id,
                                      isNowCompleted,
                                      goalId: task.goalId,
                                    );
                                if (!context.mounted) return;
                                if (isNowCompleted) {
                                  HapticFeedback.mediumImpact();
                                } else {
                                  HapticFeedback.selectionClick();
                                }
                              },
                              onDelete: () => ref
                                  .read(goalServiceProvider)
                                  .deleteTask(user!.uid, task.id,
                                      goalId: task.goalId),
                              onReschedule: () {},
                            );
                          },
                          childCount: tasks.length,
                        ),
                      );
                    },
                    loading: () => SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: colors.primary,
                            strokeWidth: 2.5,
                          ),
                        ),
                      ),
                    ),
                    error: (e, _) =>
                        SliverToBoxAdapter(child: Text('Error: $e')),
                  ),

                  // ─── Life Balance ─────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Life Balance",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: colors.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Your momentum across categories",
                            style: TextStyle(
                                color: colors.textMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate(
                        categoryProgress.entries.map((entry) {
                          return CategoryProgressBar(
                            category: entry.key,
                            progress: entry.value,
                            onTap: () => context.pushNamed(
                              RouteNames.categoryDetail,
                              pathParameters: {'category': entry.key},
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 140)),
                ],
              ),

              // ─── Motivation Bubble ────────────────────────────────────
              Positioned(
                bottom: 30,
                left: 20,
                right: 20,
                child: _MotivationBubble(
                  message: homeState.motivationMessage,
                  colors: colors,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

// ─── Home Header ────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.user, required this.colors});
  final dynamic user;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMM d').format(now);

    String greeting;
    if (now.hour < 12) {
      greeting = 'Good Morning';
    } else if (now.hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$greeting,",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user?.displayName?.split(' ').first ?? 'there',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              // Duo avatar / spark icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 20),
          StreakRow(colors: colors),
        ],
      ),
    );
  }
}

// ─── Our Energy Ring Section ────────────────────────────────────────
class _OurEnergySection extends StatelessWidget {
  const _OurEnergySection({
    required this.progress,
    required this.partner,
    required this.colors,
  });
  final double progress;
  final dynamic partner;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    if (partner == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.people_outline_rounded,
                    color: colors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Power Up with a Partner',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Invite your partner to sync routines and grow your energy ring together.',
              style: TextStyle(color: colors.textMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push('/routines/invite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Invite Partner',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      );
    }

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
                'Our Energy',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Shared',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SharedProgressRing(
            progress: progress,
            size: 160,
            strokeWidth: 12,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                  ),
                ),
                Text(
                  'Combined',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Paired with ${partner.displayName?.split(' ').first ?? 'Partner'}",
            style: TextStyle(
              fontSize: 14,
              color: colors.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Motivation Bubble ──────────────────────────────────────────────
class _MotivationBubble extends StatelessWidget {
  const _MotivationBubble({required this.message, required this.colors});
  final String message;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded,
                size: 20, color: colors.primary),
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

// ─── Empty Task State ───────────────────────────────────────────────
class _EmptyTaskState extends StatelessWidget {
  const _EmptyTaskState({required this.colors});
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.wb_sunny_rounded,
              size: 48, color: colors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            "Clear skies today!",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add a task to start building momentum.",
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Add Task Sheet ───────────────────────────────────────────
void _showAddTaskSheet(BuildContext context, WidgetRef ref, ColorTokens colors) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AddTaskSheet(colors: colors),
  );
}

class _AddTaskSheet extends ConsumerStatefulWidget {
  final ColorTokens colors;

  const _AddTaskSheet({required this.colors});

  @override
  ConsumerState<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends ConsumerState<_AddTaskSheet> {
  final TextEditingController _controller = TextEditingController();
  String _selectedCategory = 'mindfulness';
  TimeOfDay? _selectedTime;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Quick Add Task",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_isSubmitting,
            decoration: InputDecoration(
              hintText: "What needs to be done?",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: colors.surfaceContainer,
            ),
          ),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                'fitness',
                'career',
                'relationships',
                'learning',
                'mindfulness'
              ].map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat[0].toUpperCase() + cat.substring(1)),
                    selected: isSelected,
                    onSelected: _isSubmitting
                        ? null
                        : (s) => setState(() => _selectedCategory = cat),
                    selectedColor: colors.primary.withValues(alpha: 0.15),
                    checkmarkColor: colors.primary,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),

          // Reminder Picker
          Row(
            children: [
              Icon(Icons.notifications_active_rounded,
                  size: 20, color: colors.textMuted),
              const SizedBox(width: 12),
              Text("Reminder",
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: colors.text)),
              const Spacer(),
              TextButton.icon(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (!mounted) return;
                        if (time != null) setState(() => _selectedTime = time);
                      },
                icon: Icon(Icons.access_time_rounded,
                    size: 18, color: colors.primary),
                label: Text(_selectedTime?.format(context) ?? 'Set Time'),
              ),
              if (_selectedTime != null && !_isSubmitting)
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: colors.textMuted),
                  onPressed: () => setState(() => _selectedTime = null),
                ),
            ],
          ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                      if (_controller.text.isEmpty) return;

                      setState(() => _isSubmitting = true);

                      try {
                        final user = ref.read(currentUserProvider);
                        if (user == null) {
                          throw Exception("You must be logged in to create a task.");
                        }

                        DateTime? reminderTime;
                        final now = DateTime.now();
                        if (_selectedTime != null) {
                          reminderTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            _selectedTime!.hour,
                            _selectedTime!.minute,
                          );
                        }

                        final task = TaskModel(
                          id: const Uuid().v4(),
                          userId: user.uid,
                          title: _controller.text,
                          category: _selectedCategory,
                          scheduledDate: DateTime.now(),
                          createdAt: DateTime.now(),
                          reminderTime: reminderTime,
                        );

                        await ref.read(goalServiceProvider).addTask(task);

                        // Invalidate the provider to refresh the list
                        // The stream provider will update automatically as it's watching the table

                        if (reminderTime != null) {
                          await ref
                              .read(notificationServiceProvider)
                              .scheduleTaskReminder(task);
                        }

                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        debugPrint('Task creation error: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to create task: $e'),
                              backgroundColor: colors.primary,
                            ),
                          );
                        }
                        setState(() => _isSubmitting = false);
                      }
                    },
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Create Task"),
            ),
          ),
        ],
      ),
    );
  }
}
