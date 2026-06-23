import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/user_model.dart';
import '../../core/models/duo_model.dart';
import '../../core/models/task_model.dart';
import '../../core/models/goal_model.dart';
import '../../core/services/duo_service.dart';
import '../auth/auth_provider.dart';

enum PrivacyMode { public, duo, private }

final privacyModeProvider = StateProvider<PrivacyMode>((ref) => PrivacyMode.private);

/// State for the Duo feature.
class DuoState {
  const DuoState({
    this.isLoading = false,
    this.isNudging = false,
    this.error,
  });

  final bool isLoading;
  final bool isNudging;
  final String? error;

  DuoState copyWith({
    bool? isLoading,
    bool? isNudging,
    String? error,
  }) {
    return DuoState(
      isLoading: isLoading ?? this.isLoading,
      isNudging: isNudging ?? this.isNudging,
      error: error,
    );
  }
}

/// Provides a real-time stream of the partner's user document.
final partnerUserProvider = StreamProvider<UserModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final partnerId = currentUser?.duoPartnerId;
  
  if (partnerId == null || partnerId.isEmpty) {
    return Stream.value(null);
  }

  final duoService = ref.watch(duoServiceProvider);
  return duoService.watchPartner(partnerId);
});

/// Provides a real-time stream of the shared Duo document.
final duoDocumentProvider = StreamProvider<DuoModel?>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final partner = ref.watch(partnerUserProvider).value;
  
  if (currentUser == null || partner == null) {
    return Stream.value(null);
  }

  return ref.watch(duoServiceProvider).watchDuo(currentUser.uid, partner.uid);
});

/// Streams partner's tasks (privacy-safe).
final partnerTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final partner = ref.watch(partnerUserProvider).value;
  if (partner == null) return Stream.value([]);
  
  return ref.watch(duoServiceProvider).watchPartnerTasks(partner.uid);
});

/// Aggregates partner's category progress percentages (0-100).
final partnerCategoryProgressProvider = StreamProvider<Map<GoalCategory, double>>((ref) {
  final partner = ref.watch(partnerUserProvider).value;
  if (partner == null) return Stream.value({});

  return ref.watch(duoServiceProvider).watchPartnerGoals(partner.uid).map((goals) {
    final Map<GoalCategory, List<GoalModel>> grouped = {};
    for (final cat in GoalCategory.values) {
      grouped[cat] = goals.where((g) => g.category == cat).toList();
    }

    return grouped.map((cat, catGoals) {
      if (catGoals.isEmpty) return MapEntry(cat, 0.0);
      final totalProgress = catGoals.fold<double>(0, (sum, g) => sum + (g.progress * 100));
      return MapEntry(cat, totalProgress / catGoals.length);
    });
  });
});

/// Logic for pairing/unpairing and duo actions.
class DuoNotifier extends StateNotifier<DuoState> {
  DuoNotifier(this._duoService, this._ref) : super(const DuoState());

  final DuoService _duoService;
  final Ref _ref;

  /// Pairs the current user with another user via an invite code.
  Future<void> pairWithInviteCode(String code) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      state = state.copyWith(error: 'You must be logged in to pair.');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final partnerUid = await _duoService.findUidByInviteCode(code);
      
      if (partnerUid == null) {
        state = state.copyWith(isLoading: false, error: 'Invalid invite code.');
        return;
      }

      if (partnerUid == currentUser.uid) {
        state = state.copyWith(isLoading: false, error: 'You cannot pair with yourself!');
        return;
      }

      await _duoService.linkPartners(currentUser.uid, partnerUid);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sends a nudge notification to the partner.
  Future<void> sendNudge() async {
    final user = _ref.read(currentUserProvider);
    final partner = _ref.read(partnerUserProvider).value;
    if (user == null || partner == null) return;

    state = state.copyWith(isNudging: true);
    try {
      await _duoService.sendNudge(user.displayName ?? '', partner.uid);
    } finally {
      state = state.copyWith(isNudging: false);
    }
  }

  /// Removes the current duo partnership.
  Future<void> unpair() async {
    final currentUser = _ref.read(currentUserProvider);
    final partner = _ref.read(partnerUserProvider).value;

    if (currentUser == null || partner == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _duoService.unlinkPartners(currentUser.uid, partner.uid);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Global provider for [DuoNotifier].
final duoProvider = StateNotifierProvider<DuoNotifier, DuoState>((ref) {
  final duoService = ref.watch(duoServiceProvider);
  return DuoNotifier(duoService, ref);
});
