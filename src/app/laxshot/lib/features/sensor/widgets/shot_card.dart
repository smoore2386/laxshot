import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/sensor_shot.dart';

class ShotCard extends StatelessWidget {
  final SensorShot shot;
  final int shotNumber;
  final VoidCallback? onTap;

  const ShotCard({
    super.key,
    required this.shot,
    required this.shotNumber,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scoreColor = shot.shotScore >= 80
        ? AppColors.success
        : shot.shotScore >= 60
            ? AppColors.accent
            : shot.shotScore >= 40
                ? AppColors.warning
                : AppColors.error;

    return GestureDetector(
      onTap: onTap,
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
            // Shot number badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppSizes.radiusSm),
              ),
              alignment: Alignment.center,
              child: Text(
                '#$shotNumber',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.md),
            // Score
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Score: ${shot.shotScore}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: scoreColor,
                  ),
                ),
                Text(
                  '${shot.powerEstimateMph.toStringAsFixed(0)} mph  |  '
                  '${shot.releaseAngleDeg.toStringAsFixed(0)}°  |  '
                  '${shot.wristSnapMs}ms snap',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            if (onTap != null)
              Icon(
                Icons.play_circle_outline,
                color: AppColors.textSecondary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
