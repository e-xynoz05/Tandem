import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';

import '../models/goal_model.dart';
import '../models/task_model.dart';

/// Service for managing user goals and their associated tasks using Supabase.
class GoalService {
  GoalService(this._sb);

  final SupabaseService _sb;
  SupabaseClient get _client => _sb.client;

  // ─── Goals ──────────────────────────────────────────────────────

  /// Creates a new goal in Supabase.
  Future<void> createGoal(GoalModel goal) async {
    await _client
        .from('goals')
        .insert(_mapGoalToPostgres(goal));
  }

  /// Updates an existing goal.
  Future<void> updateGoal(GoalModel goal) async {
    await _client
        .from('goals')
        .update(_mapGoalToPostgres(goal))
        .eq('id', goal.id);
  }

  /// Deletes a specific task.
  Future<void> deleteTask(String userId, String taskId, {String? goalId}) async {
    await _client.from('tasks').delete().eq('id', taskId).eq('user_id', userId);
    if (goalId != null) {
      await _recalculateGoalProgress(userId, goalId);
    }
  }

  /// Deletes a goal and all its associated tasks.
  Future<void> deleteGoal(String userId, String goalId) async {
    await _client.from('goals').delete().eq('id', goalId).eq('user_id', userId);
  }

  /// Watches all goals for a specific user.
  Stream<List<GoalModel>> watchGoals(String userId) {
    return _client
        .from('goals')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data
            .map((map) => GoalModel.fromMap(_mapPostgresToGoal(map)))
            .where((goal) => !goal.isArchived)
            .toList());
  }

  // ─── Tasks ──────────────────────────────────────────────────────

  /// Adds a task to the user's task collection.
  Future<void> addTask(TaskModel task) async {
    await _client
        .from('tasks')
        .insert(_mapTaskToPostgres(task));
    
    if (task.goalId != null) {
      await _recalculateGoalProgress(task.userId, task.goalId!);
    }
  }

  /// Toggles completion of a task and updates user XP.
  Future<void> toggleTask(String userId, String taskId, bool isCompleted, {String? goalId}) async {
    await _client.from('tasks').update({
      'is_completed': isCompleted,
      'completed_at': isCompleted ? DateTime.now().toIso8601String() : null,
    }).eq('id', taskId);

    if (goalId != null) {
      await _recalculateGoalProgress(userId, goalId);
    }

    // Update user stats (XP)
    // In a real app, this should be done via a Postgres trigger/function 
    // to ensure atomicity, but for now we'll do an RPC or two updates.
    await _client.rpc('increment_xp', params: {
      'p_user_id': userId,
      'p_amount': isCompleted ? 10 : -10,
      'p_task_count': isCompleted ? 1 : -1,
    });
  }

  /// Watches tasks scheduled for a specific date (e.g. today).
  Stream<List<TaskModel>> watchTodayTasks(String userId) {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day);
          
          return data
              .map((map) => TaskModel.fromMap(_mapPostgresToTask(map)))
              .where((t) {
                // Show if:
                // 1. Scheduled for today (regardless of completion)
                // 2. OR Completed today (regardless of when it was scheduled)
                final isScheduledForToday = t.scheduledDate != null &&
                    t.scheduledDate!.isAfter(startOfDay);
                
                final isCompletedToday = t.isCompleted && 
                    t.completedAt != null && 
                    t.completedAt!.isAfter(startOfDay);

                return isScheduledForToday || isCompletedToday;
              })
              .toList()
                ..sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
        });
  }

  /// Watches tasks for a specific goal.
  Stream<List<TaskModel>> watchTasks(String userId, String goalId) {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('goal_id', goalId)
        .map((data) => data
            .map((map) => TaskModel.fromMap(_mapPostgresToTask(map)))
            .toList());
  }

  Future<void> _recalculateGoalProgress(String userId, String goalId) async {
    final response = await _client
        .from('tasks')
        .select()
        .eq('goal_id', goalId);

    if (response.isEmpty) return;

    final totalTasks = response.length;
    final completedTasks = response.where((map) => map['is_completed'] == true).length;

    await _client
        .from('goals')
        .update({
      'completed_steps': completedTasks,
      'total_steps': totalTasks,
    })
    .eq('id', goalId);
  }

  // ─── Mappers ──────────────────────────────────────────────────

  Map<String, dynamic> _mapGoalToPostgres(GoalModel goal) {
    return {
      'id': goal.id,
      'user_id': goal.userId,
      'title': goal.title,
      'description': goal.description,
      'category': goal.category.name,
      'visibility': goal.visibility,
      'is_archived': goal.isArchived,
      'completed_steps': goal.completedSteps,
      'total_steps': goal.totalSteps,
      'target_date': goal.targetDate?.toIso8601String(),
    };
  }

  Map<String, dynamic> _mapPostgresToGoal(Map<String, dynamic> pg) {
    return {
      'id': pg['id'],
      'userId': pg['user_id'],
      'title': pg['title'],
      'description': pg['description'],
      'category': pg['category'],
      'visibility': pg['visibility'],
      'isArchived': pg['is_archived'],
      'completedSteps': pg['completed_steps'],
      'totalSteps': pg['total_steps'],
      'targetDate': pg['target_date'],
      'createdAt': pg['created_at'],
    };
  }

  Map<String, dynamic> _mapTaskToPostgres(TaskModel task) {
    return task.toMap();
  }

  Map<String, dynamic> _mapPostgresToTask(Map<String, dynamic> pg) {
    return {
      'id': pg['id'],
      'goalId': pg['goal_id'],
      'userId': pg['user_id'],
      'title': pg['title'],
      'description': pg['description'],
      'category': pg['category'],
      'isCompleted': pg['is_completed'],
      'xpReward': pg['xp_reward'],
      'scheduledDate': pg['scheduled_date'],
      'completedAt': pg['completed_at'],
      'reminderTime': pg['reminder_time'],
      'createdAt': pg['created_at'],
      'visibility': pg['visibility'],
    };
  }
}

/// Global provider for [GoalService].
final goalServiceProvider = Provider<GoalService>((ref) {
  final sb = ref.watch(supabaseServiceProvider);
  return GoalService(sb);
});
