import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/user_repository.dart';
import '../../auth/providers/auth_provider.dart';

/// Watches the user's settings sub-document in Firestore.
final userSettingsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value({});
  return ref.watch(userRepositoryProvider).watchSettings(user.uid);
});
