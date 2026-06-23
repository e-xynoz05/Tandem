import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/services/auth_service.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final colors = themeMode == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ─── Account Section ──────────────────────────────────
          _SettingsHeader(title: 'Account', colors: colors),
          if (user != null)
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: 'Display Name',
              subtitle: user.displayName,
              colors: colors,
            ),
          if (user?.username != null)
            _SettingsTile(
              icon: Icons.alternate_email_rounded,
              title: 'Username',
              subtitle: '@${user!.username}',
              colors: colors,
            ),
          _SettingsTile(
            icon: Icons.alternate_email_rounded,
            title: 'Email',
            subtitle: user?.email ?? 'Not logged in',
            colors: colors,
          ),

          const SizedBox(height: 32),

          // ─── Preferences Sector ───────────────────────────────
          _SettingsHeader(title: 'Preferences', colors: colors),
          _SettingsToggleTile(
            icon: Icons.dark_mode_rounded,
            title: 'Dark Mode',
            value: ref.watch(themeModeProvider) == ThemeMode.dark,
            onChanged: (isDark) {
              ref.read(themeModeProvider.notifier).toggle();
            },
            colors: colors,
          ),
          _SettingsToggleTile(
            icon: Icons.notifications_active_rounded,
            title: 'Push Notifications',
            value: true,
            onChanged: (val) {},
            colors: colors,
          ),

          const SizedBox(height: 32),

          // ─── Support Section ──────────────────────────────────
          _SettingsHeader(title: 'Support & Legal', colors: colors),
          _SettingsTile(icon: Icons.info_outline_rounded, title: 'App Version', subtitle: '1.0.0 (Build 42)', colors: colors),
          _SettingsTile(icon: Icons.description_outlined, title: 'Terms of Service', colors: colors),
          _SettingsTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', colors: colors),

          const SizedBox(height: 48),

          // ─── Sign Out ─────────────────────────────────────────
          ElevatedButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go(RouteNames.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary.withValues(alpha: 0.1),
              foregroundColor: colors.primary,
              elevation: 0,
              minimumSize: const Size.fromHeight(60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.primary, width: 1),
              ),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({required this.title, required this.colors});
  final String title;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: colors.primary, size: 22),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(color: colors.textMuted, fontSize: 13)) : null,
        trailing: const Icon(Icons.chevron_right_rounded, size: 20),
        onTap: () {},
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  const _SettingsToggleTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: SwitchListTile.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: colors.primary,
        secondary: Icon(icon, color: colors.primary, size: 22),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
