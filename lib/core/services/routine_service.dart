import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'supabase_service.dart';
import '../models/routine_model.dart';
import '../../features/routines/local_completion_cache.dart';

class RoutineService {
  RoutineService(this._sb, this._ref);

  final SupabaseService _sb;
  final Ref _ref;
  SupabaseClient get _client => _sb.client;

  /// Creates a new routine (shared or solo).
  Future<void> createRoutine(RoutineModel routine) async {
    await _client.from('routines').insert(routine.toMap());
  }

  /// Deletes a routine template and its completions.
  Future<void> deleteRoutine(String routineId) async {
    // Delete completions first to avoid foreign key constraints
    await _client.from('routine_completions').delete().eq('routine_id', routineId);
    // Then delete the template
    await _client.from('routines').delete().eq('id', routineId);
  }

  /// Toggles a routine completion for the current user.
  Future<void> toggleRoutine(String routineId, String userId, bool completed) async {
    if (completed) {
      try {
        debugPrint('Attempting to mark routine $routineId as done for user $userId');
        
        // Optimistically update local cache: force DONE
        _ref.read(localOverridesProvider.notifier).update((state) => {...state, routineId: true});

        await _client.from('routine_completions').insert({
          'routine_id': routineId,
          'user_id': userId,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        });
        debugPrint('Successfully marked routine as done');
      } catch (e) {
        debugPrint('Error marking routine as done: $e');
        // If it's a duplicate key, it means it's already done, so we keep it in the cache
        if (e.toString().contains('23505')) {
          _ref.read(localOverridesProvider.notifier).update((state) => {...state, routineId: true});
        } else {
          // For other errors, remove override so it falls back to DB
          _ref.read(localOverridesProvider.notifier).update((state) {
            final newState = Map<String, bool>.from(state);
            newState.remove(routineId);
            return newState;
          });
        }
      }
    } else {
      // For shared routines, we usually reset daily. 
      // For solo, the user said it doesn't need to reset daily.
      // To keep it simple, we delete the most recent completion for this user.
      try {
        debugPrint('Attempting to unmark routine $routineId for user $userId');
        
        // Optimistically update local cache: force UNDONE
        debugPrint('Setting override FALSE for $routineId');
        _ref.read(localOverridesProvider.notifier).update((state) => {...state, routineId: false});

        await _client
            .from('routine_completions')
            .delete()
            .eq('routine_id', routineId)
            .eq('user_id', userId);
        debugPrint('Successfully unmarked routine');
      } catch (e) {
        debugPrint('Error unmarking routine: $e');
      }
    }
  }

  Stream<List<RoutineModel>> watchAllRoutines(String userId, String? duoId) {
    final stream = _client.from('routines').stream(primaryKey: ['id']);
    
    final polling = Stream.periodic(const Duration(seconds: 10))
        .asyncMap((_) => _client.from('routines').select());

    return Rx.merge([stream, polling]).map((maps) {
      return maps
          .where((map) {
            final rDuoId = map['duo_id'] as String?;
            final rUserId = map['user_id'] as String?;
            if (duoId != null && rDuoId == duoId) return true;
            if (rDuoId == null && rUserId == userId) return true;
            return false;
          })
          .map((map) => RoutineModel.fromMap(map))
          .toList();
    }).shareValue();
  }

  /// Watches all completions.
  Stream<List<Map<String, dynamic>>> watchCompletions() {
    // Combine the real-time stream with a periodic fetch as a fallback
    // This ensures data is updated even if Realtime is not enabled on the table
    final stream = _client
        .from('routine_completions')
        .stream(primaryKey: ['id']);
    
    final polling = Stream.periodic(const Duration(seconds: 5))
        .asyncMap((_) => _client.from('routine_completions').select());

    return Rx.merge([stream, polling]).shareValue();
  }
}

final routineServiceProvider = Provider<RoutineService>((ref) {
  final sb = ref.watch(supabaseServiceProvider);
  return RoutineService(sb, ref);
});
