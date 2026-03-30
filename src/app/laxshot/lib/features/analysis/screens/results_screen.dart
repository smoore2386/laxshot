import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../providers/ml_provider.dart';
import '../../../data/services/ml_analysis_service.dart';

class ResultsScreen extends ConsumerWidget {
  final String sessionId;
  const ResultsScreen({super.key, required this.sessionId});

  static const _categoryIcons = <String, String>{
    'Balance': '⚖️',
    'Release Point': '🎯',
    'Follow Through': '➡️',
    'Body Rotation': '🔄',
    // Legacy placeholder labels (keep for any cached data)
    'Wind-up': '🔄',
    'Follow-through': '➡️',
    'Body Position': '🧍',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisState = ref.watch(analysisNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analysis Results'),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ref.read(analysisNotifierProvider.notifier).reset();
            context.go(AppRoutes.home);
          },
        ),
      ),
      body: Builder(
        builder: (context) {
          // ── Loading ────────────────────────────────────────────────
          if (analysisState.isAnalyzing) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: AppSizes.md),
                  Text(
                    'Analyzing your form…',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // ── Error ──────────────────────────────────────────────────
          if (analysisState.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orange),
                    const SizedBox(height: AppSizes.md),
                    const Text(
                      'Analysis unavailable',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      'Using estimated scores — real analysis will be available on device.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    ElevatedButton(
                      onPressed: () => context.push(AppRoutes.camera),
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          // ── Results (real or placeholder) ──────────────────────────
          final result = analysisState.result ?? _placeholderResult();
          return _ResultsBody(result: result, categoryIcons: _categoryIcons);
        },
      ),
    );
  }

  ShotAnalysisResult _placeholderResult() => const ShotAnalysisResult(
        score: 78,
        keypoints: {},
        breakdown: {
          'Balance': 82,
          'Release Point': 74,
          'Follow Through': 80,
          'Body Rotation': 76,
        },
        tip: 'Release the ball higher — get that wrist above your shoulder.',
        goalZone: 2,
      );
}

class _ResultsBody extends StatelessWidget {
  final ShotAnalysisResult result;
  final Map<String, String> categoryIcons;

  const _ResultsBody({required this.result, required this.categoryIcons});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Score ring
          _ScoreRing(score: result.score.toDouble()),
          const SizedBox(height: AppSizes.lg),

          // Breakdown cards
          const Text(
            'Form Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSizes.sm),
          ...result.breakdown.entries.map(
            (e) => _BreakdownCard(
              label: e.key,
              score: e.value.toDouble(),
              icon: categoryIcons[e.key] ?? '📊',
            ),
          ),

          const SizedBox(height: AppSizes.lg),

          // Coaching tip
          _CoachingTip(tip: result.tip),

          const SizedBox(height: AppSizes.lg),

          // Actions
          Consumer(
            builder: (context, ref, _) => ElevatedButton.icon(
              onPressed: () {
                ref.read(analysisNotifierProvider.notifier).reset();
                context.push(AppRoutes.camera);
              },
              icon: const Icon(Icons.videocam_rounded),
              label: const Text('Record Again'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.stats),
            icon: const Icon(Icons.bar_chart),
            label: const Text('View All Stats'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
            ),
          ),
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}

class _CoachingTip extends StatelessWidget {
  final String tip;
  const _CoachingTip({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💡', style: TextStyle(fontSize: 24)),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Coaching Tip',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                const SizedBox(height: 4),
                Text(tip, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final double score;
  const _ScoreRing({required this.score});

  Color get _color {
    if (score >= 80) return AppColors.primary;
    if (score >= 60) return AppColors.accent;
    return Colors.redAccent;
  }

  String get _label {
    if (score >= 90) return 'Excellent! 🌟';
    if (score >= 80) return 'Great job! ⭐';
    if (score >= 70) return 'Nice work! 💪';
    if (score >= 60) return 'Keep it up! 🔥';
    return 'Keep practicing! 🥍';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey.shade200,
                    color: _color,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${score.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: _color,
                      ),
                    ),
                    const Text('Overall', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            _label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  final String label;
  final double score;
  final String icon;

  const _BreakdownCard({required this.label, required this.score, required this.icon});

  @override
  Widget build(BuildContext context) {
    final color =
        score >= 80 ? AppColors.primary : score >= 60 ? AppColors.accent : Colors.redAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.grey.shade200,
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
