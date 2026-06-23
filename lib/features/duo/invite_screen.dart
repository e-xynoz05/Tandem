import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/auth_provider.dart';
import '../../core/models/avatar_config.dart';
import '../../core/widgets/avatar_widget.dart';

/// Invite Partner screen — matching the Stitch "Invite Duo Partner" design.
///
/// Search for partners, see suggested connections, or send a direct invite link.
class InviteScreen extends ConsumerStatefulWidget {
  const InviteScreen({super.key});

  @override
  ConsumerState<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends ConsumerState<InviteScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Invite Partner'),
        backgroundColor: colors.background,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ──────────────────────────────────────
            Text(
              'Invite your partner',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sync your lives, reduce the mental load, and grow together.',
              style: TextStyle(
                fontSize: 15,
                color: colors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // ─── Duo Preview ──────────────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Your Avatar
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: colors.primary.withValues(alpha: 0.3), width: 3),
                      ),
                      child: ref.watch(currentUserProvider)?.avatarConfig != null
                          ? AvatarWidget(
                              config: AvatarConfig.fromMap(
                                  ref.watch(currentUserProvider)!.avatarConfig),
                              size: 70,
                            )
                          : CircleAvatar(
                              radius: 35,
                              backgroundColor: colors.primary.withValues(alpha: 0.1),
                              child: Icon(Icons.person_rounded,
                                  color: colors.primary, size: 40),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Link icon
                    Icon(Icons.link_rounded,
                        color: colors.textMuted.withValues(alpha: 0.5), size: 28),
                    const SizedBox(width: 12),
                    // Partner Placeholder
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.3),
                          width: 3,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person_add_rounded,
                          color: colors.textMuted.withValues(alpha: 0.5),
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── Search Bar ──────────────────────────────────
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: Icon(Icons.search_rounded,
                    color: colors.textMuted),
                filled: true,
                fillColor: colors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: colors.primary, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ─── Suggested Connections ───────────────────────
            Text(
              'Suggested Connections',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 16),
            _ConnectionCard(
              name: 'Alex Rivera',
              handle: '@alexrivera',
              initial: 'A',
              avatarColor: colors.primary,
              colors: colors,
              onInvite: () => _sendInvite(context, 'Alex Rivera'),
            ),
            _ConnectionCard(
              name: 'Jordan Chen',
              handle: '@jordanchen',
              initial: 'J',
              avatarColor: colors.secondary,
              colors: colors,
              onInvite: () => _sendInvite(context, 'Jordan Chen'),
            ),
            _ConnectionCard(
              name: 'Sam Patel',
              handle: '@sampatel',
              initial: 'S',
              avatarColor: colors.tertiary,
              colors: colors,
              onInvite: () => _sendInvite(context, 'Sam Patel'),
            ),

            const SizedBox(height: 32),

            // ─── Direct Link Section ─────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: colors.outlineVariant.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.link_rounded,
                      color: colors.primary, size: 32),
                  const SizedBox(height: 12),
                  Text(
                    "Can't find them?",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: colors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Send a direct invite link.',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final user = ref.read(currentUserProvider);
                        final inviteCode = user?.uid.substring(0, 8) ?? 'TANDEM';
                        Clipboard.setData(
                            ClipboardData(text: 'tandem://invite/$inviteCode'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Invite link copied! 📋'),
                            backgroundColor: colors.secondary,
                          ),
                        );
                      },
                      icon: Icon(Icons.copy_rounded, color: colors.primary),
                      label: Text('Copy Invite Link',
                          style: TextStyle(color: colors.primary)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: colors.primary.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _sendInvite(BuildContext context, String name) {
    final colors = ref.read(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite sent to $name! 🎉'),
        backgroundColor: colors.secondary,
      ),
    );
  }
}

// ─── Connection Card ────────────────────────────────────────────────
class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard({
    required this.name,
    required this.handle,
    required this.initial,
    required this.avatarColor,
    required this.colors,
    required this.onInvite,
  });

  final String name;
  final String handle;
  final String initial;
  final Color avatarColor;
  final ColorTokens colors;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: avatarColor,
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: colors.text,
                  ),
                ),
                Text(
                  handle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onInvite,
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              textStyle:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }
}
