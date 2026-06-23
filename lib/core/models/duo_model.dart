/// Duo model — Represents the connection between two users.
class DuoModel {
  const DuoModel({
    required this.id,
    required this.userAId,
    required this.userBId,
    this.combinedStreak = 0,
    this.lastSyncDate,
    this.createdAt,
  });

  final String id;
  final String userAId;
  final String userBId;
  final int combinedStreak;
  final DateTime? lastSyncDate;
  final DateTime? createdAt;

  factory DuoModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime? parseDate(dynamic data) {
      if (data == null) return null;
      if (data is DateTime) return data;
      if (data is String) return DateTime.tryParse(data);
      return null;
    }

    return DuoModel(
      id: id ?? map['id'] as String? ?? '',
      userAId: map['userAId'] as String? ?? map['user_a_id'] as String? ?? '',
      userBId: map['userBId'] as String? ?? map['user_b_id'] as String? ?? '',
      combinedStreak: (map['combinedStreak'] ?? map['combined_streak'] ?? 0) as int,
      lastSyncDate: parseDate(map['lastSyncDate'] ?? map['last_sync_date']),
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_a_id': userAId,
      'user_b_id': userBId,
      'combined_streak': combinedStreak,
      'last_sync_date': lastSyncDate?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
