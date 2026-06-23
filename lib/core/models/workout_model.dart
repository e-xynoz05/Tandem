/// Workout model — a single exercise session record.
class WorkoutModel {
  const WorkoutModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.durationMinutes,
    this.caloriesBurned,
    this.notes,
    this.completedAt,
    this.createdAt,
  });

  final String id;
  final String userId;
  final WorkoutCategory category;
  final int durationMinutes;
  final int? caloriesBurned;
  final String? notes;
  final DateTime? completedAt;
  final DateTime? createdAt;

  factory WorkoutModel.fromMap(Map<String, dynamic> map) {
    return WorkoutModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      category: WorkoutCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => WorkoutCategory.other,
      ),
      durationMinutes: (map['durationMinutes'] as num).toInt(),
      caloriesBurned: (map['caloriesBurned'] as num?)?.toInt(),
      notes: map['notes'] as String?,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'category': category.name,
      'durationMinutes': durationMinutes,
      'caloriesBurned': caloriesBurned,
      'notes': notes,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }
}

enum WorkoutCategory {
  cardio,
  strength,
  yoga,
  swimming,
  cycling,
  hiit,
  other,
}
