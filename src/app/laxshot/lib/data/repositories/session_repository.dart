import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session_model.dart';
import '../models/stats_model.dart';

class SessionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessions(String uid) =>
      _db.collection('users').doc(uid).collection('sessions');

  Future<SessionModel?> getSession(String uid, String sessionId) async {
    final doc = await _sessions(uid).doc(sessionId).get();
    if (!doc.exists) return null;
    return SessionModel.fromFirestore(doc);
  }

  Stream<List<SessionModel>> watchRecentSessions(String uid, {int limit = 10}) =>
      _sessions(uid)
          .orderBy('recordedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) =>
              snap.docs.map(SessionModel.fromFirestore).toList());

  Stream<SessionModel?> watchSession(String uid, String sessionId) =>
      _sessions(uid).doc(sessionId).snapshots().map(
            (doc) => doc.exists ? SessionModel.fromFirestore(doc) : null,
          );

  Future<String> createSession(String uid, SessionModel session) async {
    final ref = await _sessions(uid).add(session.toFirestore());
    return ref.id;
  }

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
}
