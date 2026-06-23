import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../router/app_router.dart';
import '../router/route_names.dart';
import '../models/task_model.dart';

/// Notification service handling local notifications.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String channelId = 'tandem_main';
  static const String channelName = 'Tandem Notifications';
  static const String channelDescription = 'Daily check-ins, reminders, and duo updates';

  final List<String> _morningMessages = [
    "Today is a new chance to grow. What's first?",
    "Tandem is awake and ready to crush some goals!",
    "Good morning! Ready to keep that streak alive?",
    "Rise and shine. Your partner is already working!",
    "New day, new focus. Let's make it count.",
    "A fresh morning for a fresh start. Tandem time!",
    "Ready to make progress today? 🚀",
    "Success is built daily. Let's build together.",
    "Morning! What's one thing we can finish today?",
    "Wake up! Life is better when we're growing.",
  ];

  /// Initialises notification channels and requests permissions.
  Future<void> initialise() async {
    // 1. Initialize timezones
    tz.initializeTimeZones();

    // 2. Configure Android channel
    const androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      ledColor: Color(0xFFA43B2F),
      enableLights: true,
      playSound: true,
    );

    if (!kIsWeb) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }

    // 3. Initialize local notifications
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false, // Requested manually after onboarding
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );
  }

  /// Manually request iOS permissions (called after onboarding).
  Future<void> requestPermissions() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Schedules the daily 8:00 AM check-in.
  Future<void> scheduleDailyCheckIn() async {
    final random = Random();
    final message = _morningMessages[random.nextInt(_morningMessages.length)];

    await _localNotifications.zonedSchedule(
      100, // ID
      "Good morning! Time for Tandem 🚀",
      message,
      _nextInstanceOfTime(8, 0),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedules the 7:00 PM streak risk alert.
  Future<void> scheduleStreakRiskAlert() async {
    await _localNotifications.zonedSchedule(
      101, // ID
      "Don't break your streak!",
      "You haven't completed any tasks today. Let's make it happen!",
      _nextInstanceOfTime(19, 0),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }


  /// Cancels a task reminder.
  Future<void> cancelTaskReminder(String taskId) async {
    await _localNotifications.cancel(taskId.hashCode);
  }

  void _handleNotificationTap(NotificationResponse response) {
    _navigateToScreen(response.payload);
  }

  void _navigateToScreen(String? payload) {
    if (payload == null) return;

    if (payload.startsWith('task:')) {
      appRouter.go(RouteNames.home);
      // In a real app, we'd use a deep link or pass data to home to auto-scroll
      return;
    }

    switch (payload) {
      case 'duo':
      case 'routines':
        appRouter.go(RouteNames.routines);
        break;
      case 'stats':
      case 'growth':
        appRouter.go(RouteNames.growth);
        break;
      default:
        appRouter.go(RouteNames.home);
    }
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotifications.show(
      Random().nextInt(100000),
      title,
      body,
      _notificationDetails(),
      payload: payload,
    );
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFFA43B2F),
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  /// Schedules a reminder for a specific task.
  Future<void> scheduleTaskReminder(TaskModel task) async {
    if (task.reminderTime == null) return;

    final scheduledDate = tz.TZDateTime.from(task.reminderTime!, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _localNotifications.zonedSchedule(
      task.id.hashCode,
      "Tandem Reminder: ${task.title}",
      "Time to make progress together! 🚀",
      scheduledDate,
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'task:${task.id}',
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

/// Global provider for [NotificationService].
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());
