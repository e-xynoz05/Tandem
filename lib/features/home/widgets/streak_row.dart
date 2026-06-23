import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';

class StreakRow extends StatelessWidget {
  const StreakRow({super.key, required this.colors});
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = (DateTime.now().weekday - 1) % 7;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isToday = index == todayIndex;
        final isCompleted = index < todayIndex; // Mock logic for demo

        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? Colors.amber : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isToday ? Colors.white : Colors.white.withValues(alpha: 0.3),
                  width: isToday ? 3 : 1,
                ),
                boxShadow: isToday ? [
                  BoxShadow(color: Colors.white.withValues(alpha: 0.5), blurRadius: 10)
                ] : null,
              ),
              child: isToday 
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                  ) 
                : null,
            ),
            const SizedBox(height: 8),
            Text(
              days[index],
              style: TextStyle(
                color: isToday ? Colors.white : Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        );
      }),
    );
  }
}
