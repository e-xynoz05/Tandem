/// Task model — an individual action item.
class TaskModel {
  const TaskModel({
    required this.id,
    this.goalId,
    required this.userId,
    required this.title,
    this.description,
    this.category = 'mindfulness',
    this.isCompleted = false,
    this.xpReward = 10,
    this.scheduledDate,
    this.completedAt,
    this.createdAt,
    this.visibility = 'private',
    this.reminderTime,
  });

  final String id;
  final String? goalId;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final bool isCompleted;
  final int xpReward;
  final DateTime? scheduledDate;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final String visibility; // public | duo | private
  final DateTime? reminderTime;

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic data) {
      if (data == null) return null;
      if (data is DateTime) return data;
      if (data is String) return DateTime.tryParse(data);
      return null;
    }

    return TaskModel(
      id: map['id'] as String? ?? '',
      goalId: map['goalId'] as String? ?? map['goal_id'] as String?,
      userId: map['userId'] as String? ?? map['user_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      category: map['category'] as String? ?? 'mindfulness',
      isCompleted: map['isCompleted'] as bool? ?? map['is_completed'] as bool? ?? false,
      xpReward: (map['xpReward'] ?? map['xp_reward'] ?? 10) as int,
      scheduledDate: parseDate(map['scheduledDate'] ?? map['scheduled_date']),
      completedAt: parseDate(map['completedAt'] ?? map['completed_at']),
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
      visibility: map['visibility'] as String? ?? 'private',
      reminderTime: parseDate(map['reminderTime'] ?? map['reminder_time']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'is_completed': isCompleted,
      'xp_reward': xpReward,
      'scheduled_date': scheduledDate?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'visibility': visibility,
      'reminder_time': reminderTime?.toIso8601String(),
    };
  }

  TaskModel copyWith({
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? scheduledDate,
    DateTime? reminderTime,
  }) {
    return TaskModel(
      id: id,
      goalId: goalId,
      userId: userId,
      title: title,
      category: category,
      isCompleted: isCompleted ?? this.isCompleted,
      xpReward: xpReward,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt,
      visibility: visibility,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }
}
