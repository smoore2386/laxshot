import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/ml_analysis_service.dart';

/// Singleton instance of [MlAnalysisService].
/// Lazily initialized on first use; reuses across screens.
final mlAnalysisServiceProvider = Provider<MlAnalysisService>((ref) {
  final service = MlAnalysisService();
  ref.onDispose(service.dispose);
  return service;
});

/// State for an in-progress analysis run.
class AnalysisState {
  final bool isAnalyzing;
  final ShotAnalysisResult? result;
  final String? error;

  const AnalysisState({
    this.isAnalyzing = false,
    this.result,
    this.error,
  });

  AnalysisState copyWith({
    bool? isAnalyzing,
    ShotAnalysisResult? result,
    String? error,
  }) {
    return AnalysisState(
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      result: result ?? this.result,
      error: error,
    );
  }
}

class AnalysisNotifier extends AutoDisposeNotifier<AnalysisState> {
  @override
  AnalysisState build() => const AnalysisState();

  Future<void> analyze(String imagePath) async {
    state = const AnalysisState(isAnalyzing: true);
    try {
      final service = ref.read(mlAnalysisServiceProvider);
      await service.initialize();
      final result = await service.analyzeFrame(imagePath);
      state = AnalysisState(result: result);
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
