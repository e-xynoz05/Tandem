import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A local cache of completion overrides for the current session.
/// Key: routineId
/// Value: true (force done), false (force undone)
final localOverridesProvider = StateProvider<Map<String, bool>>((ref) => {});

/// A provider that returns the local override for a specific routine if it exists.
final routineOverrideProvider = Provider.family<bool?, String>((ref, routineId) {
  final overrides = ref.watch(localOverridesProvider);
  return overrides[routineId];
});
