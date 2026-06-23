import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';
import '../models/workout_plan_model.dart';
import '../models/workout_session_model.dart';

class WorkoutService {
  WorkoutService(this._sb);

  final SupabaseService _sb;
  SupabaseClient get _client => _sb.client;

  // ─── Workout Plans ──────────────────────────────────────────

  /// Stream all workout plans for a user from Postgres.
  Stream<List<WorkoutPlanModel>> watchPlans(String userId) {
    return _client
        .from('workout_plans')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data
            .map((map) => WorkoutPlanModel.fromMap(_mapPostgresToPlan(map)))
            .toList());
  }

  /// Create a new workout plan in Supabase.
  Future<String> createPlan(WorkoutPlanModel plan) async {
    final response = await _client
        .from('workout_plans')
        .insert(_mapPlanToPostgres(plan))
        .select('id')
        .single();
    
    return response['id'] as String;
  }

  // ─── Workout Sessions ───────────────────────────────────────

  /// Stream this week's workout sessions for a user.
  Stream<List<WorkoutSessionModel>> watchThisWeeksSessions(String userId) {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonday = DateTime(monday.year, monday.month, monday.day);

    return _client
        .from('workout_sessions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) => data
            .where((map) => DateTime.parse(map['started_at']).isAfter(startOfMonday))
            .map((map) => WorkoutSessionModel.fromMap(_mapPostgresToSession(map)))
            .toList());
  }

  /// Start a new workout session in Supabase.
  Future<String> startSession(WorkoutSessionModel session) async {
    final response = await _client
        .from('workout_sessions')
        .insert(_mapSessionToPostgres(session))
        .select('id')
        .single();
    
    return response['id'] as String;
  }

  /// Complete a workout session in Supabase.
  Future<void> completeSession(WorkoutSessionModel session) async {
    await _client
        .from('workout_sessions')
        .update(_mapSessionToPostgres(session))
        .eq('id', session.id);
  }

  // ─── Mappings ──────────────────────────────────────────────────

  Map<String, dynamic> _mapPlanToPostgres(WorkoutPlanModel plan) {
    return {
      'user_id': plan.userId,
      'title': plan.title,
      'description': plan.description,
      'category': plan.category,
      'difficulty': plan.difficulty,
      'exercises': plan.exercises.map((e) => e.toMap()).toList(),
    };
  }

  Map<String, dynamic> _mapPostgresToPlan(Map<String, dynamic> pg) {
    return {
      'id': pg['id'],
      'userId': pg['user_id'],
      'title': pg['title'],
      'description': pg['description'],
      'category': pg['category'],
      'difficulty': pg['difficulty'],
      'exercises': pg['exercises'],
      'createdAt': pg['created_at'],
    };
  }

  Map<String, dynamic> _mapSessionToPostgres(WorkoutSessionModel session) {
    return {
      'user_id': session.userId,
      'plan_id': session.planId,
      'title': session.title,
      'started_at': session.startedAt.toIso8601String(),
      'completed_at': session.completedAt?.toIso8601String(),
      'total_volume': session.totalVolume,
      'data': session.exerciseLogs.map((e) => e.toMap()).toList(),
    };
  }

  Map<String, dynamic> _mapPostgresToSession(Map<String, dynamic> pg) {
    return {
      'id': pg['id'],
      'userId': pg['user_id'],
      'planId': pg['plan_id'],
      'title': pg['title'],
      'startedAt': pg['started_at'],
      'completedAt': pg['completed_at'],
      'totalVolume': pg['total_volume'],
      'data': pg['data'],
      'createdAt': pg['created_at'],
    };
  }
}

final workoutServiceProvider = Provider<WorkoutService>((ref) {
  final sb = ref.watch(supabaseServiceProvider);
  return WorkoutService(sb);
});
