import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_web_plugins/url_strategy.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/services/notification_service.dart';

/// Error captured on startup from the URL on web.
String? startupAuthError;

/// Application entry point.
///
/// Initialises Supabase, locks orientation to portrait, and wraps the
/// widget tree in [ProviderScope] for Riverpod state management.
Future<void> main() async {
  // Use clean paths in URLs (removes '#' fragment if possible)
  usePathUrlStrategy();
  
  // NUCLEAR FIX for GoRouter crash on Supabase redirect errors
  if (kIsWeb) {
    final uri = Uri.base;
    if (uri.queryParameters.containsKey('error') || 
        uri.queryParameters.containsKey('error_description') ||
        uri.fragment.contains('error_description')) {
      // Capture error before cleaning
      final errorStr = uri.queryParameters['error_description'] ?? 
                       uri.queryParameters['error'] ??
                       uri.fragment.split('&').firstWhere((e) => e.startsWith('error_description='), orElse: () => '').split('=').last;
      
      if (errorStr.isNotEmpty) {
        startupAuthError = Uri.decodeComponent(errorStr).replaceAll('+', ' ');
      }

      // Clean the URL in the browser's history before Flutter routing starts
      html.window.history.replaceState(null, '', '/');
    }
  }

  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation on mobile
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Supabase initialisation
  await Supabase.initialize(
    url: 'https://clwnuxzekoozwbmdbgng.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNsd251eHpla29vendibWRiZ25nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4NjgwMjUsImV4cCI6MjA5MjQ0NDAyNX0.eElRkORElg6htYvveHoWwNiS5ma7yP4pp_8aBYmdgTk',
  );

  // Initialize Notifications
  final container = ProviderContainer();
  try {
    final notificationService = container.read(notificationServiceProvider);
    await notificationService.initialise();
    
    // Schedule recurring local notifications
    if (!kIsWeb) {
      await notificationService.scheduleDailyCheckIn();
      await notificationService.scheduleStreakRiskAlert();
    }
  } catch (e) {
    debugPrint('Notification initialization failed: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: TandemApp(),
    ),
  );
}
