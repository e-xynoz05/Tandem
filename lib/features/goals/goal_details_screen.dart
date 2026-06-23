import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/goal_model.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/services/goal_service.dart';
import '../../core/widgets/progress_bar.dart';
import '../home/task_card.dart';
import 'goal_provider.dart';

class GoalDetailsScreen extends ConsumerWidget {
  const GoalDetailsScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    final goals = ref.watch(goalsStreamProvider).value ?? [];
    final goal = goals.firstWhere((g) => g.id == goalId, orElse: () => goals.first);
    final tasksAsync = ref.watch(goalTasksProvider(goalId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: tasksAsync.when(
        data: (tasks) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              _GoalHeader(goal: goal, colors: colors),
              
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tasks (${tasks.length})',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddTaskDialog(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Task'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (tasks.isEmpty)
                _EmptyTasksPlaceholder(colors: colors)
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskCard(
                      task: task,
                      onToggle: () {
                        ref.read(goalNotifierProvider.notifier).toggleTask(
                              goalId,
                              task.id,
                              !task.isCompleted,
                            );
                      },
                      onDelete: () => ref.read(goalServiceProvider).deleteTask(
                            task.userId,
                            task.id,
                            goalId: goalId,
                          ),
                      onReschedule: () {},
                    );
                  },
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'What needs to be done?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = controller.text.trim();
              if (title.isNotEmpty) {
                ref.read(goalNotifierProvider.notifier).addTask(
                      goalId: goalId,
                      title: title,
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal?'),
        content: const Text('This will permanently remove the goal and all its tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(goalNotifierProvider.notifier).deleteGoal(goalId);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back from screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _GoalHeader extends StatelessWidget {
  const _GoalHeader({required this.goal, required this.colors});
  final GoalModel goal;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  goal.category.name.toUpperCase(),
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (goal.isCompleted)
                const Icon(Icons.verified_rounded, color: Colors.green, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            goal.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (goal.description != null && goal.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              goal.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                  ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Overall Progress', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '${(goal.progress * 100).toInt()}%',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TandemProgressBar(
            value: goal.progress,
            height: 14,
            foregroundColor: colors.primary,
          ),
        ],
      ),
    );
  }
}

class _EmptyTasksPlaceholder extends StatelessWidget {
  const _EmptyTasksPlaceholder({required this.colors});
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.checklist_rounded, size: 64, color: colors.textMuted.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            'No tasks yet',
            style: TextStyle(color: colors.textMuted, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text('Break down your goal into small wins!'),
        ],
      ),
    );
  }
}
