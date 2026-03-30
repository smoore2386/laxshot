import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/stats_model.dart';
import '../../../data/models/session_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../auth/providers/auth_provider.dart';

final userStatsProvider = FutureProvider<StatsModel?>((ref) async {
  final user = ref.watch(firebaseUserProvider).valueOrNull;
  if (user == null) return null;
  final repo = ref.watch(userRepositoryProvider);
  return repo.getStats(user.uid);
});

final recentSessionsProvider = FutureProvider<List<SessionModel>>((ref) async {
  final user = ref.watch(firebaseUserProvider).valueOrNull;
  if (user == null) return [];
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.getRecentSessions(user.uid, limit: 10);
});
