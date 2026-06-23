/// App-wide constants.
abstract final class AppConstants {
  /// App identity
  static const appName = 'Tandem';
  static const appTagline = 'Grow together. Daily.';

  /// Animation durations
  static const Duration quickAnimation = Duration(milliseconds: 200);
  static const Duration standardAnimation = Duration(milliseconds: 400);
  static const Duration slowAnimation = Duration(milliseconds: 600);

  /// Layout
  static const double pagePadding = 24.0;
  static const double cardRadius = 16.0;
  static const double buttonRadius = 12.0;
  static const double chipRadius = 8.0;

  /// Firestore collection names
  static const usersCollection = 'users';
  static const goalsCollection = 'goals';
  static const tasksCollection = 'tasks';
  static const workoutsCollection = 'workouts';
  static const duosCollection = 'duos';
}
