import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

/// Draws a lacrosse goal divided into a 3x3 grid of zones.
/// Each zone is heat-colored (blue → green → red) based on shot accuracy.
///
/// Zone layout (matches standard lacrosse goal naming):
///   TL | TC | TR
///   ML | MC | MR
///   BL | BC | BR
class GoalZoneHeatmap extends StatelessWidget {
  /// Map of zone label → accuracy (0.0 to 1.0)
  final Map<String, double> zoneAccuracy;

  const GoalZoneHeatmap({super.key, required this.zoneAccuracy});

  static const _zones = [
    ['TL', 'TC', 'TR'],
    ['ML', 'MC', 'MR'],
    ['BL', 'BC', 'BR'],
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            children: [
              _LegendItem(color: _heatColor(0.0), label: 'Low'),
              const SizedBox(width: 8),
              _LegendItem(color: _heatColor(0.5), label: 'Medium'),
              const SizedBox(width: 8),
              _LegendItem(color: _heatColor(1.0), label: 'High'),
              const Spacer(),
              const Text('accuracy', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: AppSizes.sm),

          // Goal frame + grid
          AspectRatio(
            aspectRatio: 16 / 9,
            child: CustomPaint(
              painter: _GoalZonePainter(zoneAccuracy: zoneAccuracy, zones: _zones),
            ),
          ),

          const SizedBox(height: AppSizes.sm),

          // Zone accuracy breakdown
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _zones.expand((row) => row).map((zone) {
              final acc = zoneAccuracy[zone];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: acc != null ? _heatColor(acc).withOpacity(0.15) : AppColors.border.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: acc != null ? _heatColor(acc) : AppColors.border),
                ),
                child: Text(
                  '$zone: ${acc != null ? "${(acc * 100).toStringAsFixed(0)}%" : "--"}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: acc != null ? _heatColor(acc) : Colors.grey,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

Color _heatColor(double value) {
  // Blue (0.0) → Green (0.5) → Red (1.0)
  if (value <= 0.5) {
    return Color.lerp(const Color(0xFF2196F3), const Color(0xFF4CAF50), value * 2)!;
  } else {
    return Color.lerp(const Color(0xFF4CAF50), const Color(0xFFF44336), (value - 0.5) * 2)!;
  }
}

class _GoalZonePainter extends CustomPainter {
  final Map<String, double> zoneAccuracy;
  final List<List<String>> zones;

  const _GoalZonePainter({required this.zoneAccuracy, required this.zones});

  @override
  void paint(Canvas canvas, Size size) {
    const postWidth = 6.0;
    const crossbarHeight = 6.0;

    // Goal interior rect (inside the posts)
    final goalRect = Rect.fromLTWH(
      postWidth,
      crossbarHeight,
      size.width - postWidth * 2,
      size.height - crossbarHeight,
    );

    final cellW = goalRect.width / 3;
    final cellH = goalRect.height / 3;

    // Draw zone fills
    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        final label = zones[row][col];
        final acc = zoneAccuracy[label];
        final rect = Rect.fromLTWH(
          goalRect.left + col * cellW,
          goalRect.top + row * cellH,
          cellW,
          cellH,
        );

        final fillPaint = Paint()
          ..color = acc != null ? _heatColor(acc).withOpacity(0.55) : Colors.grey.withOpacity(0.12);
        canvas.drawRect(rect, fillPaint);

        // Zone label
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: acc != null ? _heatColor(acc) : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(rect.center.dx - textPainter.width / 2, rect.center.dy - textPainter.height / 2),
        );
      }
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;

    // Vertical lines
    for (var col = 1; col < 3; col++) {
      canvas.drawLine(
        Offset(goalRect.left + col * cellW, goalRect.top),
        Offset(goalRect.left + col * cellW, goalRect.bottom),
        gridPaint,
      );
    }
    // Horizontal lines
    for (var row = 1; row < 3; row++) {
      canvas.drawLine(
        Offset(goalRect.left, goalRect.top + row * cellH),
        Offset(goalRect.right, goalRect.top + row * cellH),
        gridPaint,
      );
    }

    // Goal posts (white with dark border)
    final postPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final postBorder = Paint()
      ..color = Colors.black45
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Left post
    final leftPost = Rect.fromLTWH(0, crossbarHeight, postWidth, size.height - crossbarHeight);
    canvas.drawRect(leftPost, postPaint);
    canvas.drawRect(leftPost, postBorder);

    // Right post
    final rightPost = Rect.fromLTWH(size.width - postWidth, crossbarHeight, postWidth, size.height - crossbarHeight);
    canvas.drawRect(rightPost, postPaint);
    canvas.drawRect(rightPost, postBorder);

    // Crossbar
    final crossbar = Rect.fromLTWH(0, 0, size.width, crossbarHeight);
    canvas.drawRect(crossbar, postPaint);
    canvas.drawRect(crossbar, postBorder);
  }

  @override
  bool shouldRepaint(_GoalZonePainter old) => old.zoneAccuracy != zoneAccuracy;
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
