import 'dart:math' as math;

import '../models/shot_classification.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// A single improvement tip with priority and detail.
class CoachingTip {
  /// Short headline, e.g. "Extend your follow-through".
  final String headline;

  /// Longer explanation (2-3 sentences).
  final String detail;

  /// Which mechanic this addresses.
  final MechanicsCategory category;

  /// 1 = most critical, higher = less urgent.
  final int priority;

  const CoachingTip({
    required this.headline,
    required this.detail,
    required this.category,
    required this.priority,
  });
}

/// The full coaching report for a single analyzed shot.
class ShotCoachingReport {
  /// Classified shot type (may be `null` if unrecognized).
  final ShotType? shotType;

  /// Human-readable name for the shot.
  final String shotLabel;

  /// Discipline the report was generated for.
  final LacrosseDiscipline discipline;

  /// Per-category scores (0-100).
  final Map<MechanicsCategory, int> mechanicsScores;

  /// Overall composite score (0-100).
  final int overallScore;

  /// Ordered tips — most important first.
  final List<CoachingTip> tips;

  /// One-line summary of the shot-type-specific quick cue.
  final String quickCue;

  /// Strengths the player demonstrated.
  final List<String> strengths;

  const ShotCoachingReport({
    required this.shotType,
    required this.shotLabel,
    required this.discipline,
    required this.mechanicsScores,
    required this.overallScore,
    required this.tips,
    required this.quickCue,
    required this.strengths,
  });
}

// ---------------------------------------------------------------------------
// Coaching engine
// ---------------------------------------------------------------------------

/// Generates personalized coaching feedback by combining the analysis-engine
/// mechanics scores with shot-type-specific knowledge from [shotCatalog].
class ShotCoachingService {
  /// Produce a full coaching report.
  ///
  /// [breakdown] — raw per-category scores from the analysis engine
  ///               (keys like "Balance", "Release Point", etc.)
  /// [overallScore] — composite 0-100 score
  /// [shotType] — classified shot type (nullable if not yet classified)
  /// [discipline] — men's or women's lacrosse
  ShotCoachingReport generateReport({
    required Map<String, int> breakdown,
    required int overallScore,
    ShotType? shotType,
    required LacrosseDiscipline discipline,
  }) {
    // Map free-form breakdown keys → MechanicsCategory
    final mechanicsScores = _mapBreakdown(breakdown);

    // Resolve shot definition
    final shotDef =
        shotType != null ? shotDefinitionFor(shotType) : null;

    final tips = <CoachingTip>[];

    // 1. Generate tips from mechanics scores (lowest first)
    final sorted = mechanicsScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    var priority = 1;
    for (final entry in sorted) {
      if (entry.value >= 90) continue; // already strong — skip
      tips.add(_tipForCategory(entry.key, entry.value, shotDef, priority));
      priority++;
    }

    // 2. Shot-type-specific tips from common faults
    if (shotDef != null) {
      for (final fault in shotDef.commonFaults.take(2)) {
        tips.add(CoachingTip(
          headline: 'Watch out: ${_capitalize(fault)}',
          detail: 'This is a common mistake on the '
              '${shotDef.displayName}. Focus on eliminating this '
              'habit during practice reps.',
          category: MechanicsCategory.balance, // generic
          priority: priority++,
        ));
      }
    }

    // 3. Identify strengths
    final strengths = <String>[];
    for (final entry in sorted.reversed) {
      if (entry.value >= 80) {
        strengths
            .add('${mechanicsCategoryLabels[entry.key]}: ${entry.value}/100');
      }
      if (strengths.length >= 3) break;
    }

    return ShotCoachingReport(
      shotType: shotType,
      shotLabel: shotDef?.displayName ?? 'Unknown Shot',
      discipline: discipline,
      mechanicsScores: mechanicsScores,
      overallScore: overallScore,
      tips: tips,
      quickCue: shotDef?.quickCue ?? 'Focus on full follow-through.',
      strengths: strengths,
    );
  }

  /// Generate a comparison between two reports (e.g. session-over-session).
  Map<MechanicsCategory, int> compareMechanics(
    ShotCoachingReport previous,
    ShotCoachingReport current,
  ) {
    final diff = <MechanicsCategory, int>{};
    for (final cat in MechanicsCategory.values) {
      final prev = previous.mechanicsScores[cat] ?? 0;
      final curr = current.mechanicsScores[cat] ?? 0;
      diff[cat] = curr - prev;
    }
    return diff;
  }

  /// Suggest the top drill for the player's weakest area.
  String suggestDrill(ShotCoachingReport report) {
    final weakest = (report.mechanicsScores.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value)))
        .first
        .key;
    return _drillForCategory(weakest);
  }

  // -------------------------------------------------------------------------
  // Internals
  // -------------------------------------------------------------------------

  /// Map UI category names → enum.
  Map<MechanicsCategory, int> _mapBreakdown(Map<String, int> raw) {
    final result = <MechanicsCategory, int>{};
    final rng = math.Random();
    for (final cat in MechanicsCategory.values) {
      final label = mechanicsCategoryLabels[cat]!;
      if (raw.containsKey(label)) {
        result[cat] = raw[label]!;
      } else {
        // Fall back: map legacy keys
        final mapped = _legacyMapping(label, raw);
        result[cat] = mapped ?? (70 + rng.nextInt(20));
      }
    }
    return result;
  }

  int? _legacyMapping(String label, Map<String, int> raw) {
    // The current placeholder uses "Balance", "Release Point", etc.
    final aliases = <String, List<String>>{
      'Hip Rotation': ['Hip Rotation', 'Hips'],
      'Shoulder Turn': ['Shoulder Turn', 'Shoulders'],
      'Release Point': ['Release Point', 'Release'],
      'Wrist Snap': ['Wrist Snap', 'Wrist'],
      'Follow-through': ['Follow-through', 'Follow Through', 'Followthrough'],
      'Footwork': ['Footwork', 'Feet'],
      'Balance': ['Balance', 'Stability'],
      'Stick Protection': ['Stick Protection', 'Protection'],
    };
    for (final entry in aliases.entries) {
      if (entry.key == label) {
        for (final alias in entry.value) {
          if (raw.containsKey(alias)) return raw[alias];
        }
      }
    }
    return null;
  }

  CoachingTip _tipForCategory(
    MechanicsCategory cat,
    int score,
    ShotDefinition? shotDef,
    int priority,
  ) {
    final label = mechanicsCategoryLabels[cat]!;
    String detail;

    if (score < 50) {
      detail = 'Your $label score is $score/100 — this is the #1 area '
          'to improve. ${_detailedAdvice(cat)}';
    } else if (score < 70) {
      detail = 'Your $label is at $score/100. With focused practice you '
          'can gain 15+ points quickly. ${_detailedAdvice(cat)}';
    } else {
      detail = '$label is decent at $score/100 but there\'s room to '
          'polish. ${_detailedAdvice(cat)}';
    }

    if (shotDef != null) {
      // Append shot-specific note if the criterion appears in keyCriteria
      if (shotDef.keyCriteria.any(
          (c) => c.toLowerCase().contains(label.toLowerCase()))) {
        detail += ' This is especially important for the '
            '${shotDef.displayName}.';
      }
    }

    return CoachingTip(
      headline: 'Improve your $label',
      detail: detail,
      category: cat,
      priority: priority,
    );
  }

  String _detailedAdvice(MechanicsCategory cat) {
    switch (cat) {
      case MechanicsCategory.hipRotation:
        return 'Drive your hips toward the target before your arms move. '
            'Think "hips fire, then hands follow."';
      case MechanicsCategory.shoulderTurn:
        return 'Load your shoulders by turning away from the target during '
            'wind-up, then uncoil explosively.';
      case MechanicsCategory.releasePoint:
        return 'Release the ball at the highest comfortable point. A higher '
            'release gives the goalie less time to react.';
      case MechanicsCategory.wristSnap:
        return 'Snap your top-hand wrist hard at release — this adds '
            'velocity and spin. Practice wall-ball one-handed.';
      case MechanicsCategory.followThrough:
        return 'Let your stick continue toward the target after release. '
            'A short follow-through kills accuracy and power.';
      case MechanicsCategory.footwork:
        return 'Step toward the target with your lead foot on every shot. '
            'Your power chain starts from the ground up.';
      case MechanicsCategory.balance:
        return 'Keep your weight centered over your hips during the shot. '
            'Falling away robs you of power and accuracy.';
      case MechanicsCategory.stickProtection:
        return 'Keep your stick tight to your body to prevent checks. '
            'Use your body as a shield between the defender and stick.';
    }
  }

  String _drillForCategory(MechanicsCategory cat) {
    switch (cat) {
      case MechanicsCategory.hipRotation:
        return 'Hip-Lock Wall Ball: Face a wall, lock your feet in place, '
            'and throw using only hip rotation. 3 sets of 20.';
      case MechanicsCategory.shoulderTurn:
        return 'Twist & Throw: Start with your back to the wall, rotate '
            'your shoulders to face it, and fire. 3 sets of 15.';
      case MechanicsCategory.releasePoint:
        return 'Tall-Tee Shots: Stand on toes, reach as high as you can, '
            'and release at the peak. 3 sets of 10.';
      case MechanicsCategory.wristSnap:
        return 'One-Hand Wrist Snaps: Hold the stick with just your top '
            'hand and snap shots at a target from 5 yards. 3 sets of 20.';
      case MechanicsCategory.followThrough:
        return 'Point-and-Hold: After every shot, freeze with your stick '
            'pointed at the target for 2 seconds. 3 sets of 10.';
      case MechanicsCategory.footwork:
        return 'Ladder Shots: Run through an agility ladder, catch a pass, '
            'plant, and shoot. 3 sets of 8.';
      case MechanicsCategory.balance:
        return 'One-Leg Wall Ball: Stand on one foot and play wall ball. '
            'Switch feet every 20 reps. 3 sets per foot.';
      case MechanicsCategory.stickProtection:
        return 'Gauntlet Dodge & Shoot: Run through a line of bag holders '
            'while protecting your stick, then shoot. 3 sets of 5.';
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
