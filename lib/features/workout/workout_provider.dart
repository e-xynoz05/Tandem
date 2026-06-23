import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/workout_plan_model.dart';
import '../../core/models/workout_session_model.dart';
import '../../core/services/workout_service.dart';
import '../auth/auth_provider.dart';

// ─── Streams ──────────────────────────────────────────────────

/// Provider for user's workout plans.
final workoutPlansProvider = StreamProvider<List<WorkoutPlanModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(workoutServiceProvider).watchPlans(user.uid);
});

/// Provider for current week's workout sessions.
final weeklySessionsProvider = StreamProvider<List<WorkoutSessionModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(workoutServiceProvider).watchThisWeeksSessions(user.uid);
});

// ─── Active Session State ──────────────────────────────────────

class ActiveSessionState {
  const ActiveSessionState({
    this.session,
    this.currentExerciseIndex = 0,
    this.isResting = false,
  });

  final WorkoutSessionModel? session;
  final int currentExerciseIndex;
  final bool isResting;

  ActiveSessionState copyWith({
    WorkoutSessionModel? session,
    int? currentExerciseIndex,
    bool? isResting,
  }) {
    return ActiveSessionState(
      session: session ?? this.session,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      isResting: isResting ?? this.isResting,
    );
  }
}

class ActiveSessionNotifier extends StateNotifier<ActiveSessionState> {
  ActiveSessionNotifier(this._ref) : super(const ActiveSessionState());

  final Ref _ref;

  void startSession(WorkoutPlanModel plan) {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;

    final session = WorkoutSessionModel(
      id: '', 
      userId: user.uid,
      planId: plan.id,
      title: plan.title,
      startedAt: DateTime.now(),
      exerciseLogs: plan.exercises
          .map((e) => ExerciseLog(exerciseName: e.name, sets: []))
          .toList(),
    );

    state = ActiveSessionState(session: session);
  }

  void logSet(int exerciseIndex, int reps, double weight) {
    final session = state.session;
    if (session == null) return;

    final updatedLogs = List<ExerciseLog>.from(session.exerciseLogs);
    final log = updatedLogs[exerciseIndex];
    final updatedSets = List<SetLog>.from(log.sets)..add(SetLog(reps: reps, weight: weight));
    
    updatedLogs[exerciseIndex] = ExerciseLog(
      exerciseName: log.exerciseName,
      sets: updatedSets,
    );

    final totalVolume = updatedLogs.fold<double>(0, (sum, log) {
      return sum + log.sets.fold(0, (s, set) => s + (set.reps * set.weight));
    });

    state = state.copyWith(
      session: WorkoutSessionModel(
        id: session.id,
        userId: session.userId,
        planId: session.planId,
        title: session.title,
        startedAt: session.startedAt,
        exerciseLogs: updatedLogs,
        totalVolume: totalVolume,
      ),
    );

    // Start rest timer after logging a set
    _ref.read(restTimerProvider.notifier).startTimer();
  }

  void nextExercise() {
    if (state.session == null) return;
    if (state.currentExerciseIndex < state.session!.exerciseLogs.length - 1) {
      state = state.copyWith(currentExerciseIndex: state.currentExerciseIndex + 1);
    }
  }

  Future<void> finishSession() async {
    final session = state.session;
    if (session == null) return;

    final finalSession = WorkoutSessionModel(
      id: session.id,
      userId: session.userId,
      planId: session.planId,
      title: session.title,
      startedAt: session.startedAt,
      completedAt: DateTime.now(),
      exerciseLogs: session.exerciseLogs,
      totalVolume: session.totalVolume,
      isCompleted: true,
    );

    await _ref.read(workoutServiceProvider).completeSession(finalSession);
    state = const ActiveSessionState();
  }
}

final activeSessionProvider = StateNotifierProvider<ActiveSessionNotifier, ActiveSessionState>((ref) {
  return ActiveSessionNotifier(ref);
});

// ─── Rest Timer State ──────────────────────────────────────────

class RestTimerNotifier extends StateNotifier<double> {
  RestTimerNotifier() : super(0.0);

  Timer? _timer;
  int _secondsLeft = 0;
  int _totalSeconds = 90;

  void startTimer({int duration = 90}) {
    _timer?.cancel();
    _totalSeconds = duration;
    _secondsLeft = duration;
    state = 1.0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsLeft--;
      if (_secondsLeft <= 0) {
        timer.cancel();
        state = 0.0;
      } else {
        state = _secondsLeft / _totalSeconds;
      }
    });
  }

  void skip() {
    _timer?.cancel();
    state = 0.0;
  }

  void adjust(int delta) {
    _secondsLeft = (_secondsLeft + delta).clamp(0, 300);
    state = _secondsLeft / _totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final restTimerProvider = StateNotifierProvider<RestTimerNotifier, double>((ref) {
  return RestTimerNotifier();
});
