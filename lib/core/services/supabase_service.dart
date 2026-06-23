import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Centralized service for Supabase interactions.
class SupabaseService {
  const SupabaseService();

  SupabaseClient get client => Supabase.instance.client;

  /// Helper for common table references
  SupabaseQueryBuilder from(String table) => client.from(table);

  /// Helper for auth
  GoTrueClient get auth => client.auth;
}

/// Global provider for [SupabaseService].
final supabaseServiceProvider = Provider<SupabaseService>((ref) => const SupabaseService());
