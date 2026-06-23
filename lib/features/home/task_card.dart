import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/task_model.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';

/// Interactive task card for the HomeScreen.
class TaskCard extends ConsumerStatefulWidget {
  const TaskCard({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
    required this.onReschedule,
  });

  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onReschedule;

  @override
  ConsumerState<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<TaskCard> with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(_checkController);

    if (widget.task.isCompleted) {
      _checkController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.isCompleted != widget.task.isCompleted) {
      if (widget.task.isCompleted) {
        _checkController.forward();
      } else {
        _checkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'fitness': return const Color(0xFF1A1C1A);
      case 'career': return const Color(0xFFA43B2F);
      case 'relationships': return const Color(0xFFFF7F6E);
      case 'learning': return const Color(0xFFD4A373);
      case 'mindfulness': return const Color(0xFF1A1C1A);
      default: return const Color(0xFFA43B2F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    return Dismissible(
      key: Key(widget.task.id),
      background: Container(
        color: const Color(0xFFFF7F6E).withValues(alpha: 0.1),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.calendar_today_rounded, color: Color(0xFFFF7F6E)),
      ),
      secondaryBackground: Container(
        color: Colors.red.withValues(alpha: 0.1),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.red),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          widget.onDelete();
        } else {
          widget.onReschedule();
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            GestureDetector(
              key: const Key('task-checkbox'),
              onTap: widget.onToggle,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.task.isCompleted ? const Color(0xFFA43B2F) : Colors.transparent,
                      border: Border.all(
                        color: widget.task.isCompleted ? const Color(0xFFA43B2F) : colors.textMuted,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: widget.task.isCompleted
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.task.isCompleted ? colors.textMuted : colors.text,
                      decoration: widget.task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getCategoryColor(widget.task.category),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.task.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10, 
                          color: colors.textMuted,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (widget.task.scheduledDate != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.access_time, size: 12, color: colors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.task.scheduledDate!.hour}:${widget.task.scheduledDate!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 12, color: colors.textMuted),
                        ),
                      ],
                    ],
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
