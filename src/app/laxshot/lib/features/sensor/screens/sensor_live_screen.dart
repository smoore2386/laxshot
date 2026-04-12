import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/services/analytics_service.dart';
import '../providers/ble_provider.dart';
import '../providers/sensor_session_provider.dart';
import '../widgets/ble_connection_badge.dart';
import '../widgets/shot_score_ring.dart';
import '../widgets/wrist_snap_meter.dart';
import '../widgets/release_angle_gauge.dart';
import '../widgets/power_estimate_display.dart';
import '../widgets/shot_card.dart';

class SensorLiveScreen extends ConsumerStatefulWidget {
  const SensorLiveScreen({super.key});

  @override
  ConsumerState<SensorLiveScreen> createState() => _SensorLiveScreenState();
}

class _SensorLiveScreenState extends ConsumerState<SensorLiveScreen> {
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    // Start session on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sensorSessionProvider.notifier).startSession();
    });
    // Timer to refresh elapsed display
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  Future<void> _endSession() async {
    await ref.read(sensorSessionProvider.notifier).endSession();
    if (mounted) {
      final session = ref.read(sensorSessionProvider);
      ref.read(analyticsServiceProvider).logSensorSessionEnd(
            shotCount: session.shots.length,
          );
      context.go(AppRoutes.sensorSummary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sensorSessionProvider);
    final battery = ref.watch(sensorBatteryProvider);
    final lastShot = session.lastShot;

    // Haptic on new shot
    ref.listen(sensorSessionProvider, (prev, next) {
      if (prev != null && next.shots.length > prev.shots.length) {
        HapticFeedback.mediumImpact();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const BleConnectionBadge(),
            const Spacer(),
            if (battery >= 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    battery > 20
                        ? Icons.battery_std
                        : Icons.battery_alert,
                    size: 16,
                    color: battery > 20
                        ? AppColors.textSecondary
                        : AppColors.error,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$battery%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            const SizedBox(width: AppSizes.sm),
            Text(
              _formatDuration(session.elapsed),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Shot score — large center display
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
            child: ShotScoreRing(
              score: lastShot?.shotScore ?? 0,
              size: 160,
            ),
          ),

          // Metrics row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                WristSnapMeter(
                  snapMs: lastShot?.wristSnapMs ?? 0,
                  snapDps: lastShot?.wristSnapDps ?? 0,
                ),
                ReleaseAngleGauge(
                  angleDeg: lastShot?.releaseAngleDeg ?? 0,
                ),
                PowerEstimateDisplay(
                  mph: lastShot?.powerEstimateMph ?? 0,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSizes.md),

          // Shot count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${session.shots.length} shot${session.shots.length == 1 ? '' : 's'} detected',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),

          const SizedBox(height: AppSizes.sm),

          // Shot list
          Expanded(
            child: session.shots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports_hockey,
                            size: 40, color: AppColors.surfaceVariant),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          'Take a shot!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Swing your stick and we\'ll detect it',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSizes.md),
                    itemCount: session.shots.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      final reversedIndex =
                          session.shots.length - 1 - index;
                      return ShotCard(
                        shot: session.shots[reversedIndex],
                        shotNumber: reversedIndex + 1,
                        onTap: null, // Replay available after session ends
                      );
                    },
                  ),
          ),

          // End session button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: ElevatedButton(
                  onPressed: _endSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                  child: const Text(
                    'End Session',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
