class DailyScoreModel {
  const DailyScoreModel({
    required this.id, // YYYY-MM-DD
    required this.userId,
    required this.overall,
    required this.fitness,
    required this.career,
    required this.relationships,
    required this.learning,
    required this.mindfulness,
    required this.date,
  });

  final String id;
  final String userId;
  final double overall;
  final double fitness;
  final double career;
  final double relationships;
  final double learning;
  final double mindfulness;
  final DateTime date;

  factory DailyScoreModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic data) {
      if (data is DateTime) return data;
      if (data is String) return DateTime.parse(data);
      throw ArgumentError('Invalid date format');
    }

    return DailyScoreModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? map['user_id'] as String? ?? '',
      overall: (map['overall'] as num? ?? 0).toDouble(),
      fitness: (map['fitness'] as num? ?? 0).toDouble(),
      career: (map['career'] as num? ?? 0).toDouble(),
      relationships: (map['relationships'] as num? ?? 0).toDouble(),
      learning: (map['learning'] as num? ?? 0).toDouble(),
      mindfulness: (map['mindfulness'] as num? ?? 0).toDouble(),
      date: parseDate(map['date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'overall': overall,
      'fitness': fitness,
      'career': career,
      'relationships': relationships,
      'learning': learning,
      'mindfulness': mindfulness,
      'date': date.toIso8601String(),
    };
  }
}
