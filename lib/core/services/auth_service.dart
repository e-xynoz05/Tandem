import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';

/// Supabase Authentication service.
class AuthService {
  AuthService(this._sb);

  final SupabaseService _sb;

  sb.SupabaseClient get _client => _sb.client;

  /// Current Supabase session user.
  sb.User? get currentUser => _client.auth.currentUser;

  /// Stream of authentication state changes.
  Stream<sb.AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Signs in with email and password.
  Future<sb.AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return response;
  }

  /// Creates a new user with email and password.
  /// (SQL Trigger handles profile creation in Supabase)
  Future<sb.AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String username,
    String? photoURL,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'display_name': displayName,
        'username': username,
        if (photoURL != null) 'photo_url': photoURL,
      },
    );
    return response;
  }

  /// Verifies a 6-digit OTP code sent via email.
  Future<sb.AuthResponse> verifyOtp({
    required String email,
    required String token,
    sb.OtpType type = sb.OtpType.signup,
  }) async {
    final response = await _client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: type,
    );
    return response;
  }

  /// Signs in anonymously as a guest.
  Future<sb.AuthResponse> signInAnonymously() async {
    return await _client.auth.signInAnonymously();
  }

  /// Checks if a username is already taken.
  Future<bool> isUsernameAvailable(String username) async {
    final response = await _client
        .from('profiles')
        .select('username')
        .eq('username', username.toLowerCase().trim())
        .maybeSingle();
    return response == null;
  }

  /// Signs in with Google using native SDK.
  Future<sb.AuthResponse?> signInWithGoogle() async {
    // 1. Configure Native Google Sign-In
    const webClientId = '548760692644-j7un14k8vhrfugc8ih07o218tq2qb1ft.apps.googleusercontent.com';
    
    final googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? webClientId : null,
      serverClientId: !kIsWeb ? webClientId : null,
    );

    // 2. Trigger Native Sign-In
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null; // User cancelled

    // 3. Obtain Tokens
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw const sb.AuthException('Failed to obtain ID Token from Google.');
    }

    // 4. Authenticate with Supabase
    return await _client.auth.signInWithIdToken(
      provider: sb.OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Fetch the current user's profile from Postgres.
  Future<UserModel?> getUserDocument(String uid) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (response == null) return null;
    
    // Map SnakeCase Postgres to CamelCase UserModel
    return UserModel.fromMap(_mapPostgresToModel(response));
  }

  /// Saves the FCM token to the user's profile.
  Future<void> saveFcmToken(String uid, String token) async {
    await _client.from('profiles').update({'fcmToken': token}).eq('id', uid);
  }

  /// Marks onboarding as complete for the user.
  Future<void> completeOnboarding(String uid) async {
    await _client.from('profiles').update({'onboardingComplete': true}).eq('id', uid);
  }

  /// Updates the user's profile in Postgres.
  Future<void> updateProfile(UserModel user) async {
    await _client.from('profiles')
        .update(_mapModelToPostgres(user.toMap()))
        .eq('id', user.uid);
  }

  Map<String, dynamic> _mapPostgresToModel(Map<String, dynamic> pg) {
    return {
      'uid': pg['id'],
      'displayName': pg['display_name'],
      'username': pg['username'],
      'email': pg['email'],
      'photoURL': pg['photo_url'],
      'duoPartnerId': pg['duo_partner_id'],
      'duoInviteCode': pg['duo_invite_code'],
      'fcmToken': pg['fcm_token'] ?? '',
      'streakCount': pg['streak_count'],
      'totalXP': pg['total_xp'],
      'tasksCompleted': pg['tasks_completed'],
      'onboardingComplete': pg['onboarding_complete'],
      'avatarUrl': pg['avatar_url'] ?? '',
      'avatarConfig': pg['avatar_config'] ?? {},
      'badges': pg['badges'] ?? [],
      'lastActiveDate': pg['updated_at'],
      'createdAt': pg['created_at'],
    };
  }

  Map<String, dynamic> _mapModelToPostgres(Map<String, dynamic> model) {
    return {
      'display_name': model['displayName'],
      'username': model['username'],
      'email': model['email'],
      'duo_partner_id': model['duoPartnerId'],
      'duo_invite_code': model['duoInviteCode'],
      'streak_count': model['streakCount'],
      'total_xp': model['totalXP'],
      'tasks_completed': model['tasksCompleted'],
      'onboarding_complete': model['onboardingComplete'],
      'avatar_url': model['avatarUrl'],
      'avatar_config': model['avatarConfig'],
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}

/// Global singleton provider for [AuthService].
final authServiceProvider = Provider<AuthService>((ref) {
  final sb = ref.watch(supabaseServiceProvider);
  return AuthService(sb);
});
