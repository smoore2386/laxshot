import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/stats_provider.dart';
import '../widgets/stat_summary_card.dart';
import '../widgets/recent_sessions_list.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserModelProvider).valueOrNull;
    final stats = ref.watch(userStatsProvider);
    final sessions = ref.watch(recentSessionsProvider);

    final firstName = user?.displayName.split(' ').first ?? 'Athlete';
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            pinned: true,
            expandedHeight: 100,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    firstName,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                onPressed: () => context.push(AppRoutes.profile),
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Record CTA
                GestureDetector(
                  onTap: () => context.push(AppRoutes.camera),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSizes.lg),
                    padding: const EdgeInsets.all(AppSizes.lg),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ready to record?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Analyze your shot or save',
                                style: TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ),
                ),

                // Stats row
                const Text(
                  'Your Stats',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSizes.sm),
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
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                const SizedBox(height: AppSizes.lg),

                // Quick links
                Row(
                  children: [
                    Expanded(
                      child: _QuickLink(
                        icon: Icons.bar_chart_rounded,
                        label: 'Full Stats',
                        onTap: () => context.push(AppRoutes.stats),
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _QuickLink(
                        icon: Icons.emoji_events_rounded,
                        label: 'Achievements',
                        onTap: () => context.push(AppRoutes.achievements),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSizes.lg),

                // Recent sessions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Sessions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    TextButton(
                      onPressed: () => context.push(AppRoutes.stats),
                      child: const Text('See all'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),
                sessions.when(
                  data: (list) => list.isEmpty
                      ? _EmptySessionsCard(onRecord: () => context.push(AppRoutes.camera))
                      : RecentSessionsList(sessions: list),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSizes.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _EmptySessionsCard extends StatelessWidget {
  final VoidCallback onRecord;
  const _EmptySessionsCard({required this.onRecord});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text('🥍', style: TextStyle(fontSize: 40)),
          const SizedBox(height: AppSizes.sm),
          const Text(
            'No sessions yet',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Record your first shot to get started!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: AppSizes.md),
          ElevatedButton.icon(
            onPressed: onRecord,
            icon: const Icon(Icons.videocam_rounded),
            label: const Text('Record Now'),
          ),
        ],
      ),
    );
  }
}
