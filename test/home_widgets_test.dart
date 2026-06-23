import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tandem/features/home/task_card.dart';
import 'package:tandem/features/home/widgets/streak_row.dart';
import 'package:tandem/core/models/task_model.dart';
import 'package:tandem/core/theme/color_tokens.dart';

void main() {
  group('TaskCard Widget Tests', () {
    final mockTask = TaskModel(
      id: 'test-1',
      userId: 'user-1',
      title: 'Test Task',
      category: 'fitness',
      isCompleted: false,
    );

    testWidgets('renders task title and category', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: mockTask,
            onToggle: () {},
            onDelete: () {},
            onReschedule: () {},
          ),
        ),
      ));

      expect(find.text('Test Task'), findsOneWidget);
      expect(find.text('FITNESS'), findsOneWidget);
    });

    testWidgets('shows checkmark when task is completed', (WidgetTester tester) async {
      final completedTask = mockTask.copyWith(isCompleted: true);
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: completedTask,
            onToggle: () {},
            onDelete: () {},
            onReschedule: () {},
          ),
        ),
      ));

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('triggers onToggle when tapped', (WidgetTester tester) async {
      bool toggled = false;
      
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TaskCard(
            task: mockTask,
            onToggle: () => toggled = true,
            onDelete: () {},
            onReschedule: () {},
          ),
        ),
      ));

      // Find the checkbox by key
      await tester.tap(find.byKey(const Key('task-checkbox')));
      await tester.pump();
      expect(toggled, isTrue);
    });
  });

  group('StreakRow Widget Tests', () {
    testWidgets('renders all 7 days of the week', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StreakRow(colors: ColorTokens.light),
        ),
      ));

      expect(find.text('M'), findsOneWidget);
      expect(find.text('T'), findsNWidgets(2)); // Tuesday and Thursday
      expect(find.text('W'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      expect(find.text('S'), findsNWidgets(2)); // Saturday and Sunday
    });

    testWidgets('indicates today with a center dot', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StreakRow(colors: ColorTokens.light),
        ),
      ));

      // The center dot is a Container with width 8
      final todayContainer = find.descendant(
        of: find.byType(Container),
        matching: find.byWidgetPredicate((widget) => 
          widget is Container && 
          widget.constraints?.maxWidth == 8 && 
          widget.decoration is BoxDecoration && 
          (widget.decoration as BoxDecoration).color == Colors.white
        ),
      );
      
      expect(todayContainer, findsOneWidget);
    });
  });
}
