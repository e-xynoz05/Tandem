import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import 'auth_provider.dart';

/// Splash screen — app entry point.
///
/// Shows the Tandem logo (two overlapping circles — violet + coral),
/// the app logo, and auto-navigates
/// after 2.2 seconds based on auth state.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    // Auto-navigate after 2.2s
    _navTimer = Timer(const Duration(milliseconds: 2200), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    try {
      final authState = ref.read(authProvider);
      if (authState is Authenticated) {
        context.go(RouteNames.home);
      } else {
        context.go(RouteNames.login);
      }
    } catch (_) {
      // Auth session not found — go to login
      context.go(RouteNames.login);
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    return Scaffold(
      backgroundColor: colors.background,
      body: FadeTransition(
        opacity: _fadeIn,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Tandem Logo ─────────────────────────────────
              _TandemLogo(colors: colors),
              const SizedBox(height: 32),

              const SizedBox(height: 12),

              // ─── App name ────────────────────────────────────
              Text(
                'Tandem',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                'Grow together. Daily.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: colors.textMuted),
              ),
            ],
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
      width: 90,
      height: 60,
      child: CustomPaint(
        painter: _LogoPainter(
          leftColor: colors.primary,
          rightColor: colors.secondary,
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.leftColor, required this.rightColor});
  final Color leftColor;
  final Color rightColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height * 0.4;
    final cy = size.height / 2;
    final gap = radius * 0.6;

    // Left circle (violet)
    canvas.drawCircle(
      Offset(size.width / 2 - gap, cy),
      radius,
      Paint()..color = leftColor.withValues(alpha: 0.75),
    );

    // Right circle (coral)
    canvas.drawCircle(
      Offset(size.width / 2 + gap, cy),
      radius,
      Paint()..color = rightColor.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.leftColor != leftColor || old.rightColor != rightColor;
}
