import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../providers/stats_provider.dart';

class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool earned;

  const Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.earned,
  });
}

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  List<Achievement> _buildAchievements(dynamic stats) {
    final totalShots = (stats?.totalShots ?? 0) as int;
    final bestScore = (stats?.bestScore ?? 0.0) as double;
    final streakDays = (stats?.streakDays ?? 0) as int;

    return [
      Achievement(
        id: 'first_shot',
        emoji: '🥍',
        title: 'First Shot',
        description: 'Record your first shot',
        earned: totalShots >= 1,
      ),
      Achievement(
        id: 'ten_shots',
        emoji: '🔥',
        title: 'On Fire',
        description: 'Record 10 shots',
        earned: totalShots >= 10,
      ),
      Achievement(
        id: 'fifty_shots',
        emoji: '💪',
        title: 'Grinder',
        description: 'Record 50 shots',
        earned: totalShots >= 50,
      ),
      Achievement(
        id: 'hundred_shots',
        emoji: '💯',
        title: '100 Shots Club',
        description: 'Record 100 shots total',
        earned: totalShots >= 100,
      ),
      Achievement(
        id: 'score_70',
        emoji: '⭐',
        title: 'Nice Form',
        description: 'Score 70% or higher on a shot',
        earned: bestScore >= 70,
      ),
      Achievement(
        id: 'score_90',
        emoji: '🌟',
        title: 'All-Star',
        description: 'Score 90% or higher on a shot',
        earned: bestScore >= 90,
      ),
      Achievement(
        id: 'streak_3',
        emoji: '📅',
        title: 'Consistent',
        description: 'Practice 3 days in a row',
        earned: streakDays >= 3,
      ),
      Achievement(
        id: 'streak_7',
        emoji: '🗓️',
        title: 'Week Warrior',
        description: 'Practice 7 days in a row',
        earned: streakDays >= 7,
      ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Achievements'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: stats.when(
        data: (s) {
          final achievements = _buildAchievements(s);
          final earned = achievements.where((a) => a.earned).length;

          return Column(
            children: [
              // Progress header
              Container(
                margin: const EdgeInsets.all(AppSizes.md),
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                ),
                child: Row(
                  children: [
                    const Text('🏆', style: TextStyle(fontSize: 48)),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$earned / ${achievements.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'Achievements earned',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: achievements.isEmpty ? 0 : earned / achievements.length,
                              backgroundColor: Colors.white24,
                              color: AppColors.accent,
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Grid
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: AppSizes.sm,
                    mainAxisSpacing: AppSizes.sm,
                  ),
                  itemCount: achievements.length,
                  itemBuilder: (_, i) => _AchievementCard(achievement: achievements[i]),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load achievements')),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: achievement.earned ? 1.0 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: achievement.earned ? AppColors.surface : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(
            color: achievement.earned ? AppColors.primary.withOpacity(0.3) : AppColors.border,
            width: achievement.earned ? 2 : 1,
          ),
          boxShadow: achievement.earned
              ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(achievement.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: achievement.earned ? AppColors.textPrimary : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
