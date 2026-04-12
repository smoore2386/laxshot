import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/repositories/sensor_session_repository.dart';
import '../../../data/services/sensor_coaching_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/ble_provider.dart';
import '../providers/sensor_session_provider.dart';
import '../widgets/coaching_tips_card.dart';
import '../widgets/shot_score_ring.dart';
import '../widgets/shot_card.dart';

class SensorSessionSummaryScreen extends ConsumerStatefulWidget {
  const SensorSessionSummaryScreen({super.key});

  @override
  ConsumerState<SensorSessionSummaryScreen> createState() =>
      _SensorSessionSummaryScreenState();
}

class _SensorSessionSummaryScreenState
    extends ConsumerState<SensorSessionSummaryScreen> {
  bool _saving = false;
  bool _saved = false;

  Future<void> _saveToFirebase() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    setState(() => _saving = true);

    final notifier = ref.read(sensorSessionProvider.notifier);
    final deviceId =
        ref.read(bleServiceProvider).connectedDevice?.remoteId.str ?? 'unknown';
    final sessionModel = notifier.buildSessionModel(
      userId: user.uid,
      deviceId: deviceId,
    );

    final repo = ref.read(sensorSessionRepositoryProvider);
    await repo.createSensorSession(user.uid, sessionModel);
    await repo.updateStatsFromSensorSession(user.uid, sessionModel);

    setState(() {
      _saving = false;
      _saved = true;
    });
  }

  Future<void> _exportCsv() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;

    final notifier = ref.read(sensorSessionProvider.notifier);
    final deviceId =
        ref.read(bleServiceProvider).connectedDevice?.remoteId.str ?? 'unknown';
    final sessionModel = notifier.buildSessionModel(
      userId: user.uid,
      deviceId: deviceId,
    );

    final repo = ref.read(sensorSessionRepositoryProvider);
    final csv = repo.exportSessionAsCsv(sessionModel);

    // Write to temp file and share
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/laxpod_session_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: 'LaxPod Session Export',
    ));
  }

  void _startNewSession() {
    ref.read(sensorSessionProvider.notifier).reset();
    context.go(AppRoutes.sensorLive);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sensorSessionProvider);
    final shots = session.shots;
    final avgScore = shots.isEmpty
        ? 0.0
        : shots.map((s) => s.shotScore).reduce((a, b) => a + b) /
            shots.length;
    final avgPower = shots.isEmpty
        ? 0.0
        : shots.map((s) => s.powerEstimateMph).reduce((a, b) => a + b) /
            shots.length;
    final avgAngle = shots.isEmpty
        ? 0.0
        : shots.map((s) => s.releaseAngleDeg).reduce((a, b) => a + b) /
            shots.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Session Summary'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              ref.read(sensorSessionProvider.notifier).reset();
              context.go(AppRoutes.home);
            },
          ),
        ],
      ),
      body: shots.isEmpty
          ? const Center(child: Text('No shots recorded in this session.'))
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Score ring + summary stats
                      Center(
                        child: ShotScoreRing(
                          score: avgScore.round(),
                          size: 140,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Center(
                        child: Text(
                          'Average Score',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),

                      // Summary stats row
                      Row(
                        children: [
                          _SummaryTile(
                            label: 'Shots',
                            value: '${shots.length}',
                          ),
                          _SummaryTile(
                            label: 'Avg Power',
                            value: '${avgPower.toStringAsFixed(0)} mph',
                          ),
                          _SummaryTile(
                            label: 'Avg Angle',
                            value: '${avgAngle.toStringAsFixed(0)}°',
                          ),
                          _SummaryTile(
                            label: 'Duration',
                            value: _formatDuration(session.elapsed),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.lg),

                      // Score trend chart
                      if (shots.length >= 2) ...[
                        const Text(
                          'Shot Score Trend',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSizes.sm),
                        SizedBox(
                          height: 160,
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: 100,
                              gridData: FlGridData(
                                show: true,
                                horizontalInterval: 25,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: AppColors.surfaceVariant,
                                  strokeWidth: 1,
                                ),
                                drawVerticalLine: false,
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) => Text(
                                      '${value.toInt()}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) => Text(
                                      '#${value.toInt() + 1}',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles:
                                        SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: List.generate(
                                    shots.length,
                                    (i) => FlSpot(
                                        i.toDouble(),
                                        shots[i]
                                            .shotScore
                                            .toDouble()),
                                  ),
                                  isCurved: true,
                                  color: AppColors.primary,
                                  barWidth: 2.5,
                                  dotData: FlDotData(
                                    show: true,
                                    getDotPainter: (spot, percent, bar,
                                            index) =>
                                        FlDotCirclePainter(
                                      radius: 3,
                                      color: AppColors.primary,
                                      strokeWidth: 0,
                                    ),
                                  ),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),
                      ],

                      // Coaching tips
                      Builder(builder: (context) {
                        final coaching = SensorCoachingService();
                        final report = coaching.analyzeSession(shots);
                        if (report == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSizes.lg),
                          child: CoachingTipsCard(report: report),
                        );
                      }),

                      // Shot list
                      const Text(
                        'All Shots',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      ...List.generate(
                        shots.length,
                        (i) => ShotCard(
                          shot: shots[i],
                          shotNumber: i + 1,
                          onTap: () => context.push(
                              AppRoutes.shotReplayPath(i)),
                        ),
                      ),

                      const SizedBox(height: AppSizes.lg),

                      // Action buttons
                      SizedBox(
                        width: double.infinity,
                        height: AppSizes.buttonHeight,
                        child: ElevatedButton.icon(
                          onPressed:
                              _saving || _saved ? null : _saveToFirebase,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : Icon(_saved
                                  ? Icons.check
                                  : Icons.cloud_upload),
                          label: Text(_saved
                              ? 'Saved!'
                              : _saving
                                  ? 'Saving...'
                                  : 'Save to Cloud'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppSizes.radiusMd),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: AppSizes.buttonHeight,
                              child: OutlinedButton.icon(
                                onPressed: _exportCsv,
                                icon: const Icon(Icons.download),
                                label: const Text('Export CSV'),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: SizedBox(
                              height: AppSizes.buttonHeight,
                              child: OutlinedButton.icon(
                                onPressed: _startNewSession,
                                icon: const Icon(Icons.replay),
                                label: const Text('New Session'),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.xl),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
