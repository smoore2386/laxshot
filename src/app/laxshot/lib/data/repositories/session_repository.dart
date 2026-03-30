import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';
import '../models/stats_model.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((_) => SessionRepository());

class SessionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sessions(String uid) =>
      _db.collection('users').doc(uid).collection('sessions');

  Future<SessionModel?> getSession(String uid, String sessionId) async {
    final doc = await _sessions(uid).doc(sessionId).get();
    if (!doc.exists) return null;
    return SessionModel.fromFirestore(doc);
  }

  Future<List<SessionModel>> getRecentSessions(String uid, {int limit = 10}) async {
    final snap = await _sessions(uid)
        .orderBy('recordedAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(SessionModel.fromFirestore).toList();
  }

  Stream<List<SessionModel>> watchRecentSessions(String uid, {int limit = 10}) =>
      _sessions(uid)
          .orderBy('recordedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((snap) => snap.docs.map(SessionModel.fromFirestore).toList());

  Stream<SessionModel?> watchSession(String uid, String sessionId) =>
      _sessions(uid).doc(sessionId).snapshots().map(
            (doc) => doc.exists ? SessionModel.fromFirestore(doc) : null,
          );

  Future<String> createSession(String uid, SessionModel session) async {
    final ref = await _sessions(uid).add(session.toFirestore());
    return ref.id;
  }
}
