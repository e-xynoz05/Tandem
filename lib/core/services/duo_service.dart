import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';
import '../models/user_model.dart';
import '../models/duo_model.dart';
import '../models/task_model.dart';
import '../models/goal_model.dart';

/// Service for managing Duo (partner) relationships and shared data using Supabase.
class DuoService {
  DuoService(this._sb);

  final SupabaseService _sb;
  SupabaseClient get _client => _sb.client;

  /// Finds a user's UID by their 6-character invite code.
  Future<String?> findUidByInviteCode(String code) async {
    final response = await _client
        .from('profiles')
        .select('id')
        .eq('duo_invite_code', code.toUpperCase().trim())
        .maybeSingle();

    return response?['id'] as String?;
  }

  /// Links two users as partners using a Postgres RPC.
  Future<void> linkPartners(String currentUid, String partnerUid) async {
    // We use an RPC call to handle the transaction safely on the server side.
    await _client.rpc('link_partners', params: {
      'p_user_a': currentUid,
      'p_user_b': partnerUid,
    });
  }

  /// Removes the partnership between two users.
  Future<void> unlinkPartners(String currentUid, String partnerUid) async {
    await _client.rpc('unlink_partners', params: {
      'p_user_a': currentUid,
      'p_user_b': partnerUid,
    });
  }

  /// Returns a real-time stream of the partner's profile.
  Stream<UserModel?> watchPartner(String partnerId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', partnerId)
        .map((data) => data.isNotEmpty 
            ? UserModel.fromMap(_mapPostgresToModel(data.first)) 
            : null);
  }

  /// Returns a real-time stream of the active duo document.
  Stream<DuoModel?> watchDuo(String userId, String? partnerId) {
    if (partnerId == null) return Stream.value(null);
    
    final duoId = userId.compareTo(partnerId) < 0 
        ? '${userId}_$partnerId' 
        : '${partnerId}_$userId';

    return _client
        .from('duos')
        .stream(primaryKey: ['id'])
        .eq('id', duoId)
        .map((data) => data.isNotEmpty 
            ? DuoModel.fromMap(_mapPostgresToDuo(data.first), id: duoId) 
            : null);
  }

  /// Streams partner's tasks with privacy filtering.
  Stream<List<TaskModel>> watchPartnerTasks(String partnerId) {
    return _client
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('user_id', partnerId)
        .map((data) => data
            .map((map) => TaskModel.fromMap(_mapPostgresToTask(map)))
            .toList());
  }

  /// Streams partner's goals with privacy filtering.
  Stream<List<GoalModel>> watchPartnerGoals(String partnerId) {
    return _client
        .from('goals')
        .stream(primaryKey: ['id'])
        .eq('user_id', partnerId)
        .map((data) => data
            .map((map) => GoalModel.fromMap(_mapPostgresToGoal(map)))
            .where((goal) => ['public', 'duo'].contains(goal.visibility))
            .toList());
  }

  /// Sends a nudge notification to the partner.
  Future<void> sendNudge(String currentUserName, String partnerUid) async {
    // Supabase implementation: Could insert into a 'notifications' table
    // for a database trigger to handle push notifications.
  }

  Map<String, dynamic> _mapPostgresToGoal(Map<String, dynamic> pg) {
    return {
      'id': pg['id'],
      'userId': pg['user_id'],
      'title': pg['title'],
      'currentXP': pg['current_xp'],
      'targetXP': pg['target_xp'],
      'category': pg['category'],
      'icon': pg['icon'],
      'color': pg['color'],
      'visibility': pg['visibility'],
      'createdAt': pg['created_at'],
    };
  }

  // ─── Mappings ──────────────────────────────────────────────────

  Map<String, dynamic> _mapPostgresToModel(Map<String, dynamic> pg) {
    return {
      'uid': pg['id'],
      'displayName': pg['display_name'],
      'email': pg['email'],
      'photoURL': pg['photo_url'],
      'duoPartnerId': pg['duo_partner_id'],
      'duoInviteCode': pg['duo_invite_code'],
      'streakCount': pg['streak_count'],
      'totalXP': pg['total_xp'],
      'tasksCompleted': pg['tasks_completed'],
      'onboardingComplete': pg['onboarding_complete'],
      'avatarUrl': pg['avatar_url'] ?? '',
      'avatarConfig': pg['avatar_config'] ?? {},
    };
  }

  Map<String, dynamic> _mapPostgresToDuo(Map<String, dynamic> pg) {
    return {
      'userAId': pg['user_a_id'],
      'userBId': pg['user_b_id'],
      'combinedStreak': pg['combined_streak'],
      'createdAt': pg['created_at'],
    };
  }

  Map<String, dynamic> _mapPostgresToTask(Map<String, dynamic> pg) {
    return {
      'id': pg['id'],
      'goalId': pg['goal_id'],
      'userId': pg['user_id'],
      'title': pg['title'],
      'isCompleted': pg['is_completed'],
      'createdAt': pg['created_at'],
    };
  }
}

/// Global provider for [DuoService].
final duoServiceProvider = Provider<DuoService>((ref) {
  final sb = ref.watch(supabaseServiceProvider);
  return DuoService(sb);
});
