import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/circular_timer_painter.dart';
import 'workout_provider.dart';

class ActiveSessionScreen extends ConsumerWidget {
  const ActiveSessionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(activeSessionProvider);
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    if (sessionState.session == null) {
      return const Scaffold(body: Center(child: Text('No active session')));
    }

    final currentExercise = sessionState.session!.exerciseLogs[sessionState.currentExerciseIndex];
    final progress = (sessionState.currentExerciseIndex + 1) / sessionState.session!.exerciseLogs.length;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text('Session: ${sessionState.session!.planId}'), // Ideally look up plan name
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(activeSessionProvider.notifier).finishSession();
              if (context.mounted) context.pop();
            },
            child: const Text('Finish', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Progress Bar ──────────────────────────────────────
          LinearProgressIndicator(
            value: progress,
            backgroundColor: colors.border,
            color: colors.primary,
            minHeight: 6,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    currentExercise.exerciseName,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Exercise ${sessionState.currentExerciseIndex + 1} of ${sessionState.session!.exerciseLogs.length}',
                    style: TextStyle(color: colors.textMuted),
                  ),
                  const SizedBox(height: 32),

                  // ─── Sets Log ──────────────────────────────────────────
                  ...currentExercise.sets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final set = entry.value;
                    return _SetLogRow(index: index, set: set, colors: colors);
                  }),

                  const SizedBox(height: 24),

                  // ─── Quick Log Form ────────────────────────────────────
                  _LogSetForm(
                    onLog: (reps, weight) {
                      ref.read(activeSessionProvider.notifier).logSet(
                            sessionState.currentExerciseIndex,
                            reps,
                            weight,
                          );
                    },
                    colors: colors,
                  ),

                  const SizedBox(height: 48),

                  // ─── Rest Timer ────────────────────────────────────────
                  const _RestTimerSection(),
                ],
              ),
            ),
          ),

          // ─── Footer Action ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton(
              onPressed: () => ref.read(activeSessionProvider.notifier).nextExercise(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: colors.surface,
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Next Exercise', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetLogRow extends StatelessWidget {
  const _SetLogRow({required this.index, required this.set, required this.colors});
  final int index;
  final dynamic set;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: colors.primary.withValues(alpha: 0.1),
            child: Text('${index + 1}', style: TextStyle(fontSize: 12, color: colors.primary)),
          ),
          const SizedBox(width: 16),
          Text('${set.reps} reps', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Text('${set.weight} kg', style: TextStyle(color: colors.textMuted)),
          const SizedBox(width: 8),
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
        ],
      ),
    );
  }
}

class _LogSetForm extends StatefulWidget {
  const _LogSetForm({required this.onLog, required this.colors});
  final Function(int, double) onLog;
  final ColorTokens colors;

  @override
  State<_LogSetForm> createState() => _LogSetFormState();
}

class _LogSetFormState extends State<_LogSetForm> {
  final _repsController = TextEditingController(text: '10');
  final _weightController = TextEditingController(text: '20');

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _repsController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Reps',
              filled: true,
              fillColor: widget.colors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: _weightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Weight (kg)',
              filled: true,
              fillColor: widget.colors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: () {
            final reps = int.tryParse(_repsController.text) ?? 0;
            final weight = double.tryParse(_weightController.text) ?? 0.0;
            widget.onLog(reps, weight);
          },
          icon: const Icon(Icons.add_rounded),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFFA43B2F),
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}

class _RestTimerSection extends ConsumerWidget {
  const _RestTimerSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerProgress = ref.watch(restTimerProvider);
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    if (timerProgress <= 0) return const SizedBox.shrink();

    return Column(
      children: [
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CustomPaint(
                  painter: CircularTimerPainter(
                    progress: timerProgress,
                    color: const Color(0xFFA43B2F),
                    backgroundColor: colors.border.withValues(alpha: 0.5),
                    strokeWidth: 8,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('REST', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Text(
                    '${(timerProgress * 90).toInt()}s',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => ref.read(restTimerProvider.notifier).skip(),
          child: const Text('Skip Rest', style: TextStyle(color: Colors.amber)),
        ),
      ],
    );
  }
}
