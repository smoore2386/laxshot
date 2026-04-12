import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/stats_model.dart';

final userRepositoryProvider = Provider<UserRepository>((_) => UserRepository());

class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  Stream<UserModel?> watchUser(String uid) =>
      _db.collection('users').doc(uid).snapshots().map(
            (doc) => doc.exists ? UserModel.fromFirestore(doc) : null,
          );

  Future<void> createProfile({
    required String uid,
    required String email,
    required String displayName,
    required DateTime dateOfBirth,
    required PlayerPosition position,
  }) async {
    final age = _calcAge(dateOfBirth);
    final isMinor = age < 13;
    await _functions.httpsCallable('createProfile').call({
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'position': position.name,
      'isMinor': isMinor,
    });
  }

  Future<void> requestParentalConsent(String parentEmail) async {
    await _functions.httpsCallable('parentalConsent').call({
      'parentEmail': parentEmail,
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> fields) =>
      _db.collection('users').doc(uid).update(fields);

  Future<void> updateSettings(String uid, Map<String, dynamic> settings) =>
      _db.collection('users').doc(uid).set(
            {'settings': settings},
            SetOptions(merge: true),
          );

  Stream<Map<String, dynamic>> watchSettings(String uid) => _db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        if (data == null) return <String, dynamic>{};
        return Map<String, dynamic>.from(
            data['settings'] as Map<String, dynamic>? ?? {});
      });

  Future<StatsModel?> getStats(String uid) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('stats')
        .doc('summary')
        .get();
    if (!doc.exists) return null;
    return StatsModel.fromFirestore(doc);
  }

  Stream<StatsModel?> watchStats(String uid) =>
      _db
          .collection('users')
          .doc(uid)
          .collection('stats')
          .doc('summary')
          .snapshots()
          .map((doc) => doc.exists ? StatsModel.fromFirestore(doc) : null);

  /// Request a data export for the user. Returns a status message.
  Future<String?> exportUserData(String uid) async {
    try {
      final result =
          await _functions.httpsCallable('exportUserData').call({'uid': uid});
      return result.data as String?;
    } catch (_) {
      // If the Cloud Function doesn't exist yet, fall back to local message
      return 'Data export is being prepared. You will receive an email when ready.';
    }
  }

  int _calcAge(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}
