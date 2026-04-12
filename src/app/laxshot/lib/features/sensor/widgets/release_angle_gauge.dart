import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class ReleaseAngleGauge extends StatelessWidget {
  final double angleDeg;

  const ReleaseAngleGauge({super.key, required this.angleDeg});

  @override
  Widget build(BuildContext context) {
    final inIdealRange = angleDeg >= 45 && angleDeg <= 55;
    final color = inIdealRange ? AppColors.success : AppColors.warning;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 60,
          height: 40,
          child: CustomPaint(
            painter: _AngleArcPainter(
              angleDeg: angleDeg,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${angleDeg.toStringAsFixed(0)}°',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          'Release Angle',
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

class _AngleArcPainter extends CustomPainter {
  final double angleDeg;
  final Color color;

  _AngleArcPainter({required this.angleDeg, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 4;

    // Track arc (0-90°)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = AppColors.surfaceVariant
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Ideal zone highlight (45-55°)
    final idealStartAngle = math.pi + (45 / 90) * math.pi;
    final idealSweep = (10 / 90) * math.pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      idealStartAngle,
      idealSweep,
      false,
      Paint()
        ..color = AppColors.success.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    // Needle
    final needleAngle =
        math.pi + (angleDeg.clamp(0, 90) / 90) * math.pi;
    final needleEnd = Offset(
      center.dx + radius * math.cos(needleAngle),
      center.dy + radius * math.sin(needleAngle),
    );
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_AngleArcPainter old) =>
      old.angleDeg != angleDeg || old.color != color;
}
