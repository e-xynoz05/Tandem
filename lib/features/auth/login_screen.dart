import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import 'auth_provider.dart';

/// Login screen with email/password, Google sign-in, and error shake animation.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -12, end: 12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 12, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await ref.read(authProvider.notifier).signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState is Unauthenticated && authState.error != null) {
        setState(() {
          _isLoading = false;
          _errorText = authState.error;
        });
        _shakeController.forward(from: 0);
      } else if (authState is Authenticated) {
        context.go(RouteNames.home);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = e.toString();
      });
      _shakeController.forward(from: 0);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await ref.read(authProvider.notifier).signInWithGoogle();

      if (!mounted) return;

      final authState = ref.read(authProvider);
      if (authState is Unauthenticated && authState.error != null) {
        setState(() {
          _isLoading = false;
          _errorText = authState.error;
        });
        _shakeController.forward(from: 0);
      } else if (authState is Authenticated) {
        context.go(RouteNames.home);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorText = e.toString();
      });
      _shakeController.forward(from: 0);
    }
  }

  Future<void> _handleGuestSignIn() async {
    debugPrint('Guest Sign-In button pressed');
    setState(() {
      _isLoading = true;
      _errorText = null;
    });
    try {
      await ref.read(authProvider.notifier).signInAsGuest();
      debugPrint('signInAsGuest call completed');
      
      if (!mounted) return;
      
      final authState = ref.read(authProvider);
      debugPrint('Auth state after guest sign-in: ${authState.runtimeType}');
      
      if (authState is Authenticated) {
        debugPrint('Navigating to Home...');
        context.go(RouteNames.home);
      } else if (authState is Unauthenticated && authState.error != null) {
        setState(() {
          _isLoading = false;
          _errorText = authState.error;
        });
        _shakeController.forward(from: 0);
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Guest Sign-In Button Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = e.toString();
        });
        _shakeController.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is Unauthenticated && next.error != null) {
        setState(() {
          _isLoading = false;
          _errorText = next.error;
        });
        _shakeController.forward(from: 0);
      }
    });

    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    // Listen for auth state changes to show errors from redirects (e.g. email confirmation failure)
    final authState = ref.watch(authProvider);
    if (authState is Unauthenticated && authState.error != null && _errorText == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _errorText = authState.error;
          });
          _shakeController.forward(from: 0);
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // ─── Logo ────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      _TandemLogo(colors: colors),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Center(
                  child: Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    'Sign in to continue your streak',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: colors.textMuted),
                  ),
                ),
                const SizedBox(height: 32),

                // ─── Error message ────────────────────────────
                if (_errorText != null) ...[
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_shakeAnimation.value, 0),
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: colors.secondary, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorText!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: colors.secondary),
                                ),
                              ),
                            ],
                          ),
                          if (_errorText!.toLowerCase().contains('email not confirmed')) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => context.push('/otp-verification?email=${Uri.encodeComponent(_emailController.text.trim())}'),
                              child: Text(
                                'Verify your email now',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ─── Email field ──────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ─── Password field ───────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ─── Login button ─────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Log In'),
                  ),
                ),
                const SizedBox(height: 16),

                // ─── Divider ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: colors.textMuted.withValues(alpha: 0.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'or',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colors.textMuted),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: colors.textMuted.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ─── Google sign-in ───────────────────────────
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                    label: const Text('Sign in with Google'),
                  ),
                ),
                const SizedBox(height: 12),
                
                // ─── Guest sign-in ────────────────────────────
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleGuestSignIn,
                    child: Text(
                      'Continue as Guest',
                      style: TextStyle(
                        color: colors.textMuted,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ─── Sign up link ─────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () => context.go(RouteNames.signup),
                    child: Text.rich(
                      TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: colors.textMuted),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two overlapping circles representing the Tandem brand.
class _TandemLogo extends StatelessWidget {
  const _TandemLogo({required this.colors});
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 4,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.7),
              ),
            ),
          ),
          Positioned(
            right: 4,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.secondary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
