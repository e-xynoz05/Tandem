import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/goal_model.dart';
import '../../core/theme/color_tokens.dart';
import '../../core/theme/theme_provider.dart';
import 'goal_provider.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  late GoalCategory _selectedCategory;
  DateTime? _targetDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _parseCategory(widget.initialCategory) ?? GoalCategory.mindfulness;
  }

  GoalCategory? _parseCategory(String? cat) {
    if (cat == null) return null;
    return GoalCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == cat.toLowerCase(),
      orElse: () => GoalCategory.mindfulness,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for your goal')),
      );
      return;
    }

    final goalId = await ref.read(goalNotifierProvider.notifier).createGoal(
          title: title,
          description: _descController.text.trim(),
          category: _selectedCategory,
          targetDate: _targetDate,
        );

    if (mounted && goalId != null) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeModeProvider) == ThemeMode.dark
        ? ColorTokens.dark
        : ColorTokens.light;

    return Scaffold(
      appBar: AppBar(title: const Text('New Goal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Icon
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 80,
                  color: colors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Category Picker
            Text(
              'What\'s the focus?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: GoalCategory.values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final cat = GoalCategory.values[index];
                  final isSelected = _selectedCategory == cat;
                  return _CategoryCircle(
                    category: cat,
                    isSelected: isSelected,
                    onTap: () => setState(() => _selectedCategory = cat),
                    colors: colors,
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Inputs
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Goal Title',
                hintText: 'e.g. Run a 5k Marathon',
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Break it down...',
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Date Picker Tile
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colors.border),
              ),
              leading: Icon(Icons.calendar_today_rounded, color: colors.primary),
              title: const Text('Target Date'),
              subtitle: Text(_targetDate == null ? 'Optional' : _targetDate!.toString().split(' ')[0]),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _targetDate = date);
              },
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _onSave,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Set Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCircle extends StatelessWidget {
  const _CategoryCircle({
    required this.category,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final GoalCategory category;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorTokens colors;

  @override
  Widget build(BuildContext context) {
    Color catColor;
    IconData icon;

    switch (category) {
      case GoalCategory.fitness:
        catColor = const Color(0xFF1A1C1A); // Black
        icon = Icons.fitness_center_rounded;
        break;
      case GoalCategory.learning:
        catColor = const Color(0xFF1A1C1A); // Black
        icon = Icons.book_rounded;
        break;
      case GoalCategory.career:
        catColor = const Color(0xFFA43B2F); // Coral
        icon = Icons.work_rounded;
        break;
      case GoalCategory.relationships:
        catColor = const Color(0xFFFF7F6E); // Coral Light
        icon = Icons.favorite_rounded;
        break;
      case GoalCategory.mindfulness:
        catColor = const Color(0xFF1A1C1A); // Black
        icon = Icons.spa_rounded;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isSelected ? catColor : catColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: catColor.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : catColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name[0].toUpperCase() + category.name.substring(1),
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colors.text : colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
