import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../providers/stats_provider.dart';
import '../widgets/goal_zone_heatmap.dart';
import '../widgets/stat_summary_card.dart';
import '../widgets/recent_sessions_list.dart';

class StatsDashboardScreen extends ConsumerWidget {
  const StatsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final sessions = ref.watch(recentSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Stats'),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_rounded, color: AppColors.accent),
            onPressed: () => context.push(AppRoutes.achievements),
            tooltip: 'Achievements',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(userStatsProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary cards
              stats.when(
                data: (s) => Row(
                  children: [
                    Expanded(
                      child: StatSummaryCard(
                        label: 'Total Shots',
                        value: '${s?.totalShots ?? 0}',
                        icon: Icons.sports_hockey,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: StatSummaryCard(
                        label: 'Avg Score',
                        value: s != null ? '${s.avgScore.toStringAsFixed(1)}%' : '--',
                        icon: Icons.bar_chart,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: StatSummaryCard(
                        label: 'Best Score',
                        value: s != null ? '${s.bestScore.toStringAsFixed(0)}%' : '--',
                        icon: Icons.star_rounded,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
                loading: () => const SizedBox(height: 80, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: AppSizes.lg),

              // Goal zone heatmap
              const Text('Shot Zone Accuracy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSizes.sm),
              stats.when(
                data: (s) => GoalZoneHeatmap(zoneAccuracy: s?.zoneAccuracy ?? {}),
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(height: 200),
              ),

              const SizedBox(height: AppSizes.lg),

              // Progress chart
              const Text('Progress Over Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSizes.sm),
              _ProgressChart(sessionsAsync: sessions),

              const SizedBox(height: AppSizes.lg),

              // Recent sessions
              const Text('Recent Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSizes.sm),
              sessions.when(
                data: (list) => list.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSizes.xl),
                          child: Text('No sessions yet. Go record your first shot! 🥍'),
                        ),
                      )
                    : RecentSessionsList(sessions: list),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: AppSizes.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressChart extends StatelessWidget {
  final AsyncValue<dynamic> sessionsAsync;
  const _ProgressChart({required this.sessionsAsync});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: sessionsAsync.when(
        data: (sessions) {
          final spots = <FlSpot>[];
          final list = sessions as List? ?? [];
          for (var i = 0; i < list.length && i < 10; i++) {
            final session = list[i];
            final score = (session?.overallScore ?? 0.0) as double;
            spots.add(FlSpot(i.toDouble(), score));
          }

          if (spots.isEmpty) {
            return const Center(child: Text('Record sessions to see progress', style: TextStyle(color: Colors.grey)));
          }

          return LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ),
                ),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.primary,
                      strokeColor: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}
