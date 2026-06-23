import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';

/// Life graph widget — a visual representation of weekly/monthly progress.
///
/// This is a placeholder. Replace the custom bars with [fl_chart] widgets
/// for production-quality interactive charts.
class LifeGraph extends ConsumerWidget {
  const LifeGraph({
    super.key,
    this.data = const [0.3, 0.6, 0.45, 0.8, 0.5, 0.9, 0.2],
  });

  final List<double> data;

  static const _labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (i) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 20,
                height: 140 * data[i].clamp(0.0, 1.0),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(
                    alpha: 0.4 + (data[i] * 0.6),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _labels[i],
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        }),
      ),
    );
  }
}
