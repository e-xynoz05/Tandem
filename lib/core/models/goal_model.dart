/// Goal model — a high-level life objective.
class GoalModel {
  const GoalModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.category = GoalCategory.mindfulness,
    this.targetDate,
    this.completedSteps = 0,
    this.totalSteps = 1,
    this.visibility = 'private',
    this.isArchived = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final GoalCategory category;
  final DateTime? targetDate;
  final int completedSteps;
  final int totalSteps;
  final String visibility; // public | duo | private
  final bool isArchived;
  final DateTime? createdAt;

  /// Returns true if the goal has reached its target steps.
  bool get isCompleted => progress >= 1.0;

  /// Percent progress (0.0 to 1.0).
  double get progress => totalSteps > 0 ? completedSteps / totalSteps : 0.0;

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic data) {
      if (data == null) return null;
      if (data is DateTime) return data;
      if (data is String) return DateTime.tryParse(data);
      return null;
    }

    return GoalModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? map['user_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      category: GoalCategory.values.firstWhere(
        (e) => e.name == (map['category'] ?? 'mindfulness'),
        orElse: () => GoalCategory.mindfulness,
      ),
      targetDate: parseDate(map['targetDate'] ?? map['target_date']),
      completedSteps: (map['completedSteps'] ?? map['completed_steps'] ?? 0) as int,
      totalSteps: (map['totalSteps'] ?? map['total_steps'] ?? 1) as int,
      visibility: map['visibility'] as String? ?? 'private',
      isArchived: map['isArchived'] as bool? ?? map['is_archived'] as bool? ?? false,
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category.name,
      'target_date': targetDate?.toIso8601String(),
      'completed_steps': completedSteps,
      'total_steps': totalSteps,
      'visibility': visibility,
      'is_archived': isArchived,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

enum GoalCategory {
  fitness,
  career,
  relationships,
  learning,
  mindfulness,
}
