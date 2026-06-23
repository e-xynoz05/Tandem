import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';
import '../models/daily_score_model.dart';

class StatsService {
  StatsService(this._sb);

  final SupabaseService _sb;
  SupabaseClient get _client => _sb.client;

  /// Stream daily scores for the last [days] for a user from Supabase.
  Stream<List<DailyScoreModel>> watchDailyScores(String userId, {int days = 30}) {
    final startAt = DateTime.now().subtract(Duration(days: days));
    
    return _client
        .from('daily_scores')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data
            .where((map) => DateTime.parse(map['date']).isAfter(startAt))
            .map((map) => DailyScoreModel.fromMap(_mapPostgresToScore(map)))
            .toList());
  }

  /// Bulk update privacy for all user goals in one SQL update.
  Future<void> updateAllGoalsPrivacy(String userId, String visibility) async {
    await _client
        .from('goals')
        .update({'visibility': visibility})
        .eq('user_id', userId);
  }

  // ─── Mappings ──────────────────────────────────────────────────

  Map<String, dynamic> _mapPostgresToScore(Map<String, dynamic> pg) {
    return {
      'id': pg['id'],
      'userId': pg['user_id'],
      'date': pg['date'],
      'score': pg['score'],
      'xpGained': pg['xp_gained'],
      'tasksDone': pg['tasks_done'],
      'createdAt': pg['created_at'],
    };
  }
}

final statsServiceProvider = Provider<StatsService>((ref) {
  final sb = ref.watch(supabaseServiceProvider);
  return StatsService(sb);
});
