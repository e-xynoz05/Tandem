import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tandem/features/home/home_screen.dart';
import 'package:tandem/core/services/goal_service.dart';
import 'package:tandem/core/services/notification_service.dart';
import 'package:tandem/features/auth/auth_provider.dart';
import 'package:tandem/core/models/user_model.dart';
import 'package:tandem/core/models/task_model.dart';
import 'package:tandem/core/models/goal_model.dart';

class ManualMockGoalService implements GoalService {
  int addTaskCalled = 0;
  TaskModel? lastAddedTask;

  @override
  Future<void> addTask(TaskModel task) async {
    addTaskCalled++;
    lastAddedTask = task;
  }

  @override
  Stream<List<TaskModel>> watchTodayTasks(String userId) => Stream.value([]);
  @override
  Stream<List<TaskModel>> watchTasks(String userId, String goalId) =>
      Stream.value([]);
  @override
  Stream<List<GoalModel>> watchGoals(String userId) => Stream.value([]);
  @override
  Future<void> toggleTask(String userId, String taskId, bool isCompleted,
      {String? goalId}) async {}
  @override
  Future<void> deleteTask(String userId, String taskId,
      {String? goalId}) async {}
  @override
  Future<void> createGoal(GoalModel goal) async {}
  @override
  Future<void> updateGoal(GoalModel goal) async {}
  @override
  Future<void> deleteGoal(String userId, String goalId) async {}
}

class ManualMockNotificationService implements NotificationService {
  @override
  Future<void> initialise() async {}
  @override
  Future<void> scheduleDailyCheckIn() async {}
  @override
  Future<void> scheduleStreakRiskAlert() async {}
  @override
  Future<void> scheduleTaskReminder(TaskModel task) async {}
  @override
  Future<void> cancelTaskReminder(String id) async {}
  @override
  Future<void> requestPermissions() async {}
  @override
  Future<void> showLocalNotification(
      {required String title, required String body, String? payload}) async {}
}

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Home Flow Integration Tests', () {
    late ManualMockGoalService mockGoalService;
    late ManualMockNotificationService mockNotificationService;

    final testUser = UserModel(
      uid: 'test-uid',
      displayName: 'Test User',
      email: 'test@example.com',
      duoInviteCode: 'TEST12',
      streakCount: 5,
      totalXP: 100,
    );

    setUp(() {
      mockGoalService = ManualMockGoalService();
      mockNotificationService = ManualMockNotificationService();
    });

    testWidgets('can open add task sheet and submit a task',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWithValue(testUser),
            goalServiceProvider.overrideWithValue(mockGoalService),
            notificationServiceProvider
                .overrideWithValue(mockNotificationService),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find "Add Task" button
      final addButton = find.text('Add Task');
      expect(addButton, findsOneWidget);

      await tester.tap(addButton);
      await tester.pumpAndSettle();

      expect(find.text('Quick Add Task'), findsOneWidget);

      await tester.enterText(
          find.byType(TextField), 'Finish integration tests');
      await tester.pump();

      await tester.tap(find.text('fitness'));
      await tester.pump();

      await tester.tap(find.text('Create Task'));
      await tester.pumpAndSettle();

      expect(mockGoalService.addTaskCalled, 1);
      expect(mockGoalService.lastAddedTask?.title, 'Finish integration tests');
      expect(find.text('Quick Add Task'), findsNothing);
    });
  });
}
