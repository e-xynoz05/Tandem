import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/models/daily_score_model.dart';
import '../../core/models/routine_model.dart';
import '../../core/services/routine_service.dart';
import '../auth/auth_provider.dart';
import '../duo/duo_provider.dart';
import 'local_completion_cache.dart';

/// Provider that combines routine templates and completions into a list of [RoutineModel]s.
final duoRoutinesProvider = StreamProvider<List<RoutineModel>>((ref) {
  final routineService = ref.watch(routineServiceProvider);
  final duoAsync = ref.watch(duoDocumentProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (currentUser == null) return Stream.value([]);

  final duoId = duoAsync.value?.id;
  final userId = currentUser.uid;

  final templatesStream = routineService.watchAllRoutines(userId, duoId);
  final completionsStream = routineService.watchCompletions();
  final localOverridesStream = ref.watch(localOverridesProvider.notifier).stream;
  final localOverrides = ref.watch(localOverridesProvider);

  return Rx.combineLatest3<List<RoutineModel>, List<Map<String, dynamic>>, Map<String, bool>, List<RoutineModel>>(
    templatesStream,
    completionsStream,
    Stream.value(localOverrides).concatWith([localOverridesStream]),
    (templates, completions, overrides) {
    final now = DateTime.now().toUtc();

      return templates.map((template) {
        final isSolo = template.duoId == null;
        
        bool isCompleted;
        bool partnerCompleted = false;

        if (isSolo) {
          final override = overrides[template.id.toString()];
          if (override != null) {
            isCompleted = override;
          } else {
            isCompleted = completions.any((c) => 
                c['routine_id'].toString() == template.id.toString() && 
                c['user_id'].toString() == userId.toString());
          }
        } else {
          final routineKey = template.id.toString();
          final override = overrides[routineKey];
          if (override != null) {
            isCompleted = override;
          } else {
            isCompleted = completions.any((c) {
              final sameRoutine = c['routine_id'].toString() == template.id.toString();
              final sameUser = c['user_id'].toString() == userId.toString();
              if (!sameRoutine || !sameUser) return false;

              final completedAtStr = c['completed_at']?.toString() ?? c['created_at']?.toString();
              if (completedAtStr == null) return false;
              
              final completedAt = DateTime.tryParse(completedAtStr);
              if (completedAt == null) return false;

              return completedAt.year == now.year && 
                     completedAt.month == now.month && 
                     completedAt.day == now.day;
            });
          }

          if (duoId != null) {
            final duo = duoAsync.value;
            final partnerId = duo?.userAId == userId ? duo?.userBId : duo?.userAId;
            
            partnerCompleted = completions.any((c) {
              final sameRoutine = c['routine_id'].toString() == template.id.toString();
              final sameUser = c['user_id'].toString() == partnerId.toString();
              if (!sameRoutine || !sameUser) return false;

              final completedAtStr = c['completed_at']?.toString() ?? c['created_at']?.toString();
              if (completedAtStr == null) return false;
              
              final completedAt = DateTime.tryParse(completedAtStr);
              if (completedAt == null) return false;

              return completedAt.year == now.year && 
                     completedAt.month == now.month && 
                     completedAt.day == now.day;
            });
          }
        }
        
        return template.copyWith(
          isCompleted: isCompleted,
          partnerCompleted: partnerCompleted,
        );
      }).toList();
    },
  );
});

/// Provides 30 days of routine completion history for the current user.
final routineHistoryProvider = StreamProvider<List<DailyScoreModel>>((ref) {
  final routineService = ref.watch(routineServiceProvider);
  final currentUser = ref.watch(currentUserProvider);
  final duoAsync = ref.watch(duoDocumentProvider);

  if (currentUser == null) return Stream.value([]);

  final userId = currentUser.uid;
  final duoId = duoAsync.value?.id;

  final templatesStream = routineService.watchAllRoutines(userId, duoId);
  final completionsStream = routineService.watchCompletions();

  return Rx.combineLatest2<List<RoutineModel>, List<Map<String, dynamic>>, List<DailyScoreModel>>(
    templatesStream,
    completionsStream,
    (templates, allCompletions) {
      final history = <DailyScoreModel>[];
      final now = DateTime.now().toUtc();
      
      for (int i = 29; i >= 0; i--) {
        final date = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: i));
        final nextDate = date.add(const Duration(days: 1));

        final userRoutines = templates.where((r) => r.userId == userId || (r.duoId != null && r.duoId == duoId)).toList();
        
        if (userRoutines.isEmpty) {
          history.add(_emptyScore(date, userId));
          continue;
        }

        final categoryCompletions = <String, int>{};
        final categoryTotals = <String, int>{};
        
        for (final r in userRoutines) {
          final cat = r.category.toLowerCase().trim();
          categoryTotals[cat] = (categoryTotals[cat] ?? 0) + 1;
        }

        final completionsOnDay = allCompletions.where((c) {
          if (c['user_id'].toString() != userId.toString()) return false;
          final completedAt = DateTime.tryParse(c['completed_at']?.toString() ?? '') ?? 
                             DateTime.tryParse(c['created_at']?.toString() ?? '') ?? 
                             DateTime.now();
          return completedAt.isAfter(date) && completedAt.isBefore(nextDate);
        }).toList();

        for (final c in completionsOnDay) {
          final routineId = c['routine_id'].toString();
          final template = userRoutines.where((r) => r.id.toString() == routineId).firstOrNull;
          if (template != null) {
            final cat = template.category.toLowerCase().trim();
            categoryCompletions[cat] = (categoryCompletions[cat] ?? 0) + 1;
          }
        }

        double getScore(String cat) {
          final total = categoryTotals[cat] ?? 0;
          if (total == 0) return 0.0;
          return (categoryCompletions[cat] ?? 0) / total;
        }

        final overallScore = completionsOnDay.length / userRoutines.length;

        history.add(DailyScoreModel(
          id: date.toIso8601String(),
          userId: userId,
          overall: overallScore,
          fitness: getScore('fitness'),
          career: getScore('career'),
          relationships: getScore('relationships'),
          learning: getScore('learning'),
          mindfulness: getScore('mindfulness'),
          date: date,
        ));
      }
      return history;
    },
  );
});

/// Provides 30 days of routine completion history for the partner.
final partnerRoutineHistoryProvider = StreamProvider<List<DailyScoreModel>>((ref) {
  final routineService = ref.watch(routineServiceProvider);
  final duoAsync = ref.watch(duoDocumentProvider);
  final currentUser = ref.watch(currentUserProvider);

  final duo = duoAsync.value;
  if (duo == null || currentUser == null) return Stream.value([]);

  final partnerId = duo.userAId == currentUser.uid ? duo.userBId : duo.userAId;
  if (partnerId.isEmpty) return Stream.value([]);

  final duoId = duo.id;
  final templatesStream = routineService.watchAllRoutines(partnerId, duoId);
  final completionsStream = routineService.watchCompletions();

  return Rx.combineLatest2<List<RoutineModel>, List<Map<String, dynamic>>, List<DailyScoreModel>>(
    templatesStream,
    completionsStream,
    (templates, allCompletions) {
      final history = <DailyScoreModel>[];
      final now = DateTime.now().toUtc();

      for (int i = 29; i >= 0; i--) {
        final date = DateTime.utc(now.year, now.month, now.day).subtract(Duration(days: i));
        final nextDate = date.add(const Duration(days: 1));

        final partnerRoutines = templates.where((r) => r.userId == partnerId || (r.duoId != null && r.duoId == duoId)).toList();

        if (partnerRoutines.isEmpty) {
          history.add(_emptyScore(date, partnerId));
          continue;
        }

        final categoryCompletions = <String, int>{};
        final categoryTotals = <String, int>{};
        
        for (final r in partnerRoutines) {
          final cat = r.category.toLowerCase().trim();
          categoryTotals[cat] = (categoryTotals[cat] ?? 0) + 1;
        }

        final completionsOnDay = allCompletions.where((c) {
          if (c['user_id'].toString() != partnerId.toString()) return false;
          final completedAt = DateTime.tryParse(c['completed_at']?.toString() ?? '') ?? 
                             DateTime.tryParse(c['created_at']?.toString() ?? '') ?? 
                             DateTime.now();
          return completedAt.isAfter(date) && completedAt.isBefore(nextDate);
        }).toList();

        for (final c in completionsOnDay) {
          final routineId = c['routine_id'].toString();
          final template = partnerRoutines.where((r) => r.id.toString() == routineId).firstOrNull;
          if (template != null) {
            final cat = template.category.toLowerCase().trim();
            categoryCompletions[cat] = (categoryCompletions[cat] ?? 0) + 1;
          }
        }

        double getScore(String cat) {
          final total = categoryTotals[cat] ?? 0;
          if (total == 0) return 0.0;
          return (categoryCompletions[cat] ?? 0) / total;
        }

        final overallScore = completionsOnDay.length / partnerRoutines.length;

        history.add(DailyScoreModel(
          id: date.toIso8601String(),
          userId: partnerId,
          overall: overallScore,
          fitness: getScore('fitness'),
          career: getScore('career'),
          relationships: getScore('relationships'),
          learning: getScore('learning'),
          mindfulness: getScore('mindfulness'),
          date: date,
        ));
      }
      return history;
    },
  );
});

/// Latest aggregated routine progress for the radar chart.
final routineProgressProvider = Provider<Map<String, double>>((ref) {
  final historyAsync = ref.watch(routineHistoryProvider);
  return historyAsync.maybeWhen(
    data: (history) {
      if (history.isEmpty) return _emptyProgress();
      final latest = history.last;
      return {
        'fitness': latest.fitness,
        'career': latest.career,
        'relationships': latest.relationships,
        'learning': latest.learning,
        'mindfulness': latest.mindfulness,
      };
    },
    orElse: () => _emptyProgress(),
  );
});

Map<String, double> _emptyProgress() {
  return {
    'fitness': 0.0,
    'career': 0.0,
    'relationships': 0.0,
    'learning': 0.0,
    'mindfulness': 0.0,
  };
}

DailyScoreModel _emptyScore(DateTime date, String userId) {
  return DailyScoreModel(
    id: date.toIso8601String(),
    userId: userId,
    overall: 0,
    fitness: 0,
    career: 0,
    relationships: 0,
    learning: 0,
    mindfulness: 0,
    date: date,
  );
}
