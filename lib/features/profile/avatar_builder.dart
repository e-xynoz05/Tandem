import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/avatar_config.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/avatar_widget.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../auth/auth_provider.dart';

class AvatarBuilder extends ConsumerStatefulWidget {
  const AvatarBuilder({super.key});

  @override
  ConsumerState<AvatarBuilder> createState() => _AvatarBuilderState();
}

class _AvatarBuilderState extends ConsumerState<AvatarBuilder> {
  late AvatarConfig _config;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user?.avatarConfig.isNotEmpty ?? false) {
      _config = AvatarConfig.fromMap(user!.avatarConfig);
    } else {
      _config = const AvatarConfig();
    }
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);
    
    await ref.read(authServiceProvider).updateProfile(
      user.copyWith(avatarConfig: _config.toMap()),
    );
    
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avatar saved! Looks great. ✨'),
          backgroundColor: Color(0xFFA43B2F),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Customize Avatar'),
        actions: [
          if (_isSaving)
            const Center(child: Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))))
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            // ─── Preview ─────────────────────────────────────────
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _config.outfitColor.withValues(alpha: 0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: AvatarWidget(config: _config, size: 160),
              ),
            ),
            const SizedBox(height: 48),

            // ─── Profile Color ───────────────────────────────────────
            _SectionHeader(title: 'Profile Color', colors: colors),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AvatarConfig.skinTones.map((tone) => _ChoiceChip(
                selected: _config.skinTone == tone,
                color: tone,
                onTap: () => setState(() => _config = _config.copyWith(skinTone: tone)),
              )).toList(),
            ),

            const SizedBox(height: 32),

            // ─── Accent Color ────────────────────────────────────
            _SectionHeader(title: 'Accent Color', colors: colors),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AvatarConfig.outfitColors.map((color) => _ChoiceChip(
                selected: _config.outfitColor == color,
                color: color,
                onTap: () => setState(() => _config = _config.copyWith(outfitColor: color)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.colors});
  final String title;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: colors.border)),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({required this.selected, required this.color, required this.onTap});
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected ? Border.all(color: Colors.white, width: 4) : Border.all(color: Colors.black.withValues(alpha: 0.05)),
          boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))] : null,
        ),
      ),
    );
  }
}

