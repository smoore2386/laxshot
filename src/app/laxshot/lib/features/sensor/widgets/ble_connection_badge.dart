import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/ble_service.dart';
import '../providers/ble_provider.dart';

class BleConnectionBadge extends ConsumerWidget {
  const BleConnectionBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState = ref.watch(bleConnectionStateProvider);

    final state = connState.valueOrNull ?? BleConnectionState.disconnected;

    final Color color;
    final IconData icon;
    final String label;

    switch (state) {
      case BleConnectionState.connected:
        color = AppColors.success;
        icon = Icons.bluetooth_connected;
        label = 'Connected';
      case BleConnectionState.connecting:
        color = AppColors.warning;
        icon = Icons.bluetooth_searching;
        label = 'Connecting...';
      case BleConnectionState.disconnected:
        color = AppColors.error;
        icon = Icons.bluetooth_disabled;
        label = 'Disconnected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
