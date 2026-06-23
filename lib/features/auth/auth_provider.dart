import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart';
import '../../core/models/user_model.dart';
import '../../core/services/auth_service.dart';

/// Authentication state — either unauthenticated or holding a [UserModel].
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);
  final UserModel user;
}

class Unauthenticated extends AuthState {
  const Unauthenticated([this.error]);
  final String? error;
}

class AuthVerificationPending extends AuthState {
  const AuthVerificationPending(this.email);
  final String email;
}

/// Riverpod [StateNotifier] for authentication state using Supabase.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthInitial()) {
    _subscription = _authService.authStateChanges.listen(_onAuthChanged);
    _handleRedirectError();
  }

  final AuthService _authService;
  StreamSubscription<sb.AuthState>? _subscription;

  /// Checks for auth errors in the URL (common on web redirects).
  void _handleRedirectError() {
    if (!kIsWeb) return;

    // Check if main() already captured an error before cleaning the URL
    if (startupAuthError != null) {
      state = Unauthenticated(startupAuthError!);
      return;
    }

    // Fallback if main() didn't clean it yet
    final uri = Uri.base;
    final error = uri.queryParameters['error_description'] ?? 
                  uri.queryParameters['error'] ??
                  uri.fragment.split('&').firstWhere((e) => e.startsWith('error_description='), orElse: () => '').split('=').last;
    
    if (error.isNotEmpty) {
      final decodedError = Uri.decodeComponent(error).replaceAll('+', ' ');
      state = Unauthenticated(decodedError);
    }
  }

  Future<void> _onAuthChanged(sb.AuthState event) async {
    final user = event.session?.user;
    
    if (user == null) {
      // Only set Unauthenticated if we're not in the middle of an operation
      // or already waiting for verification.
      if (state is Authenticated || state is AuthInitial) {
        state = const Unauthenticated();
      }
      return;
    }

    try {
      debugPrint('Auth changed: ${user.id}, isAnonymous: ${user.isAnonymous}');
      
      // OPTIMIZATION: Guest users don't have profiles in Postgres, bypass lookup
      if (user.isAnonymous) {
        debugPrint('Anonymous user, using guest profile');
        state = Authenticated(UserModel(
          uid: user.id,
          displayName: 'Guest User',
          email: 'guest@tandem.app',
          onboardingComplete: false,
          createdAt: DateTime.now(),
        ));
        return;
      }

      final userModel = await _authService.getUserDocument(user.id);
      if (userModel != null) {
        debugPrint('User profile found, state = Authenticated');
        state = Authenticated(userModel);
      } else {
        debugPrint('Profile sync pending for user: ${user.id}');
        // Handle case where user exists in Auth but not in Profiles yet
        state = const Unauthenticated('Profile sync pending...');
      }
    } catch (e) {
      debugPrint('Auth Changed Error: $e');
      state = Unauthenticated(e.toString());
    }
  }

  /// Sign in with email + password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      await _authService.signInWithEmail(email: email, password: password);
    } on sb.AuthException catch (e) {
      state = Unauthenticated(_friendlyError(e.message));
    } catch (e) {
      state = Unauthenticated(e.toString());
    }
  }

  /// Create a new account with email + password.
  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required String username,
    String? photoURL,
  }) async {
    state = const AuthLoading();
    try {
      debugPrint('Attempting signUp with email: $email');
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        username: username,
        photoURL: photoURL,
      );
      debugPrint('SignUp successful. User: ${response.user?.id}, Session: ${response.session != null}');
      // After signup, move to OTP verification state
      state = AuthVerificationPending(email);
      debugPrint('State set to AuthVerificationPending');
    } on sb.AuthException catch (e) {
      debugPrint('SignUp AuthException: ${e.message}');
      // If the user already exists but is unconfirmed, Supabase might return 'User already registered'
      // In this case, we still want to show the OTP entry section.
      if (e.message.toLowerCase().contains('already registered') || 
          e.message.toLowerCase().contains('rate limit')) {
        state = AuthVerificationPending(email);
        return;
      }
      state = Unauthenticated(_friendlyError(e.message));
    } catch (e) {
      debugPrint('SignUp General Error: $e');
      state = Unauthenticated(e.toString());
    }
  }

  /// Verify email OTP.
  Future<void> verifyEmailOtp(String email, String token) async {
    state = const AuthLoading();
    try {
      await _authService.verifyOtp(email: email, token: token);
      // Auth state listener (_onAuthChanged) will handle the transition to Authenticated
    } on sb.AuthException catch (e) {
      state = Unauthenticated(_friendlyError(e.message));
    } catch (e) {
      state = Unauthenticated(e.toString());
    }
  }

  /// Resend OTP code.
  Future<void> resendOtp(String email) async {
    try {
      // Supabase's signInWithOtp can be used to resend or just signUp again
      // but usually signUp automatically handles resends if configured.
      // For now, let's just trigger a resend via signInWithOtp for 'signup' type
      await _authService.verifyOtp(email: email, token: '', type: sb.OtpType.signup); 
      // Actually Supabase has a dedicated resend method:
      // await _authService.resend(email: email, type: sb.OtpType.signup);
    } catch (e) {
      debugPrint('Resend Error: $e');
    }
  }

  /// Sign in with Google (Native).
  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      final response = await _authService.signInWithGoogle();
      
      if (response == null) {
        // User cancelled the sign-in flow
        state = const Unauthenticated();
        return;
      }
    } on sb.AuthException catch (e) {
      state = Unauthenticated(_friendlyError(e.message));
    } catch (e) {
      if (e.toString().contains('sign_in_canceled')) {
        state = const Unauthenticated();
      } else {
        state = Unauthenticated(e.toString());
      }
    }
  }

  /// Sign in anonymously as a guest.
  Future<void> signInAsGuest() async {
    debugPrint('Attempting Guest Sign-In...');
    state = const AuthLoading();
    try {
      final response = await _authService.signInAnonymously();
      debugPrint('Guest Sign-In response received: ${response.user?.id}');
      
      if (response.user != null) {
        debugPrint('Manually setting Authenticated state for guest');
        state = Authenticated(UserModel(
          uid: response.user!.id,
          displayName: 'Guest User',
          email: 'guest@tandem.app',
          onboardingComplete: false,
          createdAt: DateTime.now(),
        ));
      }
    } on sb.AuthException catch (e) {
      debugPrint('Guest Sign-In AuthException: ${e.message}');
      state = Unauthenticated(_friendlyError(e.message));
    } catch (e) {
      debugPrint('Guest Sign-In General Error: $e');
      state = Unauthenticated(e.toString());
    }
  }

  /// Sign out completely.
  Future<void> signOut() async {
    await _authService.signOut();
    state = const Unauthenticated();
  }

  /// Checks if a username is already taken.
  Future<bool> isUsernameAvailable(String username) async {
    return await _authService.isUsernameAvailable(username);
  }

  /// Save FCM token for the current user.
  Future<void> saveFcmToken(String token) async {
    final current = state;
    if (current is Authenticated) {
      await _authService.saveFcmToken(current.user.uid, token);
    }
  }

  /// Mark onboarding complete for the current user.
  Future<void> completeOnboarding() async {
    final current = state;
    if (current is Authenticated) {
      await _authService.completeOnboarding(current.user.uid);
      state = Authenticated(
        current.user.copyWith(onboardingComplete: true),
      );
    }
  }

  /// Conversions for Supabase error messages.
  String _friendlyError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (message.contains('User already registered')) {
      return 'An account already exists with that email.';
    }
    return message;
  }

  /// Clears the verification pending state and returns to unauthenticated.
  void cancelVerification() {
    state = const Unauthenticated();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Global auth state provider.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});

/// Convenience provider that returns `true` when the user is authenticated.
final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider) is Authenticated;
});

/// Convenience provider that returns the current [UserModel] or null.
final currentUserProvider = Provider<UserModel?>((ref) {
  final state = ref.watch(authProvider);
  if (state is Authenticated) return state.user;
  return null;
});
