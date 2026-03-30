import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionMode { player, goalie }

class ZoneAccuracy {
  /// 3x3 grid: index 0=top-left, 1=top-center, 2=top-right,
  ///            3=mid-left,  4=mid-center,  5=mid-right,
  ///            6=bot-left,  7=bot-center,  8=bot-right
  final List<double> accuracyByZone; // 0.0–1.0 per zone

  const ZoneAccuracy({required this.accuracyByZone})
      : assert(accuracyByZone.length == 9);

  factory ZoneAccuracy.empty() =>
      ZoneAccuracy(accuracyByZone: List.filled(9, 0.0));

  factory ZoneAccuracy.fromJson(List<dynamic> json) =>
      ZoneAccuracy(accuracyByZone: json.map((e) => (e as num).toDouble()).toList());

  List<double> toJson() => accuracyByZone;

  double get overall =>
      accuracyByZone.fold(0.0, (sum, v) => sum + v) / accuracyByZone.length;
}

class SessionModel {
  final String sessionId;
  final String userId;
  final SessionMode mode;
  final DateTime recordedAt;
  final Duration duration;
  final int totalShots;
  final int successfulShots;
  final ZoneAccuracy zoneAccuracy;
  final String? videoUrl;
  final String? thumbnailUrl;
  final bool analysisComplete;

  const SessionModel({
    required this.sessionId,
    required this.userId,
    required this.mode,
    required this.recordedAt,
    required this.duration,
    required this.totalShots,
    required this.successfulShots,
    required this.zoneAccuracy,
    this.videoUrl,
    this.thumbnailUrl,
    required this.analysisComplete,
  });

  double get accuracy =>
      totalShots == 0 ? 0.0 : successfulShots / totalShots;

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SessionModel(
      sessionId: doc.id,
      userId: data['userId'] as String,
      mode: SessionMode.values.firstWhere(
        (m) => m.name == data['mode'],
        orElse: () => SessionMode.player,
      ),
      recordedAt: (data['recordedAt'] as Timestamp).toDate(),
      duration: Duration(seconds: data['durationSeconds'] as int? ?? 0),
      totalShots: data['totalShots'] as int? ?? 0,
      successfulShots: data['successfulShots'] as int? ?? 0,
      zoneAccuracy: ZoneAccuracy.fromJson(
          (data['zoneAccuracy'] as List<dynamic>?) ?? List.filled(9, 0.0)),
      videoUrl: data['videoUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      analysisComplete: data['analysisComplete'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'mode': mode.name,
        'recordedAt': Timestamp.fromDate(recordedAt),
        'durationSeconds': duration.inSeconds,
        'totalShots': totalShots,
        'successfulShots': successfulShots,
        'zoneAccuracy': zoneAccuracy.toJson(),
        if (videoUrl != null) 'videoUrl': videoUrl,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        'analysisComplete': analysisComplete,
      };
}
