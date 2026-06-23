import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/routine_card.dart';
import '../../core/models/routine_model.dart';
import '../../core/services/routine_service.dart';
import '../auth/auth_provider.dart';
import '../duo/duo_provider.dart';
import 'routine_provider.dart';
import '../../core/models/avatar_config.dart';
import '../../core/widgets/avatar_widget.dart';

class RoutinesScreen extends ConsumerStatefulWidget {
  const RoutinesScreen({super.key});

  @override
  ConsumerState<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends ConsumerState<RoutinesScreen> {
  bool _isSolo = false;

  void _confirmDeleteRoutine(RoutineModel routine) {
    final colors = ref.read(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        title: Text('Delete Routine?', style: TextStyle(color: colors.text)),
        content: Text(
            'Are you sure you want to remove "${routine.title}" from your ${routine.duoId == null ? 'personal' : 'shared'} routines?',
            style: TextStyle(color: colors.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(routineServiceProvider).deleteRoutine(routine.id);
                if (ctx.mounted) Navigator.pop(ctx);
                HapticFeedback.lightImpact();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('Failed to delete: $e'), backgroundColor: Colors.red),
                  );
                  Navigator.pop(ctx);
                }
              }
            },
            child: Text('Delete', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    final routinesAsync = ref.watch(duoRoutinesProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Column(
        children: [
          _RoutineToggle(
            isSolo: _isSolo,
            onChanged: (val) => setState(() => _isSolo = val),
            colors: colors,
          ),
          Expanded(
            child: routinesAsync.when(
              data: (routines) {
                final filteredRoutines = routines.where((r) {
                  if (_isSolo) {
                    return r.duoId == null && r.userId == currentUser?.uid;
                  } else {
                    return r.duoId != null;
                  }
                }).toList();

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (!_isSolo) ...[
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Today's Rhythm",
                                  style: TextStyle(
                                      color: colors.text,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('Stay in sync with your shared routines.',
                                  style: TextStyle(
                                      color: colors.textMuted, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _DuoStatusHeader(
                          colors: colors,
                          ref: ref,
                        ),
                      ),
                    ],
                    if (filteredRoutines.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyRoutinesState(
                          isSolo: _isSolo,
                          colors: colors,
                          onAdd: () => _showAddRoutineSheet(),
                        ),
                      )
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final routine = filteredRoutines[index];
                                return RoutineCard(
                                  icon: routine.icon,
                                  title: routine.title,
                                  description: routine.description,
                                  time: routine.time,
                                  isCompleted: routine.isCompleted,
                                  partnerCompleted: !_isSolo && routine.partnerCompleted,
                                  onToggle: () {
                                    debugPrint('TOGGLE CLICKED for ${routine.title}. Current state: ${routine.isCompleted}');
                                    if (currentUser != null && routine.id.isNotEmpty) {
                                      ref.read(routineServiceProvider).toggleRoutine(
                                            routine.id,
                                            currentUser.uid,
                                            !routine.isCompleted,
                                          );
                                      if (!routine.isCompleted) HapticFeedback.mediumImpact();
                                    }
                                  },
                                  onDelete: () => _confirmDeleteRoutine(routine),
                                );
                            },
                            childCount: filteredRoutines.length,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddRoutineSheet(),
                            icon: Icon(Icons.add_rounded, color: colors.primary),
                            label: Text(
                                _isSolo ? 'Add Personal Routine' : 'Add Shared Routine',
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
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddRoutineSheet() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final timeController = TextEditingController();
    int selectedIcon = Icons.coffee_rounded.codePoint;

    final colors = ref.read(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding:
              EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 20),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text(_isSolo ? 'Create Personal Routine' : 'Create Shared Routine',
                  style:
                      const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              Text('Quick Templates', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.text)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _TemplateChip(
                      label: 'Coffee',
                      icon: Icons.coffee_rounded,
                      onTap: () => setModalState(() {
                        titleController.text = 'Morning Coffee';
                        descController.text = 'Start the day together';
                        selectedIcon = Icons.coffee_rounded.codePoint;
                      }),
                      colors: colors,
                    ),
                    _TemplateChip(
                      label: 'Gym',
                      icon: Icons.fitness_center_rounded,
                      onTap: () => setModalState(() {
                        titleController.text = 'Daily Workout';
                        descController.text = 'Push our limits';
                        selectedIcon = Icons.fitness_center_rounded.codePoint;
                      }),
                      colors: colors,
                    ),
                    _TemplateChip(
                      label: 'Reading',
                      icon: Icons.menu_book_rounded,
                      onTap: () => setModalState(() {
                        titleController.text = 'Shared Reading';
                        descController.text = '15 mins of growth';
                        selectedIcon = Icons.menu_book_rounded.codePoint;
                      }),
                      colors: colors,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                      labelText: 'Routine Title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextField(
                  controller: descController,
                  decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                      labelText: 'Time (Optional)',
                      prefixIcon: const Icon(Icons.access_time_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 16),
              Text('Select Icon', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colors.text)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _IconOption(icon: Icons.coffee_rounded, isSelected: selectedIcon == Icons.coffee_rounded.codePoint, onTap: () => setModalState(() => selectedIcon = Icons.coffee_rounded.codePoint), colors: colors),
                  _IconOption(icon: Icons.psychology_rounded, isSelected: selectedIcon == Icons.psychology_rounded.codePoint, onTap: () => setModalState(() => selectedIcon = Icons.psychology_rounded.codePoint), colors: colors),
                  _IconOption(icon: Icons.directions_walk_rounded, isSelected: selectedIcon == Icons.directions_walk_rounded.codePoint, onTap: () => setModalState(() => selectedIcon = Icons.directions_walk_rounded.codePoint), colors: colors),
                  _IconOption(icon: Icons.menu_book_rounded, isSelected: selectedIcon == Icons.menu_book_rounded.codePoint, onTap: () => setModalState(() => selectedIcon = Icons.menu_book_rounded.codePoint), colors: colors),
                  _IconOption(icon: Icons.self_improvement_rounded, isSelected: selectedIcon == Icons.self_improvement_rounded.codePoint, onTap: () => setModalState(() => selectedIcon = Icons.self_improvement_rounded.codePoint), colors: colors),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final currentUser = ref.read(currentUserProvider);
                    if (titleController.text.isEmpty) return;

                    try {
                      await ref.read(routineServiceProvider).createRoutine(
                            RoutineModel(
                              id: '',
                              title: titleController.text,
                              description: descController.text,
                              time: timeController.text,
                              iconCode: selectedIcon,
                              duoId: _isSolo ? null : currentUser?.duoPartnerId,
                              userId: currentUser?.uid ?? '',
                            ),
                          );
                      
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        HapticFeedback.mediumImpact();
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Failed to create: $e'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: colors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Create Routine', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoutineToggle extends StatelessWidget {
  const _RoutineToggle(
      {required this.isSolo, required this.onChanged, required this.colors});
  final bool isSolo;
  final ValueChanged<bool> onChanged;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 60, 24, 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
          color: colors.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(
              child: _ToggleItem(
                  label: 'Solo',
                  isSelected: isSolo,
                  onTap: () => onChanged(true),
                  colors: colors)),
          Expanded(
              child: _ToggleItem(
                  label: 'Duo',
                  isSelected: !isSolo,
                  onTap: () => onChanged(false),
                  colors: colors)),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem(
      {required this.label,
      required this.isSelected,
      required this.onTap,
      required this.colors});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? colors.primary : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyRoutinesState extends StatelessWidget {
  const _EmptyRoutinesState(
      {required this.isSolo, required this.colors, required this.onAdd});
  final bool isSolo;
  final ColorTokens colors;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSolo ? Icons.person_outline_rounded : Icons.people_outline_rounded,
              size: 64, color: colors.outlineVariant),
          const SizedBox(height: 16),
          Text(isSolo ? 'No personal routines yet' : 'No shared routines yet',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w600, color: colors.text)),
          const SizedBox(height: 8),
          Text(
              isSolo
                  ? 'Add a personal habit that belongs to you.'
                  : 'Start a routine to sync with your partner.',
              style: TextStyle(color: colors.textMuted)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text(isSolo ? 'Add Solo Routine' : 'Add Shared Routine'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  const _TemplateChip({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: colors.secondary),
        label: Text(label),
        onPressed: onTap,
        backgroundColor: colors.secondary.withValues(alpha: 0.1),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? colors.secondary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.secondary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? colors.secondary : colors.textMuted,
        ),
      ),
    );
  }
}

class _DuoStatusHeader extends StatelessWidget {
  const _DuoStatusHeader({required this.colors, required this.ref});
  final ColorTokens colors;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final partnerAsync = ref.watch(partnerUserProvider);
    final user = ref.watch(currentUserProvider);

    return partnerAsync.when(
      data: (partner) {
        if (partner == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.people_outline_rounded,
                          color: colors.primary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Power Up with a Partner',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Invite your partner to sync routines and grow your energy ring together.',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/routines/invite'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Invite Partner',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Paired state
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                // Your Avatar
                if (user != null)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.primary, width: 2),
                    ),
                    child: AvatarWidget(
                      config: AvatarConfig.fromMap(user.avatarConfig),
                      size: 48,
                    ),
                  ),
                const SizedBox(width: 8),
                // Connection Line
                Expanded(
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Partner Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.secondary, width: 2),
                  ),
                  child: AvatarWidget(
                    config: AvatarConfig.fromMap(partner.avatarConfig),
                    size: 48,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Synced',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      'Shared Harmony',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
