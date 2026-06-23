class SetLog {
  const SetLog({
    required this.reps,
    required this.weight,
  });

  final int reps;
  final double weight;

  factory SetLog.fromMap(Map<String, dynamic> map) {
    return SetLog(
      reps: (map['reps'] as num).toInt(),
      weight: (map['weight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reps': reps,
      'weight': weight,
    };
  }
}

class ExerciseLog {
  const ExerciseLog({
    required this.exerciseName,
    required this.sets,
  });

  final String exerciseName;
  final List<SetLog> sets;

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      exerciseName: map['exerciseName'] as String,
      sets: (map['sets'] as List?)
              ?.map((e) => SetLog.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'exerciseName': exerciseName,
      'sets': sets.map((e) => e.toMap()).toList(),
    };
  }
}

class WorkoutSessionModel {
  const WorkoutSessionModel({
    required this.id,
    required this.userId,
    required this.planId,
    required this.title,
    required this.startedAt,
    this.completedAt,
    this.totalVolume = 0.0,
    this.exerciseLogs = const [],
    this.isCompleted = false,
  });

  final String id;
  final String userId;
  final String planId;
  final String title;
  final DateTime startedAt;
  final DateTime? completedAt;
  final double totalVolume;
  final List<ExerciseLog> exerciseLogs;
  final bool isCompleted;

  factory WorkoutSessionModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic data) {
      if (data is DateTime) return data;
      if (data is String) return DateTime.parse(data);
      return DateTime.now();
    }

    return WorkoutSessionModel(
      id: map['id'] as String,
      userId: map['userId'] ?? map['user_id'] as String,
      planId: map['planId'] ?? map['plan_id'] as String,
      title: map['title'] as String? ?? 'Workout Session',
      startedAt: parseDate(map['startedAt'] ?? map['started_at']),
      completedAt: (map['completedAt'] ?? map['completed_at']) != null
          ? parseDate(map['completedAt'] ?? map['completed_at'])
          : null,
      totalVolume: (map['totalVolume'] ?? map['total_volume'] as num?)?.toDouble() ?? 0.0,
      exerciseLogs: (map['exerciseLogs'] ?? map['data'] as List?)
              ?.map((e) => ExerciseLog.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: map['isCompleted'] ?? map['is_completed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'title': title,
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'totalVolume': totalVolume,
      'exerciseLogs': exerciseLogs.map((e) => e.toMap()).toList(),
      'isCompleted': isCompleted,
    };
  }
}
