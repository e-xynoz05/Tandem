import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/models/goal_model.dart';
import '../../core/models/task_model.dart';
import '../../core/services/goal_service.dart';
import '../auth/auth_provider.dart';

/// State for goal-related actions (e.g., adding a new goal).
class GoalState {
  const GoalState({this.isLoading = false, this.error});
  final bool isLoading;
  final String? error;

  GoalState copyWith({bool? isLoading, String? error}) {
    return GoalState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provides a stream of goals for the current user.
final goalsStreamProvider = StreamProvider<List<GoalModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final service = ref.watch(goalServiceProvider);
  return service.watchGoals(user.uid);
});

/// Provides a stream of tasks for a specific goal.
final goalTasksProvider = StreamProvider.family<List<TaskModel>, String>((ref, goalId) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  
  final service = ref.watch(goalServiceProvider);
  return service.watchTasks(user.uid, goalId);
});

/// Logic for creating, updating, and managing goals/tasks.
class GoalNotifier extends StateNotifier<GoalState> {
  GoalNotifier(this._service, this._ref) : super(const GoalState());

  final GoalService _service;
  final Ref _ref;
  final _uuid = const Uuid();

  /// Creates a new goal.
  Future<String?> createGoal({
    required String title,
    String? description,
    GoalCategory category = GoalCategory.mindfulness,
    DateTime? targetDate,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return null;

    state = state.copyWith(isLoading: true, error: null);
    final goalId = _uuid.v4();
    
    final goal = GoalModel(
      id: goalId,
      userId: user.uid,
      title: title,
      description: description,
      category: category,
      targetDate: targetDate,
      createdAt: DateTime.now(),
    );

    try {
      await _service.createGoal(goal);
      state = state.copyWith(isLoading: false);
      return goalId;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Adds a task to a goal.
  Future<void> addTask({
    required String goalId,
    required String title,
    String? description,
    DateTime? dueDate,
  }) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);
    
    final task = TaskModel(
      id: _uuid.v4(),
      goalId: goalId,
      userId: user.uid,
      title: title,
      description: description,
      scheduledDate: dueDate,
      createdAt: DateTime.now(),
    );

    try {
      await _service.addTask(task);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Toggles a task completion.
  Future<void> toggleTask(String goalId, String taskId, bool isCompleted) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    try {
      await _service.toggleTask(user.uid, taskId, isCompleted, goalId: goalId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Deletes a goal.
  Future<void> deleteGoal(String goalId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteGoal(user.uid, goalId);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Global provider for [GoalNotifier].
final goalNotifierProvider = StateNotifierProvider<GoalNotifier, GoalState>((ref) {
  final service = ref.watch(goalServiceProvider);
  return GoalNotifier(service, ref);
});
