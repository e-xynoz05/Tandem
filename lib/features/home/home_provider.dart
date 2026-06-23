import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/goal_model.dart';
import '../../core/models/task_model.dart';
import '../../core/services/goal_service.dart';
import '../auth/auth_provider.dart';

/// State for the Home screen, including the current motivational message.
class HomeState {
  const HomeState({
    this.motivationMessage = 'Let\'s make today count!',
    this.streakCount = 0,
  });

  final String motivationMessage;
  final int streakCount;

  HomeState copyWith({
    String? motivationMessage,
    int? streakCount,
  }) {
    return HomeState(
      motivationMessage: motivationMessage ?? this.motivationMessage,
      streakCount: streakCount ?? this.streakCount,
    );
  }
}

class MotivationMessage {
  const MotivationMessage(this.text);
  final String text;
}

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState()) {
    _startMotivationTimer();
  }

  Timer? _timer;

  static const List<MotivationMessage> _motivationMessages = [
    MotivationMessage("Small steps lead to big changes. You've got this!"),
    MotivationMessage("Success is the sum of small efforts repeated daily."),
    MotivationMessage("You've got this! Let's hit those goals."),
    MotivationMessage("Focus on progress, not perfection."),
    MotivationMessage("Your future self will thank you for today's work."),
    MotivationMessage("Consistency is the key to mastery."),
    MotivationMessage("Every task completed is a victory."),
    MotivationMessage("Dream big, act small, start now."),
    MotivationMessage("Stay focused and stay curious."),
    MotivationMessage("You are capable of amazing things."),
    MotivationMessage("Keep pushing, the finish line is closer than you think."),
    MotivationMessage("Discipline is choosing between what you want now and what you want most."),
    MotivationMessage("The secret of getting ahead is getting started."),
    MotivationMessage("Don't stop until you're proud."),
    MotivationMessage("Make today so awesome that yesterday gets jealous."),
    MotivationMessage("Your potential is endless."),
    MotivationMessage("Action is the foundational key to all success."),
    MotivationMessage("Turn your 'can'ts' into 'cans' and your dreams into plans."),
    MotivationMessage("The only way to do great work is to love what you do."),
    MotivationMessage("Believe you can and you're halfway there."),
    MotivationMessage("Don't count the days, make the days count."),
    MotivationMessage("Happiness is the joy of achievement."),
    MotivationMessage("Obstacles are those frightful things you see when you take your eyes off your goal."),
    MotivationMessage("It always seems impossible until it's done."),
    MotivationMessage("Hard work beats talent when talent doesn't work hard."),
    MotivationMessage("The best way to predict the future is to create it."),
    MotivationMessage("Everything you've ever wanted is on the other side of fear."),
    MotivationMessage("Success doesn't just find you. You have to go out and get it."),
    MotivationMessage("The harder you work for something, the greater you'll feel when you achieve it."),
    MotivationMessage("Wake up with determination. Go to bed with satisfaction."),
  ];

  void _startMotivationTimer() {
    _updateMessage();
    _timer = Timer.periodic(const Duration(hours: 3), (_) => _updateMessage());
  }

  void _updateMessage() {
    final now = DateTime.now();
    final index = (now.hour ~/ 3) % _motivationMessages.length;
    final msg = _motivationMessages[index];
    state = state.copyWith(
      motivationMessage: msg.text,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Global home state provider.
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) => HomeNotifier());

/// Stream of today's tasks.
final todayTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(goalServiceProvider).watchTodayTasks(user.uid);
});

/// Stream of all active goals.
final activeGoalsProvider = StreamProvider<List<GoalModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(goalServiceProvider).watchGoals(user.uid);
});

/// Aggregated progress for life categories, showing the distribution of COMPLETED work.
final lifeProgressProvider = Provider<Map<String, double>>((ref) {
  final tasks = ref.watch(todayTasksProvider).maybeWhen(
        data: (data) => data,
        orElse: () => <TaskModel>[],
      );

  final Map<String, double> categoryResults = {
    'fitness': 0.0,
    'career': 0.0,
    'relationships': 0.0,
    'learning': 0.0,
    'mindfulness': 0.0,
  };

  // Filter tasks completed TODAY (since 12am)
  final completedToday = tasks.where((t) => t.isCompleted).toList();
  
  // Calculate total COMPLETED units
  double totalCompletedUnits = completedToday.length.toDouble();

  // If nothing is done, show 0% for everything
  if (totalCompletedUnits == 0) return categoryResults;

  // Calculate the share (%) of total completed work for each category
  for (final catKey in categoryResults.keys) {
    double completedInCat = completedToday
        .where((t) => t.category.toLowerCase().trim() == catKey)
        .length
        .toDouble();

    categoryResults[catKey] = completedInCat / totalCompletedUnits;
  }

  return categoryResults;
});

/// Aggregated overall progress across all categories.
final overallProgressProvider = Provider<double>((ref) {
  final tasks = ref.watch(todayTasksProvider).maybeWhen(
        data: (data) => data,
        orElse: () => <TaskModel>[],
      );

  if (tasks.isEmpty) return 0.0;

  final completedCount = tasks.where((t) => t.isCompleted).length;
  return completedCount / tasks.length;
});

