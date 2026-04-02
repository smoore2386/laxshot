import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/shot_classification.dart';
import '../../../data/services/ml_analysis_service.dart';
import '../../../data/services/shot_coaching_service.dart';

/// Singleton instance of [MlAnalysisService].
/// Lazily initialized on first use; reuses across screens.
final mlAnalysisServiceProvider = Provider<MlAnalysisService>((ref) {
  final service = MlAnalysisService();
  ref.onDispose(service.dispose);
  return service;
});

/// Singleton instance of [ShotCoachingService].
final shotCoachingServiceProvider = Provider<ShotCoachingService>((ref) {
  return ShotCoachingService();
});

/// State for an in-progress analysis run.
class AnalysisState {
  final bool isAnalyzing;
  final ShotAnalysisResult? result;
  final ShotCoachingReport? coachingReport;
  final String? error;

  const AnalysisState({
    this.isAnalyzing = false,
    this.result,
    this.coachingReport,
    this.error,
  });

  AnalysisState copyWith({
    bool? isAnalyzing,
    ShotAnalysisResult? result,
    ShotCoachingReport? coachingReport,
    String? error,
  }) {
    return AnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      result: result ?? this.result,
      coachingReport: coachingReport ?? this.coachingReport,
      error: error,
    );
  }
}

class AnalysisNotifier extends AutoDisposeNotifier<AnalysisState> {
  @override
  AnalysisState build() => const AnalysisState();

  Future<void> analyze(
    String imagePath, {
    LacrosseDiscipline discipline = LacrosseDiscipline.mens,
    ShotType? shotType,
  }) async {
    state = const AnalysisState(isAnalyzing: true);
    try {
      final mlService = ref.read(mlAnalysisServiceProvider);
      await mlService.initialize();
      final result = await mlService.analyzeFrame(imagePath);

      final coaching = ref.read(shotCoachingServiceProvider);
      final report = coaching.generateReport(
        breakdown: result.breakdown,
        overallScore: result.score,
        shotType: shotType,
        discipline: discipline,
      );

      state = AnalysisState(result: result, coachingReport: report);
    } catch (e) {
      state = AnalysisState(error: e.toString());
    }
  }

  void reset() => state = const AnalysisState();
}

final analysisNotifierProvider =
    AutoDisposeNotifierProvider<AnalysisNotifier, AnalysisState>(
  AnalysisNotifier.new,
);
