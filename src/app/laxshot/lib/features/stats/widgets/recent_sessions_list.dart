import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/session_model.dart';

class RecentSessionsList extends StatelessWidget {
  final List<SessionModel> sessions;
  const RecentSessionsList({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sessions.take(5).map((s) => _SessionTile(session: s)).toList(),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final SessionModel session;
  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, y').format(session.date.toDate());
    final score = session.overallScore;
    final scoreColor = score >= 80
        ? AppColors.primary
        : score >= 60
            ? AppColors.accent
            : Colors.redAccent;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.results.replaceAll(':sessionId', session.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.sports_hockey, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(
                    '${session.shots.length} shot${session.shots.length == 1 ? '' : 's'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${score.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                Text('score', style: TextStyle(color: scoreColor.withOpacity(0.7), fontSize: 11)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
