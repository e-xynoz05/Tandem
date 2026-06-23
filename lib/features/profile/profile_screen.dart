import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/route_names.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/auth_provider.dart';
import '../workout/workout_provider.dart';
import '../../core/models/avatar_config.dart';
import '../../core/widgets/avatar_widget.dart';
import '../duo/duo_provider.dart';
import 'avatar_builder.dart';

/// Profile tab — matching the Stitch "Profile & Duo" combined view.
///
/// Shows user avatar (with optional overlapping partner avatar),
/// stats row, badges, and menu items. Uses Coral/Black/White palette.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final sessionsAsync = ref.watch(weeklySessionsProvider);
    final partnerAsync = ref.watch(partnerUserProvider);

    final themeMode = ref.watch(themeModeProvider);
    final colors = themeMode == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    if (user == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(
          child: CircularProgressIndicator(color: colors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          // ─── Header with Duo Avatars ──────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.06),
              ),
              child: Column(
                children: [
                  // Settings button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(Icons.settings_rounded,
                          color: colors.textMuted),
                      onPressed: () =>
                          context.pushNamed(RouteNames.settings),
                    ),
                  ),

                  // Avatar stack (user + partner)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AvatarBuilder()),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Main user avatar
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.3),
                              width: 3,
                            ),
                          ),
                          child: AvatarWidget(
                            config:
                                AvatarConfig.fromMap(user.avatarConfig),
                            size: 100,
                          ),
                        ),
                        // Partner avatar (overlapping or placeholder)
                        partnerAsync.when(
                          data: (partner) {
                            if (partner == null) {
                              return Positioned(
                                right: -15,
                                bottom: -5,
                                child: GestureDetector(
                                  onTap: () => context.push('/routines/invite'),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colors.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.primary.withValues(alpha: 0.3),
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors.primary.withValues(alpha: 0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(Icons.person_add_rounded,
                                        color: colors.primary, size: 20),
                                  ),
                                ),
                              );
                            }
                            return Positioned(
                              right: -20,
                              bottom: -5,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.secondary
                                        .withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: AvatarWidget(
                                  config: AvatarConfig.fromMap(
                                      partner.avatarConfig),
                                  size: 48,
                                ),
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        // Edit badge
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: colors.background, width: 2),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.displayName ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
                  if (user.username != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  // Partner name
                  partnerAsync.when(
                    data: (partner) {
                      if (partner == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link_rounded,
                                  size: 14, color: colors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                'Paired with ${partner.displayName?.split(' ').first ?? 'Partner'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          // ─── Stats Row ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 20, horizontal: 8),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: colors.outlineVariant.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ProfileStat(
                      value: '${user.totalXP}',
                      label: 'XP',
                      icon: Icons.bolt_rounded,
                      iconColor: colors.primary,
                      colors: colors,
                    ),
                    _StatDivider(colors: colors),
                    _ProfileStat(
                      value: '${user.streakCount}',
                      label: 'Streak',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: colors.primaryContainer,
                      colors: colors,
                    ),
                    _StatDivider(colors: colors),
                    sessionsAsync.when(
                      data: (s) => _ProfileStat(
                        value: '${s.length}',
                        label: 'Workouts',
                        icon: Icons.fitness_center_rounded,
                        iconColor: colors.secondary,
                        colors: colors,
                      ),
                      loading: () => _ProfileStat(
                        value: '...',
                        label: 'Workouts',
                        icon: Icons.fitness_center_rounded,
                        iconColor: colors.textMuted,
                        colors: colors,
                      ),
                      error: (_, __) => _ProfileStat(
                        value: '0',
                        label: 'Workouts',
                        icon: Icons.fitness_center_rounded,
                        iconColor: colors.textMuted,
                        colors: colors,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Duo Section ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: partnerAsync.when(
                data: (partner) {
                  if (partner == null) {
                    return _InvitePartnerCard(colors: colors);
                  }
                  return _DuoStatusCard(
                    user: user,
                    partner: partner,
                    colors: colors,
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Badges',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: colors.text)),
                  Text('View All',
                      style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _BadgeItem(
                      icon: Icons.local_fire_department_rounded,
                      color: colors.primaryContainer,
                      label: 'Starter'),
                  _BadgeItem(
                      icon: Icons.fitness_center_rounded,
                      color: colors.primary,
                      label: 'Iron Mind'),
                  _BadgeItem(
                      icon: Icons.favorite_rounded,
                      color: colors.primaryContainer,
                      label: 'Warm Heart'),
                  _BadgeItem(
                      icon: Icons.self_improvement_rounded,
                      color: colors.secondary,
                      label: 'Zen Master'),
                  _BadgeItem(
                      icon: Icons.auto_awesome_rounded,
                      color: colors.tertiary,
                      label: 'Superstreak'),
                ],
              ),
            ),
          ),

          // ─── Menu Items ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                children: [
                  _ProfileMenuTile(
                    icon: Icons.history_rounded,
                    label: 'Activity Journal',
                    colors: colors,
                    onTap: () {},
                  ),
                  _ProfileMenuTile(
                    icon: Icons.shield_rounded,
                    label: 'Privacy Center',
                    colors: colors,
                    onTap: () => _showPrivacyDialog(context, ref, colors),
                  ),
                  _ProfileMenuTile(
                    icon: Icons.help_center_rounded,
                    label: 'Support & FAQ',
                    colors: colors,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context, WidgetRef ref, ColorTokens colors) {
    final currentPrivacy = ref.watch(privacyModeProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.shield_rounded, color: colors.primary, size: 24),
            const SizedBox(width: 12),
            Text('Privacy Center', style: TextStyle(color: colors.text)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Control who can see your progress and symmetry map.',
              style: TextStyle(color: colors.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _PrivacyOption(
              mode: PrivacyMode.public,
              icon: Icons.public_rounded,
              title: 'Public',
              subtitle: 'Visible to everyone',
              isSelected: currentPrivacy == PrivacyMode.public,
              colors: colors,
              onTap: () {
                ref.read(privacyModeProvider.notifier).state = PrivacyMode.public;
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            _PrivacyOption(
              mode: PrivacyMode.duo,
              icon: Icons.people_rounded,
              title: 'Duo Only',
              subtitle: 'Visible to your partner only',
              isSelected: currentPrivacy == PrivacyMode.duo,
              colors: colors,
              onTap: () {
                ref.read(privacyModeProvider.notifier).state = PrivacyMode.duo;
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            _PrivacyOption(
              mode: PrivacyMode.private,
              icon: Icons.lock_rounded,
              title: 'Private',
              subtitle: 'Visible to you only',
              isSelected: currentPrivacy == PrivacyMode.private,
              colors: colors,
              onTap: () {
                ref.read(privacyModeProvider.notifier).state = PrivacyMode.private;
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: TextStyle(color: colors.textMuted)),
          ),
        ],
      ),
    );
  }
}

class _PrivacyOption extends StatelessWidget {
  const _PrivacyOption({
    required this.mode,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.colors,
    required this.onTap,
  });

  final PrivacyMode mode;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final ColorTokens colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.1)
              : colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colors.primary : colors.outlineVariant.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? colors.primary : colors.textMuted),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? colors.primary : colors.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: colors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Duo Management Widgets ────────────────────────────────────────

class _InvitePartnerCard extends StatelessWidget {
  const _InvitePartnerCard({required this.colors});
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.people_outline_rounded,
                color: colors.primary, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Better Together',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite a partner to sync routines, share goals, and grow your energy ring together.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/routines/invite'),
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Invite Partner',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DuoStatusCard extends StatelessWidget {
  const _DuoStatusCard({
    required this.user,
    required this.partner,
    required this.colors,
  });

  final dynamic user;
  final dynamic partner;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your Avatar
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.primary, width: 2),
                    ),
                    child: AvatarWidget(
                      config: AvatarConfig.fromMap(user.avatarConfig),
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('You',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.text)),
                ],
              ),
              const SizedBox(width: 12),
              // Pulse line
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Partner Avatar
              Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.secondary, width: 2),
                    ),
                    child: AvatarWidget(
                      config: AvatarConfig.fromMap(partner.avatarConfig),
                      size: 60,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(partner.displayName?.split(' ').first ?? 'Partner',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.text)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: colors.outlineVariant.withValues(alpha: 0.1)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Duo Connection',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                    ),
                  ),
                  Text(
                    'Synced & Growing',
                    style: TextStyle(color: colors.success, fontSize: 12),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () => context.push('/routines/invite'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: colors.outlineVariant),
                ),
                child: Text('Manage',
                    style: TextStyle(color: colors.text, fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Other Profile Widgets ──────────────────────────────────────────
class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.colors,
  });
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colors.text)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: colors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider({required this.colors});
  final ColorTokens colors;
  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1,
        height: 36,
        color: colors.outlineVariant.withValues(alpha: 0.3));
  }
}

// ─── Badge Item ─────────────────────────────────────────────────────
class _BadgeItem extends StatelessWidget {
  const _BadgeItem(
      {required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─── Profile Menu Tile ──────────────────────────────────────────────
class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.colors,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final ColorTokens colors;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.primary, size: 20),
            ),
            const SizedBox(width: 14),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: colors.text)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: colors.textMuted),
          ],
        ),
      ),
    );
  }
}
