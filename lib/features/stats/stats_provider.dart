import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/daily_score_model.dart';
import '../../core/services/stats_service.dart';
import '../auth/auth_provider.dart';
import '../duo/duo_provider.dart';
import '../home/home_provider.dart';

// ─── Streams ──────────────────────────────────────────────────

/// Stream 30 days of daily scores for the current user.
final dailyScoresProvider = StreamProvider<List<DailyScoreModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);
  return ref.watch(statsServiceProvider).watchDailyScores(user.uid);
});

/// Stream partner's daily scores.
final partnerScoresProvider = StreamProvider<List<DailyScoreModel>>((ref) {
  final duoDoc = ref.watch(duoDocumentProvider).value;
  final currentUid = ref.read(currentUserProvider)?.uid;
  
  if (duoDoc == null || currentUid == null) return Stream.value([]);
  
  final partnerId = duoDoc.userAId == currentUid ? duoDoc.userBId : duoDoc.userAId;

  if (partnerId.isEmpty) return Stream.value([]);
  
  return ref.watch(statsServiceProvider).watchDailyScores(partnerId);
});

// ─── Computed Stats ───────────────────────────────────────────

class StatsStats {
  const StatsStats({
    required this.overallLifeScore,
    required this.weakestCategory,
    required this.strongestCategory,
    required this.currentStreak,
  });

  final double overallLifeScore;
  final String weakestCategory;
  final String strongestCategory;
  final int currentStreak;
}

final computedStatsProvider = Provider<StatsStats>((ref) {
  final progress = ref.watch(lifeProgressProvider);
  if (progress.isEmpty) {
    return const StatsStats(
      overallLifeScore: 0.0,
      weakestCategory: 'None',
      strongestCategory: 'None',
      currentStreak: 0,
    );
  }

  final sortedByValue = progress.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
  final homeState = ref.watch(homeProvider);

  return StatsStats(
    overallLifeScore: progress.values.reduce((a, b) => a + b) / progress.length,
    weakestCategory: sortedByValue.first.key,
    strongestCategory: sortedByValue.last.key,
    currentStreak: homeState.streakCount,
  );
});

// ─── Actions ──────────────────────────────────────────────────

class StatsNotifier extends StateNotifier<bool> {
  StatsNotifier(this._ref) : super(false);
  final Ref _ref;

  Future<void> updateAllPrivacy(String visibility) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    
    state = true;
    await _ref.read(statsServiceProvider).updateAllGoalsPrivacy(user.uid, visibility);
    state = false;
  }
}

final statsActionProvider = StateNotifierProvider<StatsNotifier, bool>((ref) {
  return StatsNotifier(ref);
});
