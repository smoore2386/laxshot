import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class WristSnapMeter extends StatelessWidget {
  final int snapMs;
  final double snapDps;

  const WristSnapMeter({
    super.key,
    required this.snapMs,
    required this.snapDps,
  });

  @override
  Widget build(BuildContext context) {
    // Lower ms = better. 0-80ms is excellent, 80-200ms is average, 200+ is slow.
    final normalized = (1.0 - (snapMs / 200.0)).clamp(0.0, 1.0);
    final color = normalized >= 0.6
        ? AppColors.success
        : normalized >= 0.3
            ? AppColors.warning
            : AppColors.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${snapMs}ms',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          height: 6,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: normalized,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          'Wrist Snap',
          style: TextStyle(
            fontSize: AppSizes.label,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
