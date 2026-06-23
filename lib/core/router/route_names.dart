// Route names for the Tandem app.

/// Centralised route-name constants.
///
/// Using a dedicated class prevents typos and enables IDE auto-complete
/// for every route in the app.
abstract final class RouteNames {
  // Auth
  static const splash = '/';
  static const login = '/login';
  static const signup = '/signup';
  static const onboarding = '/onboarding';

  // Main tabs (matches Stitch nav: Home / Routines / Growth / Workouts / Profile)
  static const home = '/home';
  static const routines = '/routines';
  static const growth = '/growth';
  static const workout = '/workout';
  static const profile = '/profile';

  // Nested — Home
  static const createGoal = 'create-goal';
  static const goalDetails = 'goal-details/:id';
  static const categoryDetail = 'category-detail/:category';

  // Nested — Routines
  static const invite = 'invite';

  // Nested — Profile
  static const settings = 'settings';

  // Nested — Workout
  static const activeSession = 'active-session';
  static const createWorkoutPlan = 'create-plan';
}
