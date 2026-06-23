class ExerciseTemplate {
  const ExerciseTemplate({
    required this.name,
    required this.targetSets,
    required this.targetReps,
    required this.targetWeight,
  });

  final String name;
  final int targetSets;
  final int targetReps;
  final double targetWeight;

  factory ExerciseTemplate.fromMap(Map<String, dynamic> map) {
    return ExerciseTemplate(
      name: map['name'] as String,
      targetSets: (map['targetSets'] as num).toInt(),
      targetReps: (map['targetReps'] as num).toInt(),
      targetWeight: (map['targetWeight'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'targetSets': targetSets,
      'targetReps': targetReps,
      'targetWeight': targetWeight,
    };
  }
}

class WorkoutPlanModel {
  const WorkoutPlanModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.assignedDays, // 0=Mon, 6=Sun
    required this.exercises,
    this.visibility = 'private',
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final List<int> assignedDays;
  final List<ExerciseTemplate> exercises;
  final String visibility;
  final DateTime? createdAt;

  factory WorkoutPlanModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic data) {
      if (data == null) return null;
      if (data is DateTime) return data;
      if (data is String) return DateTime.parse(data);
      return null;
    }

    return WorkoutPlanModel(
      id: map['id'] as String,
      userId: map['userId'] ?? map['user_id'] as String,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      difficulty: map['difficulty'] as String? ?? 'Intermediate',
      assignedDays: List<int>.from(map['assignedDays'] ?? map['assigned_days'] ?? []),
      exercises: (map['exercises'] as List?)
              ?.map((e) => ExerciseTemplate.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      visibility: map['visibility'] as String? ?? 'private',
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'assignedDays': assignedDays,
      'exercises': exercises.map((e) => e.toMap()).toList(),
      'visibility': visibility,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
