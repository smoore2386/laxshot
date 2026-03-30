import 'package:cloud_firestore/cloud_firestore.dart';
import 'session_model.dart';

class StatsModel {
  final String userId;
  final int totalSessions;
  final int totalShots;
  final int totalSuccessful;
  final ZoneAccuracy lifetimeZoneAccuracy;
  final double bestAccuracy;
  final int currentStreak;   // days
  final int longestStreak;
  final List<String> unlockedAchievements;
  final DateTime lastUpdated;

  const StatsModel({
    required this.userId,
    required this.totalSessions,
    required this.totalShots,
    required this.totalSuccessful,
    required this.lifetimeZoneAccuracy,
    required this.bestAccuracy,
    required this.currentStreak,
    required this.longestStreak,
    required this.unlockedAchievements,
    required this.lastUpdated,
  });

  double get overallAccuracy =>
      totalShots == 0 ? 0.0 : totalSuccessful / totalShots;

  factory StatsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StatsModel(
      userId: doc.id,
      totalSessions: data['totalSessions'] as int? ?? 0,
      totalShots: data['totalShots'] as int? ?? 0,
      totalSuccessful: data['totalSuccessful'] as int? ?? 0,
      lifetimeZoneAccuracy: ZoneAccuracy.fromJson(
          (data['lifetimeZoneAccuracy'] as List<dynamic>?) ?? List.filled(9, 0.0)),
      bestAccuracy: (data['bestAccuracy'] as num?)?.toDouble() ?? 0.0,
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      unlockedAchievements:
          List<String>.from(data['unlockedAchievements'] as List? ?? []),
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'totalSessions': totalSessions,
        'totalShots': totalShots,
        'totalSuccessful': totalSuccessful,
        'lifetimeZoneAccuracy': lifetimeZoneAccuracy.toJson(),
        'bestAccuracy': bestAccuracy,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'unlockedAchievements': unlockedAchievements,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String iconEmoji;
  final bool unlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconEmoji,
    required this.unlocked,
  });

  static List<Achievement> all(List<String> unlocked) => [
        Achievement(
          id: 'first_shot',
          title: 'First Shot',
          description: 'Record your first session',
          iconEmoji: '🥍',
          unlocked: unlocked.contains('first_shot'),
        ),
        Achievement(
          id: 'sharpshooter',
          title: 'Sharpshooter',
          description: 'Achieve 80% accuracy in a session',
          iconEmoji: '🎯',
          unlocked: unlocked.contains('sharpshooter'),
        ),
        Achievement(
          id: 'streak_7',
          title: 'Week Warrior',
          description: 'Practice 7 days in a row',
          iconEmoji: '🔥',
          unlocked: unlocked.contains('streak_7'),
        ),
        Achievement(
          id: 'century',
          title: 'Century Club',
          description: 'Take 100 total shots',
          iconEmoji: '💯',
          unlocked: unlocked.contains('century'),
        ),
        Achievement(
          id: 'all_zones',
          title: 'Zone Master',
          description: 'Score in all 9 goal zones',
          iconEmoji: '⭐',
          unlocked: unlocked.contains('all_zones'),
        ),
        Achievement(
          id: 'consistent',
          title: 'Mr. Consistent',
          description: 'Complete 10 sessions',
          iconEmoji: '🏆',
          unlocked: unlocked.contains('consistent'),
        ),
      ];
}
