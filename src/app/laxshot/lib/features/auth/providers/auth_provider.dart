import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../data/models/user_model.dart';
import '../../../data/services/analytics_service.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/repositories/user_repository.dart';

// ── AuthService singleton ───────────────────────────────────────────────────

final authServiceProvider = Provider<AuthService>((_) => AuthService());

// ── Firebase Auth state stream ──────────────────────────────────────────────

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

/// Alias used by stats_provider and camera_screen.
final firebaseUserProvider = authStateProvider;

// ── Current user model from Firestore ───────────────────────────────────────

final currentUserModelProvider = StreamProvider<UserModel?>((ref) {
  final firebaseUser = ref.watch(authStateProvider).valueOrNull;
  if (firebaseUser == null) return Stream.value(null);
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchUser(firebaseUser.uid);
});

// ── Auth notifier (signIn / signUp / signOut / social / COPPA) ──────────────

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthService get _auth => ref.read(authServiceProvider);
  UserRepository get _repo => ref.read(userRepositoryProvider);
  AnalyticsService get _analytics => ref.read(analyticsServiceProvider);

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithEmail(email, password);
      _analytics.logSignIn('email');
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
    required DateTime dateOfBirth,
    required PlayerPosition position,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final cred = await _auth.createWithEmail(email, password);
      final uid = cred.user!.uid;
      await _repo.createProfile(
        uid: uid,
        email: email,
        displayName: displayName,
        dateOfBirth: dateOfBirth,
        position: position,
      );
      _analytics.logSignUp('email');
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithGoogle();
      _analytics.logSignIn('google');
    });
  }

  Future<void> signInWithApple() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _auth.signInWithApple();
      _analytics.logSignIn('apple');
    });
  }

  Future<void> requestParentalConsent(String parentEmail) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repo.requestParentalConsent(parentEmail),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _auth.signOut());
  }
}
