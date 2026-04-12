import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class PowerEstimateDisplay extends StatelessWidget {
  final double mph;

  const PowerEstimateDisplay({super.key, required this.mph});

  @override
  Widget build(BuildContext context) {
    final color = mph >= 70
        ? AppColors.success
        : mph >= 50
            ? AppColors.accent
            : AppColors.textSecondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${mph.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          'MPH',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          'Power Est.',
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
