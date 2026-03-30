import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';

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
