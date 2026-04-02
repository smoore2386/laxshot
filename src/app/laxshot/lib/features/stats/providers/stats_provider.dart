import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/stats_model.dart';
import '../../../data/models/session_model.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/session_repository.dart';
import '../../auth/providers/auth_provider.dart';

final userStatsProvider = StreamProvider<StatsModel?>((ref) {
  final user = ref.watch(firebaseUserProvider).valueOrNull;
  if (user == null) return Stream.value(null);
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchStats(user.uid);
});

final recentSessionsProvider = StreamProvider<List<SessionModel>>((ref) {
  final user = ref.watch(firebaseUserProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  final repo = ref.watch(sessionRepositoryProvider);
  return repo.watchRecentSessions(user.uid, limit: 10);
});
