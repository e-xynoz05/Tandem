/// Tandem user model mapped to `/users/{uid}` in Firestore.
class UserModel {
  const UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.duoPartnerId,
    this.duoInviteCode,
    this.streakCount = 0,
    this.totalXP = 0,
    this.tasksCompleted = 0,
    this.onboardingComplete = false,
    this.avatarUrl = '',
    this.avatarConfig = const {},
    this.username,
    this.createdAt,
    this.lastActive,
  });

  final String uid;
  final String email;
  final String? username;
  final String? displayName;
  final String? photoURL;
  final String? duoPartnerId;
  final String? duoInviteCode;
  final int streakCount;
  final int totalXP;
  final int tasksCompleted;
  final bool onboardingComplete;
  final String avatarUrl;
  final Map<String, dynamic> avatarConfig;
  final DateTime? createdAt;
  final DateTime? lastActive;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic data) {
      if (data == null) return null;
      if (data is DateTime) return data;
      if (data is String) return DateTime.tryParse(data);
      return null;
    }

    return UserModel(
      uid: map['uid'] as String? ?? map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      username: map['username'] as String?,
      displayName: map['displayName'] as String? ?? map['display_name'] as String?,
      photoURL: map['photoURL'] as String? ?? map['photo_url'] as String?,
      duoPartnerId: map['duoPartnerId'] as String? ?? map['duo_partner_id'] as String?,
      duoInviteCode: map['duoInviteCode'] as String? ?? map['duo_invite_code'] as String?,
      streakCount: (map['streakCount'] ?? map['streak_count'] ?? 0) as int,
      totalXP: (map['totalXP'] ?? map['total_xp'] ?? 0) as int,
      tasksCompleted: (map['tasksCompleted'] ?? map['tasks_completed'] ?? 0) as int,
      onboardingComplete: (map['onboardingComplete'] ?? map['onboarding_complete'] ?? false) as bool,
      avatarUrl: map['avatarUrl'] as String? ?? map['avatar_url'] as String? ?? '',
      avatarConfig: Map<String, dynamic>.from(map['avatarConfig'] ?? map['avatar_config'] ?? {}),
      createdAt: parseDate(map['createdAt'] ?? map['created_at']),
      lastActive: parseDate(map['lastActive'] ?? map['last_active']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'displayName': displayName,
      'photoURL': photoURL,
      'duoPartnerId': duoPartnerId,
      'duoInviteCode': duoInviteCode,
      'streakCount': streakCount,
      'totalXP': totalXP,
      'tasksCompleted': tasksCompleted,
      'onboardingComplete': onboardingComplete,
      'avatarUrl': avatarUrl,
      'avatarConfig': avatarConfig,
      'createdAt': createdAt?.toIso8601String(),
      'lastActive': lastActive?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? username,
    String? displayName,
    String? photoURL,
    String? duoPartnerId,
    String? duoInviteCode,
    int? streakCount,
    int? totalXP,
    int? tasksCompleted,
    bool? onboardingComplete,
    String? avatarUrl,
    Map<String, dynamic>? avatarConfig,
    DateTime? lastActive,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      duoPartnerId: duoPartnerId ?? this.duoPartnerId,
      duoInviteCode: duoInviteCode ?? this.duoInviteCode,
      streakCount: streakCount ?? this.streakCount,
      totalXP: totalXP ?? this.totalXP,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarConfig: avatarConfig ?? this.avatarConfig,
      createdAt: createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
